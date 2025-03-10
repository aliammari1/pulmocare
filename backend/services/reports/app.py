import os
from datetime import datetime
from functools import wraps
import json
import time
import logging
import signal
import sys
from flask import Flask, request, jsonify, Blueprint, send_file
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from werkzeug.middleware.proxy_fix import ProxyFix
from prometheus_flask_exporter import PrometheusMetrics
from bson import ObjectId
import redis
import pika
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.pymongo import PymongoInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from config import Config
from prometheus_client import Counter, Histogram, start_http_server
import consul
from report_generator import ReportGenerator
from metrics import track_cache_metrics

# Handle graceful shutdown
def signal_handler(sig, frame):
    """Handle graceful shutdown"""
    logger.info("Received shutdown signal, cleaning up...")
    try:
        if rabbitmq_connection and not rabbitmq_connection.is_closed:
            rabbitmq_connection.close()
            logger.info("Closed RabbitMQ connection")
        
        if mongodb_client:
            mongodb_client.close()
            logger.info("Closed MongoDB connection")
            
        redis_client.close()
        logger.info("Closed Redis connection")
    except Exception as e:
        logger.error(f"Error during cleanup: {str(e)}")
    
    sys.exit(0)

# Register signal handlers
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

# Initialize Flask app
app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)
CORS(app)

# Initialize API blueprint
api = Blueprint('api', __name__)

# Set up logging
logging.config.dictConfig(Config.init_logging())
logger = logging.getLogger(__name__)

# Initialize OpenTelemetry
tracer_provider = TracerProvider()
otlp_exporter = OTLPSpanExporter(endpoint=Config.OTEL_EXPORTER_OTLP_ENDPOINT)
tracer_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
trace.set_tracer_provider(tracer_provider)

# Instrument Flask
FlaskInstrumentor().instrument_app(app)
PymongoInstrumentor().instrument()
RedisInstrumentor().instrument()

tracer = trace.get_tracer(__name__)

# Initialize Prometheus metrics
metrics = PrometheusMetrics(app)
metrics.info('reports_service_info', 'Reports service info', version='1.0.0')

# Prometheus metrics
REQUEST_COUNT = Counter(
    'report_service_requests_total',
    'Total requests to report service',
    ['method', 'endpoint', 'status']
)
REQUEST_LATENCY = Histogram(
    'report_service_request_latency_seconds',
    'Request latency in seconds',
    ['method', 'endpoint']
)

# Initialize rate limiter with Redis storage
limiter = Limiter(
    key_func=get_remote_address,
    storage_uri=Config.RATE_LIMIT_STORAGE_URL,
    storage_options={"password": Config.REDIS_PASSWORD},
    strategy="fixed-window"
)
limiter.init_app(app)

# Initialize Redis client for caching
redis_client = redis.Redis(
    host=Config.REDIS_HOST,
    port=Config.REDIS_PORT,
    password=Config.REDIS_PASSWORD,
    decode_responses=True
)

# Initialize MongoDB connection
def init_mongodb():
    """Initialize MongoDB connection with schema validation"""
    max_retries = 5
    retry_delay = 1
    
    for attempt in range(max_retries):
        try:
            from pymongo import MongoClient
            client = MongoClient(Config.get_mongodb_uri())
            db = client[Config.MONGODB_DATABASE]
            
            # Set up collection with schema validation
            if 'reports' not in db.list_collection_names():
                db.create_collection('reports')
                db.command({
                    'collMod': 'reports',
                    'validator': Config.get_mongodb_validation_schema()
                })
                
            reports_collection = db['reports']
            logger.info("Connected to MongoDB successfully")
            return client, db
        except Exception as e:
            logger.error(f"MongoDB connection attempt {attempt+1} failed: {str(e)}")
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
                retry_delay *= 2
            else:
                logger.error("Failed to connect to MongoDB after multiple attempts")
                return None, None

# Initialize RabbitMQ connection
def init_rabbitmq():
    """Initialize RabbitMQ connection and channel"""
    try:
        credentials = pika.PlainCredentials(
            Config.RABBITMQ_USER, 
            Config.RABBITMQ_PASS
        )
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host=Config.RABBITMQ_HOST,
                port=Config.RABBITMQ_PORT,
                virtual_host=Config.RABBITMQ_VHOST,
                credentials=credentials
            )
        )
        channel = connection.channel()
        
        # Declare exchanges
        channel.exchange_declare(
            exchange='medical.reports',
            exchange_type='topic',
            durable=True
        )
        
        # Declare queues
        channel.queue_declare(queue='report.analysis', durable=True)
        channel.queue_declare(queue='report.notifications', durable=True)
        
        # Bind queues to exchange
        channel.queue_bind(
            exchange='medical.reports',
            queue='report.analysis',
            routing_key='report.created'
        )
        channel.queue_bind(
            exchange='medical.reports',
            queue='report.notifications',
            routing_key='report.#'
        )
        
        logger.info("Connected to RabbitMQ successfully")
        return connection, channel
    except Exception as e:
        logger.error(f"Failed to connect to RabbitMQ: {str(e)}")
        return None, None

# Initialize connections
mongodb_client, db = init_mongodb()
reports_collection = db['reports']
rabbitmq_connection, rabbitmq_channel = init_rabbitmq()

def publish_event(routing_key: str, data: dict):
    """Publish event to RabbitMQ"""
    try:
        if rabbitmq_channel and rabbitmq_channel.is_open:
            rabbitmq_channel.basic_publish(
                exchange='medical.reports',
                routing_key=routing_key,
                body=json.dumps(data),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # make message persistent
                    content_type='application/json'
                )
            )
            logger.info(f"Published event {routing_key}")
        else:
            logger.error("RabbitMQ channel not available")
    except Exception as e:
        logger.error(f"Failed to publish event: {str(e)}")

# Decorators
def handle_service_error(func):
    """Enhanced decorator for service error handling and metrics"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        method = request.method
        endpoint = request.endpoint
        start_time = time.time()
        
        with tracer.start_as_current_span(f"{method} {endpoint}") as span:
            try:
                response = func(*args, **kwargs)
                status = response[1] if isinstance(response, tuple) else 200
                REQUEST_COUNT.labels(
                    method=method,
                    endpoint=endpoint,
                    status=status
                ).inc()
                return response
            except Exception as e:
                status = 500
                error_response = {
                    'error': str(e),
                    'timestamp': datetime.utcnow().isoformat(),
                    'path': request.path,
                    'method': request.method
                }
                logger.error(f"Service error: {error_response}")
                REQUEST_COUNT.labels(
                    method=method,
                    endpoint=endpoint,
                    status=status
                ).inc()
                span.set_attribute("error", True)
                span.set_attribute("error.message", str(e))
                return jsonify(error_response), status
            finally:
                REQUEST_LATENCY.labels(
                    method=method,
                    endpoint=endpoint
                ).observe(time.time() - start_time)
    return wrapper

# Health check endpoint
@api.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        # Check MongoDB
        db.command('ping')
        mongodb_status = 'UP'
    except Exception as e:
        mongodb_status = f'DOWN: {str(e)}'

    try:
        # Check Redis
        redis_client.ping()
        redis_status = 'UP'
    except Exception as e:
        redis_status = f'DOWN: {str(e)}'

    try:
        # Check RabbitMQ
        rabbitmq_status = 'UP' if rabbitmq_connection.is_open else 'DOWN'
    except Exception as e:
        rabbitmq_status = f'DOWN: {str(e)}'

    health_status = {
        'status': 'UP' if all(s == 'UP' for s in [mongodb_status, redis_status, rabbitmq_status]) else 'DOWN',
        'timestamp': datetime.utcnow().isoformat(),
        'version': Config.VERSION,
        'dependencies': {
            'mongodb': mongodb_status,
            'redis': redis_status,
            'rabbitmq': rabbitmq_status
        }
    }

    return jsonify(health_status), 200 if health_status['status'] == 'UP' else 503

# API Routes
@api.route('/', methods=['GET'])
@limiter.limit(Config.RATE_LIMIT_DEFAULT)
@handle_service_error
def get_reports():
    """Get all reports with optional filtering"""
    try:
        query = {}
        if request.args.get('search'):
            search = request.args.get('search')
            query = {
                '$or': [
                    {'title': {'$regex': search, '$options': 'i'}},
                    {'content': {'$regex': search, '$options': 'i'}}
                ]
            }
            
        reports = list(reports_collection.find(query))
        for report in reports:
            report['_id'] = str(report['_id'])
            
        return jsonify(reports)
    except Exception as e:
        logger.error(f"Error getting reports: {str(e)}")
        raise

@api.route('/<report_id>', methods=['GET'])
@limiter.limit(Config.RATE_LIMIT_DEFAULT)
@handle_service_error
def get_report(report_id):
    """Get a specific report by ID"""
    try:
        # Try cache first
        cached_report = redis_client.get(f"report:{report_id}")
        if cached_report:
            track_cache_metrics(hit=True, cache_name='reports')
            return jsonify(json.loads(cached_report))
            
        track_cache_metrics(hit=False, cache_name='reports')
        report = reports_collection.find_one({'_id': ObjectId(report_id)})
        if not report:
            return jsonify({'error': 'Report not found'}), 404
            
        report['_id'] = str(report['_id'])
        
        # Cache for next time
        redis_client.setex(
            f"report:{report_id}",
            Config.CACHE_TTL,
            json.dumps(report)
        )
        
        return jsonify(report)
    except Exception as e:
        logger.error(f"Error getting report {report_id}: {str(e)}")
        raise

@api.route('/', methods=['POST'])
@limiter.limit(Config.RATE_LIMIT_DEFAULT)
@handle_service_error
def create_report():
    """Create a new report"""
    try:
        data = request.json
        if not data:
            return jsonify({'error': 'No data provided'}), 400
            
        data['created_at'] = datetime.utcnow()
        data['updated_at'] = datetime.utcnow()
        
        result = reports_collection.insert_one(data)
        data['_id'] = str(result.inserted_id)
        
        # Publish event for analysis
        publish_event('report.created', {
            'report_id': data['_id'],
            'timestamp': datetime.utcnow().isoformat()
        })
        
        return jsonify(data), 201
    except Exception as e:
        logger.error(f"Error creating report: {str(e)}")
        raise

@api.route('/<report_id>', methods=['PUT'])
@limiter.limit(Config.RATE_LIMIT_DEFAULT)
@handle_service_error
def update_report(report_id):
    """Update an existing report"""
    try:
        data = request.json
        if not data:
            return jsonify({'error': 'No data provided'}), 400
            
        data['updated_at'] = datetime.utcnow()
        
        result = reports_collection.update_one(
            {'_id': ObjectId(report_id)},
            {'$set': data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Report not found'}), 404
            
        # Invalidate cache
        redis_client.delete(f"report:{report_id}")
        
        # Publish event
        publish_event('report.updated', {
            'report_id': report_id,
            'timestamp': datetime.utcnow().isoformat()
        })
        
        data['_id'] = report_id
        return jsonify(data)
    except Exception as e:
        logger.error(f"Error updating report {report_id}: {str(e)}")
        raise

@api.route('/<report_id>', methods=['DELETE'])
@limiter.limit(Config.RATE_LIMIT_DEFAULT)
@handle_service_error
def delete_report(report_id):
    """Delete a report"""
    try:
        result = reports_collection.delete_one({'_id': ObjectId(report_id)})
        if result.deleted_count == 0:
            return jsonify({'error': 'Report not found'}), 404
            
        # Invalidate cache
        redis_client.delete(f"report:{report_id}")
        
        # Publish event
        publish_event('report.deleted', {
            'report_id': report_id,
            'timestamp': datetime.utcnow().isoformat()
        })
        
        return '', 204
    except Exception as e:
        logger.error(f"Error deleting report {report_id}: {str(e)}")
        raise

@api.route('/<report_id>/export', methods=['GET'])
@limiter.limit(Config.RATE_LIMIT_DEFAULT)
@handle_service_error
def export_report(report_id):
    """Generate and download PDF report"""
    try:
        # Get report data
        report = reports_collection.find_one({'_id': ObjectId(report_id)})
        if not report:
            return jsonify({'error': 'Report not found'}), 404
            
        # Generate PDF
        output_path = report_generator.generate_pdf(report)
        
        # Send file
        return send_file(
            output_path,
            mimetype='application/pdf',
            as_attachment=True,
            download_name=f"medical_report_{report_id}.pdf"
        )
    except Exception as e:
        logger.error(f"Error exporting report {report_id}: {str(e)}")
        raise

# Register blueprint
app.register_blueprint(api, url_prefix='/v1')

def register_with_consul():
    """Register service with Consul"""
    try:
        consul_client = consul.Consul(
            host=Config.CONSUL_HOST,
            port=Config.CONSUL_PORT
        )
        
        service_id = f"reports-service-{os.getenv('HOSTNAME', 'unknown')}"
        service_name = 'reports-service'
        
        # Use Docker container name for service discovery
        consul_client.agent.service.register(
            name=service_name,
            service_id=service_id,
            address='medapp-reports-service-1',  # Docker container name
            port=5000,  # Internal container port
            check={
                'name': f'{service_name} health check',
                'http': 'http://medapp-reports-service-1:5000/v1/health',
                'interval': '10s',
                'timeout': '5s'
            },
            tags=['reports', 'medical', 'api']
        )
        logger.info(f"Registered service with Consul: {service_id}")
    except Exception as e:
        logger.error(f"Failed to register with Consul: {str(e)}")

# Start the application
if __name__ == '__main__':
    # Start Prometheus metrics server
    try:
        start_http_server(Config.METRICS_PORT)
        logger.info(f"Prometheus metrics server started on port {Config.METRICS_PORT}")
    except OSError as e:
        if e.errno == 98:  # Address already in use
            fallback_port = Config.METRICS_PORT + 1
            logger.warning(f"Port {Config.METRICS_PORT} is already in use. Trying fallback port {fallback_port}")
            try:
                start_http_server(fallback_port)
                logger.info(f"Prometheus metrics server started on fallback port {fallback_port}")
            except Exception as fallback_error:
                logger.error(f"Failed to start Prometheus metrics server on fallback port: {str(fallback_error)}")
        else:
            logger.error(f"Failed to start Prometheus metrics server: {str(e)}")
    
    # Register with Consul
    register_with_consul()
    
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=Config.DEBUG
    )


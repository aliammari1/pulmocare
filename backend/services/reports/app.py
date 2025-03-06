from flask import Flask, jsonify, request, Response
from flask_cors import CORS
from werkzeug.middleware.proxy_fix import ProxyFix
import logging
import os
import requests
import consul
from functools import wraps
import pymongo
import urllib.parse
from datetime import datetime
import threading
from prometheus_client import Counter, Histogram, start_http_server
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from config import Config
from services import setup_services

# Initialize Flask app
app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1)
CORS(app)

# Initialize OpenTelemetry
FlaskInstrumentor().instrument_app(app)
tracer = trace.get_tracer(__name__)

# Configure logging
logging.basicConfig(
    level=getattr(logging, Config.LOG_LEVEL),
    format=Config.LOG_FORMAT,
    handlers=[
        logging.FileHandler(Config.LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize Prometheus metrics
REQUEST_COUNT = Counter(
    'reports_request_total',
    'Total request count',
    ['method', 'endpoint', 'status']
)
REQUEST_LATENCY = Histogram(
    'reports_request_latency_seconds',
    'Request latency in seconds',
    ['method', 'endpoint']
)

# Initialize Consul client
consul_client = consul.Consul(
    host=Config.CONSUL_HOST,
    port=Config.CONSUL_PORT,
    token=Config.CONSUL_TOKEN
)

# Initialize MongoDB connection with connection pooling
def init_mongodb():
    """Initialize MongoDB connection with retry logic"""
    max_retries = 3
    retry_delay = 5  # seconds
    
    for attempt in range(max_retries):
        try:
            # Get MongoDB connection URI from Config
            mongodb_uri = Config.get_mongodb_uri()
            
            # Configure connection pool
            client = pymongo.MongoClient(
                mongodb_uri,
                maxPoolSize=50,
                minPoolSize=10,
                maxIdleTimeMS=60000,
                connectTimeoutMS=5000,
                serverSelectionTimeoutMS=5000
            )
            
            # Test connection
            client.admin.command('ping')
            logger.info("Connected to MongoDB successfully")
            return client
        except Exception as e:
            if attempt == max_retries - 1:
                logger.error(f"Failed to connect to MongoDB after {max_retries} attempts: {str(e)}")
                return None
            logger.warning(f"MongoDB connection attempt {attempt + 1} failed: {str(e)}")
            time.sleep(retry_delay)

def register_with_consul():
    """Register service with Consul including metadata"""
    try:
        service_name = "reports"
        service_id = f"{service_name}-{os.getenv('HOSTNAME', 'main')}"
        service_port = int(os.getenv('PORT', 5000))
        
        consul_client.agent.service.register(
            name=service_name,
            service_id=service_id,
            address=os.getenv('HOSTNAME', 'localhost'),
            port=service_port,
            tags=['reports', 'medical', 'api'],
            meta={
                'version': '1.0.0',
                'environment': os.getenv('ENV', 'development'),
                'owner': 'medical-team',
                'documentation': '/docs/api'
            },
            check={
                'name': f'{service_name} Health Check',
                'http': f"http://localhost:{service_port}/health",
                'interval': '10s',
                'timeout': '5s',
                'deregister_critical_service_after': '30s'
            }
        )
        logger.info("Successfully registered with Consul")
        return True
    except Exception as e:
        logger.error(f"Error registering service: {str(e)}")
        return False

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
                logger.error(f"Error in {func.__name__}: {str(e)}", exc_info=True)
                REQUEST_COUNT.labels(
                    method=method,
                    endpoint=endpoint,
                    status=status
                ).inc()
                span.set_attribute("error", True)
                span.set_attribute("error.message", str(e))
                return jsonify({'error': str(e)}), status
            finally:
                REQUEST_LATENCY.labels(
                    method=method,
                    endpoint=endpoint
                ).observe(time.time() - start_time)
    return wrapper

def get_service_url(service_name):
    """Get service URL from Consul with caching"""
    try:
        _, instances = consul_client.catalog.service(service_name)
        if not instances:
            return None
        
        # Simple round-robin load balancing
        instance = instances[int(time.time()) % len(instances)]
        return f"http://{instance['ServiceAddress']}:{instance['ServicePort']}"
    except Exception as e:
        logger.error(f"Error getting service URL for {service_name}: {str(e)}")
        return None

@app.route('/health', methods=['GET'])
def health_check():
    """Enhanced health check endpoint with detailed status"""
    health_status = {
        'status': 'UP',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0',
        'service': 'reports-service'
    }
    
    # Check dependencies
    dependencies = {
        'mongodb': check_mongodb_connection(),
        'consul': check_consul_connection(),
        'xray': check_service_dependency('xray-service'),
        'knowledge': check_service_dependency('knowledge-service')
    }
    
    health_status['dependencies'] = dependencies
    
    # Determine overall status
    if not all(dep['status'] == 'UP' for dep in dependencies.values()):
        health_status['status'] = 'DEGRADED'
        return jsonify(health_status), 503
    
    return jsonify(health_status)

def check_mongodb_connection():
    """Check MongoDB connection status"""
    try:
        if mongodb_client:
            mongodb_client.admin.command('ping')
            return {'status': 'UP'}
    except Exception as e:
        logger.error(f"MongoDB health check failed: {str(e)}")
        return {'status': 'DOWN', 'error': str(e)}
    return {'status': 'DOWN', 'error': 'Client not initialized'}

def check_consul_connection():
    """Check Consul connection status"""
    try:
        consul_client.status.leader()
        return {'status': 'UP'}
    except Exception as e:
        logger.error(f"Consul health check failed: {str(e)}")
        return {'status': 'DOWN', 'error': str(e)}

def check_service_dependency(service_name):
    """Check dependency service health"""
    service_url = get_service_url(service_name)
    if not service_url:
        return {'status': 'DOWN', 'error': 'Service not found'}
    
    try:
        response = requests.get(
            f"{service_url}/health",
            timeout=5
        )
        return {'status': 'UP'} if response.ok else {'status': 'DOWN'}
    except Exception as e:
        logger.error(f"Service dependency check failed for {service_name}: {str(e)}")
        return {'status': 'DOWN', 'error': str(e)}

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    from prometheus_client import generate_latest
    return Response(generate_latest(), mimetype='text/plain')

# Initialize services and metrics server
mongodb_client = init_mongodb()
services = setup_services(mongodb_client)

def start_metrics_server():
    """Start Prometheus metrics server on a separate port"""
    start_http_server(9090)

if __name__ == '__main__':
    # Start metrics server in a separate thread
    threading.Thread(target=start_metrics_server, daemon=True).start()
    
    # Register with Consul
    if not register_with_consul():
        logger.error("Failed to register with Consul, exiting...")
        exit(1)
    
    # Start the application
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', 5000)),
        threaded=True
    )


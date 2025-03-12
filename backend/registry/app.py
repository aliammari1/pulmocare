from flask import Flask, jsonify, request
import logging
import os
from datetime import datetime
import consul
import redis
import time
from functools import wraps
from flask_cors import CORS

app = Flask(__name__)

# Enable CORS
CORS(app)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Consul and Redis clients (initialized lazily)
consul_client = None
redis_client = None

def init_redis_client(max_retries=10, retry_interval=5):
    """Initialize Redis client with retry logic"""
    redis_host = os.getenv('REDIS_HOST', 'localhost')
    redis_port = int(os.getenv('REDIS_PORT', 6379))
    redis_password = os.getenv('REDIS_PASSWORD', 'redispass')
    
    for attempt in range(max_retries):
        try:
            client = redis.Redis(
                host=redis_host,
                port=redis_port,
                password=redis_password,
                decode_responses=True,
                socket_timeout=5,
                socket_connect_timeout=5,
                retry_on_timeout=True,
                health_check_interval=30
            )
            # Test connection
            client.ping()
            logger.info(f"Successfully connected to Redis at {redis_host}:{redis_port}")
            return client
        except redis.RedisError as e:
            logger.warning(f"Attempt {attempt+1}/{max_retries} to connect to Redis failed: {str(e)}")
            if attempt < max_retries - 1:
                logger.info(f"Retrying in {retry_interval} seconds...")
                time.sleep(retry_interval)
            else:
                logger.error(f"Failed to connect to Redis after {max_retries} attempts")
                return None

# Initialize clients with retry logic
def init_clients():
    global consul_client, redis_client
    
    # Consul client initialization with retry
    consul_host = os.getenv('CONSUL_HOST', 'localhost')
    consul_port = int(os.getenv('CONSUL_PORT', '8500'))
    max_retries = 10
    retry_interval = 5  # seconds
    
    for attempt in range(max_retries):
        try:
            consul_client = consul.Consul(host=consul_host, port=consul_port)
            # Test connection
            consul_client.status.leader()
            logger.info(f"Successfully connected to Consul at {consul_host}:{consul_port}")
            break
        except Exception as e:
            logger.warning(f"Attempt {attempt+1}/{max_retries} to connect to Consul failed: {str(e)}")
            if attempt < max_retries - 1:
                logger.info(f"Retrying in {retry_interval} seconds...")
                time.sleep(retry_interval)
            else:
                logger.error(f"Failed to connect to Consul after {max_retries} attempts")
    
    # Initialize Redis with the new function
    redis_client = init_redis_client()

# Ensure clients are available when needed
def ensure_clients():
    global consul_client, redis_client
    if consul_client is None or redis_client is None:
        init_clients()
    
    # Verify Redis connection is still active
    if redis_client:
        try:
            redis_client.ping()
        except (redis.ConnectionError, redis.TimeoutError):
            logger.warning("Redis connection lost, attempting to reconnect...")
            redis_client = init_redis_client()
    
    return consul_client is not None and redis_client is not None

def validate_service_metadata(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if request.method == 'POST':
            data = request.json
            required_fields = {'name', 'address', 'port', 'team', 'documentation'}
            if not data or not all(field in data for field in required_fields):
                return jsonify({'error': 'Missing required metadata fields'}), 400
        return f(*args, **kwargs)
    return wrapper

@app.route('/services/metadata', methods=['POST'])
@validate_service_metadata
def update_service_metadata():
    """Update service metadata in Redis"""
    if not ensure_clients():
        return jsonify({'error': 'Service unavailable - cannot connect to required services'}), 503
    
    data = request.json
    service_name = data['name']
    try:
        redis_client.hset(
            f"service:{service_name}:metadata",
            mapping={
                'team': data['team'],
                'documentation': data['documentation'],
                'updated_at': datetime.utcnow().isoformat()
            }
        )
        return jsonify({'status': 'success', 'service': service_name})
    except Exception as e:
        logger.error(f"Error updating metadata: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/services/health', methods=['GET'])
def get_services_health():
    """Get aggregated health status of all services"""
    if not ensure_clients():
        return jsonify({'error': 'Service unavailable - cannot connect to required services'}), 503
    
    try:
        services = {}
        _, registered_services = consul_client.catalog.services()
        
        for service_name in registered_services:
            _, instances = consul_client.catalog.service(service_name)
            metadata = redis_client.hgetall(f"service:{service_name}:metadata")
            
            healthy_instances = []
            unhealthy_instances = []
            
            for instance in instances:
                health_status = consul_client.agent.checks().get(
                    f"service:{instance['ServiceID']}"
                )
                instance_info = {
                    'id': instance['ServiceID'],
                    'address': instance['ServiceAddress'],
                    'port': instance['ServicePort']
                }
                
                if health_status and health_status['Status'] == 'passing':
                    healthy_instances.append(instance_info)
                else:
                    unhealthy_instances.append(instance_info)
            
            services[service_name] = {
                'healthy_count': len(healthy_instances),
                'total_count': len(instances),
                'healthy_instances': healthy_instances,
                'unhealthy_instances': unhealthy_instances,
                'metadata': metadata or {}
            }
        
        return jsonify({'services': services})
    except Exception as e:
        logger.error(f"Error getting service health: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    status = {'status': 'UP', 'timestamp': datetime.utcnow().isoformat(), 'connections': {}}
    
    try:
        # Only test Consul if client is available
        if consul_client:
            consul_client.status.leader()
            status['connections']['consul'] = 'UP'
        else:
            status['connections']['consul'] = 'DOWN'
            
        # Only test Redis if client is available
        if redis_client:
            redis_client.ping()
            status['connections']['redis'] = 'UP'
        else:
            status['connections']['redis'] = 'DOWN'
            
        # Consider service up even if some connections are down
        return jsonify(status)
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'DEGRADED',
            'timestamp': datetime.utcnow().isoformat(),
            'error': str(e),
            'connections': status.get('connections', {})
        }), 200  # Return 200 to prevent container restart loops

if __name__ == '__main__':
    # Initialize clients but don't fail if they're not available
    init_clients()
    
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', 8761)),
        debug=os.getenv('DEBUG', 'False').lower() == 'true',
        threaded=True
    )
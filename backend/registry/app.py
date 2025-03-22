from flask import Flask, jsonify, request
from datetime import datetime
import logging
import os
from config import Config
from health_check import health_check_middleware
from kong_consul_sync import KongConsulSync
import consul
import redis
import threading
import time
from functools import wraps
from flask_cors import CORS

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app = health_check_middleware(Config)(app)

# Enable CORS
CORS(app)

# Initialize services
consul_client = None
redis_client = None
kong_sync = None

def init_clients():
    """Initialize service clients"""
    global consul_client, redis_client, kong_sync
    try:
        consul_client = consul.Consul(**Config.get_consul_config())
        redis_client = redis.Redis(**Config.get_redis_config())
        kong_sync = KongConsulSync(Config)
        logger.info("Successfully initialized service clients")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize clients: {str(e)}")
        return False

def watch_services():
    """Watch for service changes in Consul and sync to Kong"""
    global consul_client, kong_sync
    
    index = None
    while True:
        try:
            index, services = consul_client.catalog.services(index=index)
            
            for service_name in services:
                _, service_data = consul_client.catalog.service(service_name)
                if service_data:
                    kong_sync.sync_service(service_name, service_data[0])
            
            time.sleep(5)  # Wait before next check
        except Exception as e:
            logger.error(f"Service watch error: {str(e)}")
            time.sleep(5)  # Wait before retry

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
    if not redis_client:
        return jsonify({'error': 'Service registry unavailable'}), 503

    try:
        data = request.json
        service_name = data.get('name')
        metadata = data.get('metadata', {})
        
        if not service_name:
            return jsonify({'error': 'Service name is required'}), 400
        
        redis_client.hmset(f"service:{service_name}:metadata", metadata)
        return jsonify({'status': 'success'})
    except Exception as e:
        logger.error(f"Error updating service metadata: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/services/health', methods=['GET'])
def get_services_health():
    """Get aggregated health status of all services"""
    if not consul_client:
        return jsonify({'error': 'Service registry unavailable'}), 503
    
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
    # Initialize clients
    if init_clients():
        # Start service watcher in a background thread
        watcher_thread = threading.Thread(target=watch_services, daemon=True)
        watcher_thread.start()
        
        app.run(
            host=Config.HOST,
            port=Config.PORT,
            debug=os.getenv('DEBUG', 'False').lower() == 'true',
            threaded=True
        )
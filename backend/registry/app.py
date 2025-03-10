from flask import Flask, jsonify, request
import logging
import os
from datetime import datetime
import consul
import redis
from functools import wraps

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Consul client
consul_host = os.getenv('CONSUL_HOST', 'localhost')
consul_port = int(os.getenv('CONSUL_PORT', '8500'))
consul_client = consul.Consul(host=consul_host, port=consul_port)

# Initialize Redis for caching
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'redis'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    password=os.getenv('REDIS_PASSWORD', 'redispass'),
    decode_responses=True
)

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
    try:
        # Verify Consul connection
        consul_client.status.leader()
        # Verify Redis connection
        redis_client.ping()
        
        return jsonify({
            'status': 'UP',
            'timestamp': datetime.utcnow().isoformat(),
            'connections': {
                'consul': 'UP',
                'redis': 'UP'
            }
        })
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'DOWN',
            'timestamp': datetime.utcnow().isoformat(),
            'error': str(e)
        }), 503

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', 8761)),
        threaded=True
    )
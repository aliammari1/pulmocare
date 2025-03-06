import consul
from flask import Flask, jsonify, request
import logging
import os
from datetime import datetime
import requests
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

def validate_service_metadata(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if request.method == 'POST':
            data = request.json
            required_fields = {'name', 'address', 'port'}
            if not data or not all(field in data for field in required_fields):
                return jsonify({'error': 'Missing required fields'}), 400
            
            # Validate port number
            if not isinstance(data['port'], int) or not (0 < data['port'] < 65536):
                return jsonify({'error': 'Invalid port number'}), 400
        return f(*args, **kwargs)
    return wrapper

def register_with_consul():
    """Register the registry service itself with Consul"""
    service_name = "service-registry"
    service_id = f"{service_name}-{os.getenv('HOSTNAME', 'main')}"
    service_port = int(os.getenv('SERVER_PORT', '8761'))
    
    try:
        consul_client.agent.service.register(
            name=service_name,
            service_id=service_id,
            address=os.getenv('HOSTNAME', 'localhost'),
            port=service_port,
            tags=['registry', 'core'],
            meta={
                'version': '1.0.0',
                'environment': os.getenv('ENV', 'development')
            },
            check={
                'name': 'Registry Health Check',
                'http': f"http://localhost:{service_port}/health",
                'interval': '10s',
                'timeout': '5s',
                'deregister_critical_service_after': '30s'
            }
        )
        logger.info(f"Registered {service_name} with Consul")
    except Exception as e:
        logger.error(f"Failed to register with Consul: {str(e)}")
        raise

@app.route('/register', methods=['POST'])
@validate_service_metadata
def register_service():
    """Register a service with Consul"""
    data = request.json
    try:
        service_id = f"{data['name']}-{data.get('id', datetime.now().strftime('%Y%m%d-%H%M%S'))}"
        
        # Enhanced health check configuration
        health_check = {
            'name': f"{data['name']} Health Check",
            'http': f"http://{data['address']}:{data['port']}/health",
            'interval': data.get('check_interval', '10s'),
            'timeout': data.get('check_timeout', '5s'),
            'deregister_critical_service_after': data.get('deregister_after', '30s')
        }

        # Register with metadata
        consul_client.agent.service.register(
            name=data['name'],
            service_id=service_id,
            address=data['address'],
            port=data['port'],
            tags=data.get('tags', []),
            meta={
                'version': data.get('version', '1.0.0'),
                'environment': os.getenv('ENV', 'development'),
                'documentation': data.get('documentation', ''),
                'owner': data.get('owner', ''),
                'team': data.get('team', '')
            },
            check=health_check
        )
        
        logger.info(f"Service registered: {data['name']} ({service_id})")
        return jsonify({
            'status': 'registered',
            'service_id': service_id,
            'health_check': health_check
        })
    except Exception as e:
        logger.error(f"Error registering service: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/deregister/<service_id>', methods=['DELETE'])
def deregister_service(service_id):
    """Deregister a service from Consul"""
    try:
        consul_client.agent.service.deregister(service_id)
        logger.info(f"Service deregistered: {service_id}")
        return '', 204
    except Exception as e:
        logger.error(f"Error deregistering service: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/services', methods=['GET'])
def get_services():
    """Get all registered services with health status"""
    try:
        services = {}
        _, services_list = consul_client.catalog.services()
        
        for service_name in services_list:
            _, instances = consul_client.catalog.service(service_name)
            service_checks = []
            
            for instance in instances:
                health_status = consul_client.agent.checks()[f"service:{instance['ServiceID']}"]
                instance['health'] = health_status['Status']
                instance['last_check'] = health_status['Output']
            
            services[service_name] = {
                'instances': instances,
                'total': len(instances),
                'healthy': sum(1 for i in instances if i['health'] == 'passing')
            }
            
        return jsonify({'services': services})
    except Exception as e:
        logger.error(f"Error getting services: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/service/<service_name>', methods=['GET'])
def get_service(service_name):
    """Get instances of a specific service with detailed health information"""
    try:
        _, instances = consul_client.catalog.service(service_name)
        if not instances:
            return jsonify({'error': 'Service not found'}), 404
        
        detailed_instances = []
        for instance in instances:
            health_status = consul_client.agent.checks()[f"service:{instance['ServiceID']}"]
            instance_details = {
                **instance,
                'health': health_status['Status'],
                'last_check': health_status['Output'],
                'last_check_time': health_status['LastUpdateTime']
            }
            detailed_instances.append(instance_details)
            
        return jsonify({
            'service': service_name,
            'instances': detailed_instances,
            'summary': {
                'total': len(detailed_instances),
                'healthy': sum(1 for i in detailed_instances if i['health'] == 'passing')
            }
        })
    except Exception as e:
        logger.error(f"Error getting service: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    """Enhanced health check endpoint"""
    try:
        # Check Consul connection
        consul_client.status.leader()
        
        return jsonify({
            'status': 'UP',
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0',
            'consul_connection': 'UP'
        })
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'DOWN',
            'timestamp': datetime.now().isoformat(),
            'error': str(e)
        }), 503

if __name__ == '__main__':
    # Register the registry service itself
    register_with_consul()
    
    # Start Flask app
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('SERVER_PORT', 8761)),
        threaded=True
    )
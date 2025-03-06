from flask import Flask, jsonify, request
import requests
import logging
import os
import consul
from functools import wraps
from datetime import datetime
from circuitbreaker import circuit
import time
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import redis
from typing import Optional, Dict, Any

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Redis for rate limiting
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'redis'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    db=0
)

# Initialize rate limiter
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    storage_uri=f"redis://{os.getenv('REDIS_HOST', 'redis')}:6379",
    strategy="fixed-window-elastic-expiry"
)

# Initialize Consul client
consul_host = os.getenv('CONSUL_HOST', 'localhost')
consul_port = int(os.getenv('CONSUL_PORT', '8500'))
consul_client = consul.Consul(host=consul_host, port=consul_port)

# Service cache with TTL
service_cache: Dict[str, Dict[str, Any]] = {}
SERVICE_CACHE_TTL = 30  # seconds

def get_service_url(service_name: str) -> Optional[str]:
    """Get service URL from Consul with caching and load balancing"""
    current_time = time.time()
    
    # Check cache first
    if service_name in service_cache:
        cache_entry = service_cache[service_name]
        if current_time - cache_entry['timestamp'] < SERVICE_CACHE_TTL:
            instances = cache_entry['instances']
            if instances:
                # Round-robin load balancing
                instance = instances[int(current_time) % len(instances)]
                return f"http://{instance['ServiceAddress']}:{instance['ServicePort']}"
    
    try:
        # Cache miss or expired, fetch from Consul
        _, instances = consul_client.catalog.service(service_name)
        if not instances:
            return None
        
        # Update cache
        service_cache[service_name] = {
            'timestamp': current_time,
            'instances': instances
        }
        
        # Return URL using round-robin
        instance = instances[int(current_time) % len(instances)]
        return f"http://{instance['ServiceAddress']}:{instance['ServicePort']}"
    except Exception as e:
        logger.error(f"Error getting service URL for {service_name}: {str(e)}")
        return None

@circuit(
    failure_threshold=5,
    recovery_timeout=60,
    expected_exception=requests.RequestException
)
def make_service_request(url: str, method: str, **kwargs) -> requests.Response:
    """Make HTTP request with circuit breaker pattern"""
    timeout = kwargs.pop('timeout', 10)
    retries = kwargs.pop('retries', 3)
    
    for attempt in range(retries):
        try:
            response = requests.request(
                method,
                url,
                timeout=timeout,
                **kwargs
            )
            response.raise_for_status()
            return response
        except requests.RequestException as e:
            if attempt == retries - 1:
                raise
            logger.warning(f"Request failed (attempt {attempt + 1}/{retries}): {str(e)}")
            time.sleep(2 ** attempt)  # Exponential backoff

def handle_service_error(f):
    """Enhanced decorator to handle service errors with detailed error responses"""
    @wraps(f)
    def wrapper(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except requests.HTTPError as e:
            logger.error(f"HTTP error occurred: {str(e)}")
            return jsonify({
                'error': 'Service error',
                'message': str(e),
                'status_code': e.response.status_code
            }), e.response.status_code
        except requests.ConnectionError:
            logger.error("Service connection error")
            return jsonify({
                'error': 'Service unavailable',
                'message': 'Service is temporarily unavailable'
            }), 503
        except requests.Timeout:
            logger.error("Service timeout")
            return jsonify({
                'error': 'Service timeout',
                'message': 'Service request timed out'
            }), 504
        except Exception as e:
            logger.error(f"Unexpected error: {str(e)}")
            return jsonify({
                'error': 'Internal server error',
                'message': 'An unexpected error occurred'
            }), 500
    return wrapper

def proxy_request(service_name: str, path: str, method: str = 'GET') -> tuple:
    """Proxy request to a service with enhanced error handling and retries"""
    service_url = get_service_url(service_name)
    if not service_url:
        return jsonify({
            'error': 'Service unavailable',
            'message': f'Service {service_name} is not available'
        }), 503
    
    url = f"{service_url}{path}"
    kwargs = {
        'headers': {
            'X-Request-ID': request.headers.get('X-Request-ID', ''),
            'X-Forwarded-For': request.remote_addr,
            'X-Original-URI': request.url,
            'X-Service-Name': service_name
        },
        'timeout': 10,
        'retries': 3
    }
    
    if method in ['POST', 'PUT', 'PATCH']:
        kwargs['json'] = request.json
    elif method == 'GET':
        kwargs['params'] = request.args
    
    try:
        response = make_service_request(url, method, **kwargs)
        return response.json(), response.status_code
    except Exception as e:
        logger.error(f"Error proxying request to {service_name}: {str(e)}")
        raise

def register_with_consul():
    """Register the gateway service with enhanced metadata"""
    try:
        service_name = "gateway"
        service_id = f"{service_name}-{os.getenv('HOSTNAME', 'main')}"
        service_port = int(os.getenv('PORT', 5000))
        
        consul_client.agent.service.register(
            name=service_name,
            service_id=service_id,
            address=os.getenv('HOSTNAME', 'localhost'),
            port=service_port,
            tags=['gateway', 'api', 'core'],
            meta={
                'version': '1.0.0',
                'environment': os.getenv('ENV', 'development'),
                'documentation': '/swagger'
            },
            check={
                'name': 'Gateway Health Check',
                'http': f"http://localhost:{service_port}/health",
                'interval': '10s',
                'timeout': '5s',
                'deregister_critical_service_after': '30s'
            }
        )
        logger.info("Gateway service registered with Consul")
    except Exception as e:
        logger.error(f"Failed to register with Consul: {str(e)}")

# Service route handlers with rate limiting
@app.route('/api/xray/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("60/minute")
@handle_service_error
def xray_service(path):
    return proxy_request('xray-service', f"/{path}", request.method)

@app.route('/api/knowledge/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("120/minute")
@handle_service_error
def knowledge_service(path):
    return proxy_request('knowledge-service', f"/{path}", request.method)

@app.route('/api/reports/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("60/minute")
@handle_service_error
def reports_service(path):
    return proxy_request('reports-service', f"/{path}", request.method)

@app.route('/api/medecins/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("30/minute")
@handle_service_error
def medecins_service(path):
    return proxy_request('medecins-service', f"/{path}", request.method)

@app.route('/api/patients/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("30/minute")
@handle_service_error
def patients_service(path):
    return proxy_request('patients-service', f"/{path}", request.method)

@app.route('/api/radiologue/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("30/minute")
@handle_service_error
def radiologue_service(path):
    return proxy_request('radiologue-service', f"/{path}", request.method)

@app.route('/health')
def health():
    """Enhanced health check endpoint"""
    services_status = {}
    critical_services = ['xray-service', 'knowledge-service', 'reports-service']
    
    for service in critical_services:
        service_url = get_service_url(service)
        services_status[service] = 'UP' if service_url else 'DOWN'
    
    status = 'UP' if all(status == 'UP' for status in services_status.values()) else 'DEGRADED'
    
    return jsonify({
        'status': status,
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0',
        'services': services_status,
        'cache': {
            'size': len(service_cache),
            'ttl': SERVICE_CACHE_TTL
        }
    })

if __name__ == '__main__':
    # Register with Consul
    register_with_consul()
    
    # Start the server
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', 5000)),
        threaded=True
    )
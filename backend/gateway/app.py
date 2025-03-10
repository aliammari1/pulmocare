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
from flask_cors import CORS

app = Flask(__name__)

# Configure CORS
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:3000", "http://localhost:5000"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Request-ID"]
    }
})

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
    password=os.getenv('REDIS_PASSWORD', 'redispass'),
    db=0,
    decode_responses=True
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
    cache_key = f"service_{service_name}"
    
    # Try to get from Redis cache first
    cached_url = redis_client.get(cache_key)
    if cached_url:
        return cached_url.decode('utf-8')
        
    try:
        # Fetch from Consul
        _, instances = consul_client.catalog.service(service_name)
        if not instances:
            logger.warning(f"No instances found for service: {service_name}")
            return None
            
        # Get healthy instances
        healthy_instances = []
        for instance in instances:
            checks = consul_client.agent.checks()
            service_check = checks.get(f"service:{instance['ServiceID']}")
            if service_check and service_check['Status'] == 'passing':
                healthy_instances.append(instance)
        
        if not healthy_instances:
            logger.warning(f"No healthy instances for service: {service_name}")
            return None
            
        # Simple round-robin load balancing
        instance = healthy_instances[int(time.time()) % len(healthy_instances)]
        service_url = f"http://{instance['ServiceAddress']}:{instance['ServicePort']}"
        
        # Cache the result
        redis_client.setex(cache_key, 30, service_url)
        return service_url
        
    except Exception as e:
        logger.error(f"Error discovering service {service_name}: {str(e)}")
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

# Service route handlers with rate limiting
@app.route('/api/xray/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("60/minute")
@handle_service_error
def xray_service(path):
    return proxy_request('xray-service', f"/{path}", request.method)

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
    """Health check endpoint"""
    try:
        # Check Redis connection
        redis_client.ping()
        # Check Consul connection
        consul_client.status.leader()
        
        return jsonify({
            'status': 'UP',
            'timestamp': datetime.utcnow().isoformat(),
            'cache': {
                'size': len(service_cache),
                'ttl': SERVICE_CACHE_TTL
            }
        })
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'DOWN',
            'error': str(e)
        }), 503

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', 5000)),
        threaded=True
    )
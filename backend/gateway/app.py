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
CORS(app)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Redis for rate limiting
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'localhost'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    password=os.getenv('REDIS_PASSWORD', 'redispass'),
    db=0,
    decode_responses=True
)

# Initialize rate limiter
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    storage_uri=f"redis://:{os.getenv('REDIS_PASSWORD', 'redispass')}@{os.getenv('REDIS_HOST', 'localhost')}:6379",
    strategy="fixed-window"
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
    cache_key = f"service_{service_name}"
    
    # Try to get from Redis cache first
    cached_url = redis_client.get(cache_key)
    if cached_url:
        logger.debug(f"Using cached URL for {service_name}: {cached_url}")
        return cached_url.decode('utf-8')
        
    try:
        # Log what we're looking for
        logger.info(f"Looking up service in Consul: {service_name}")
        
        # Fetch from Consul
        _, instances = consul_client.catalog.service(service_name)
        logger.info(f"Found {len(instances)} instances of {service_name}")
        
        if not instances:
            # Try with variations of the service name
            alternative_names = [
                service_name.replace('-', '_'),
                service_name.replace('-', ''),
                service_name.replace('_', '-'),
                service_name.split('-')[0] if '-' in service_name else service_name
            ]
            
            for alt_name in alternative_names:
                if alt_name != service_name:
                    logger.info(f"Trying alternative name: {alt_name}")
                    _, alt_instances = consul_client.catalog.service(alt_name)
                    if alt_instances:
                        logger.info(f"Found service under alternative name: {alt_name}")
                        instances = alt_instances
                        break
            
            # If still no instances found
            if not instances:
                # List all available services for debugging
                index, services = consul_client.catalog.services()
                logger.warning(f"No instances found for service: {service_name}. Available services: {list(services.keys())}")
                return None
        
        # Get healthy instances
        healthy_instances = []
        for instance in instances:
            logger.debug(f"Checking health for instance: {instance['ServiceID']}")
            checks = consul_client.agent.checks()
            service_check = checks.get(f"service:{instance['ServiceID']}")
            
            if service_check:
                logger.debug(f"Check status for {instance['ServiceID']}: {service_check['Status']}")
                if service_check['Status'] == 'passing':
                    healthy_instances.append(instance)
            else:
                # If no specific check, assume it's healthy
                logger.debug(f"No health check found for {instance['ServiceID']}, assuming healthy")
                healthy_instances.append(instance)
        
        if not healthy_instances:
            logger.warning(f"No healthy instances for service: {service_name}")
            # Fall back to using any instance if none are healthy
            if instances:
                logger.info(f"Falling back to unhealthy instance for {service_name}")
                instance = instances[0]
                service_url = f"http://{instance['ServiceAddress']}:{instance['ServicePort']}"
                return service_url
            return None
            
        # Simple round-robin load balancing
        instance = healthy_instances[int(time.time()) % len(healthy_instances)]
        service_url = f"http://{instance['ServiceAddress']}:{instance['ServicePort']}"
        logger.info(f"Selected instance for {service_name}: {service_url}")
        
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
    
    logger.debug(f"Making {method} request to {url}")
    
    for attempt in range(retries):
        try:
            response = requests.request(
                method,
                url,
                timeout=timeout,
                **kwargs
            )
            logger.debug(f"Response from {url}: status={response.status_code}")
            response.raise_for_status()
            return response
        except requests.RequestException as e:
            if attempt == retries - 1:
                logger.error(f"Failed after {retries} attempts: {str(e)}")
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
            error_details = {}
            
            # Try to extract more detailed error information from the response
            try:
                error_details = e.response.json()
                logger.error(f"Error details from service: {error_details}")
            except:
                logger.error("Could not parse error details from service response")
            
            response_data = {
                'error': 'Service error',
                'message': str(e),
                'status_code': e.response.status_code
            }
            
            # Add service error details if available
            if error_details:
                response_data['service_error'] = error_details
                
            return jsonify(response_data), e.response.status_code
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
        logger.error(f"Service {service_name} not available in Consul")
        # List available services for debugging
        _, services = consul_client.catalog.services()
        logger.info(f"Available services: {list(services.keys())}")
        return jsonify({
            'error': 'Service unavailable',
            'message': f'Service {service_name} is not available'
        }), 503

    # Ensure path starts with a slash if not empty
    if path and not path.startswith('/'):
        path = '/' + path

    url = f"{service_url}{path}"
    logger.info(f"Proxying {method} request to {url}")
    
    # Forward all original headers
    headers = {key: value for key, value in request.headers.items()
               if key.lower() not in ['host', 'content-length', 'connection']}
    
    # Add proxy-specific headers
    headers.update({
        'X-Request-ID': request.headers.get('X-Request-ID', ''),
        'X-Forwarded-For': request.remote_addr,
        'X-Original-URI': request.url,
        'X-Service-Name': service_name
    })
    
    kwargs = {
        'headers': headers,
        'timeout': 10,
        'retries': 3
    }
    
    if method in ['POST', 'PUT', 'PATCH']:
        if request.is_json:
            kwargs['json'] = request.json
        else:
            kwargs['data'] = request.data
    elif method == 'GET':
        kwargs['params'] = request.args
    
    try:
        response = make_service_request(url, method, **kwargs)
        # Log more details about successful responses for debugging
        logger.debug(f"Successful response from {service_name}: {response.status_code}")
        
        # Handle empty responses
        if not response.content:
            logger.warning(f"Empty response received from {service_name}")
            return jsonify({
                'warning': 'Empty response',
                'message': f'Service {service_name} returned an empty response'
            }), 204
            
        # Try to return as JSON, but handle text responses too
        try:
            return response.json(), response.status_code
        except ValueError:
            # Not JSON, return as text
            return response.text, response.status_code
    except Exception as e:
        logger.error(f"Error proxying request to {service_name}: {str(e)}")
        raise

# Service route handlers with rate limiting
@app.route('/api/xray/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("60/minute")
@handle_service_error
def xray_service(path):
    return proxy_request('xray-service', f"/{path}", request.method)

# Fix reports service routes
@app.route('/api/reports/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("60/minute")
@handle_service_error
def reports_service(path):
    return proxy_request('reports-service', f"/api/{path}", request.method)

# Add patient-specific routes
@app.route('/api/patient/signup', methods=['POST'])
@limiter.limit("10/minute")
@handle_service_error
def patient_signup():
    return proxy_request('patients-service', f"/api/patient/signup", request.method)

@app.route('/api/patient/login', methods=['POST'])
@limiter.limit("20/minute")
@handle_service_error
def patient_login():
    return proxy_request('patients-service', f"/api/patient/login", request.method)

@app.route('/api/patient/forgot-password', methods=['POST'])
@limiter.limit("5/minute")
@handle_service_error
def patient_forgot_password():
    return proxy_request('patients-service', f"/api/patient/forgot-password", request.method)

@app.route('/api/patient/verify-otp', methods=['POST'])
@limiter.limit("10/minute")
@handle_service_error
def patient_verify_otp():
    return proxy_request('patients-service', f"/api/patient/verify-otp", request.method)

@app.route('/api/patient/reset-password', methods=['POST'])
@limiter.limit("5/minute")
@handle_service_error
def patient_reset_password():
    return proxy_request('patients-service', f"/api/patient/reset-password", request.method)


@app.route('/api/patient/list', methods=['GET'])
@limiter.limit("30/minute")
@handle_service_error
def patient_list():
    return proxy_request('patients-service', '/api/patient/list', request.method)


# Add direct routes to medecins service endpoints
@app.route('/api/signup', methods=['POST'])
@limiter.limit("10/minute")
@handle_service_error
def signup():
    return proxy_request('medecins-service', f"/api/signup", request.method)

@app.route('/api/login', methods=['POST'])
@limiter.limit("20/minute")
@handle_service_error
def login():
    return proxy_request('medecins-service', f"/api/login", request.method)

@app.route('/api/forgot-password', methods=['POST'])
@limiter.limit("5/minute")
@handle_service_error
def forgot_password():
    return proxy_request('medecins-service', f"/api/forgot-password", request.method)

@app.route('/api/verify-otp', methods=['POST'])
@limiter.limit("10/minute")
@handle_service_error
def verify_otp():
    return proxy_request('medecins-service', f"/api/verify-otp", request.method)

@app.route('/api/reset-password', methods=['POST'])
@limiter.limit("5/minute")
@handle_service_error
def reset_password():
    return proxy_request('medecins-service', f"/api/reset-password", request.method)

@app.route('/api/profile', methods=['GET'])
@limiter.limit("30/minute")
@handle_service_error
def get_profile():
    return proxy_request('medecins-service', f"/api/profile", request.method)

@app.route('/api/change-password', methods=['POST'])
@limiter.limit("5/minute")
@handle_service_error
def change_password():
    return proxy_request('medecins-service', f"/api/change-password", request.method)

@app.route('/api/update-profile', methods=['PUT'])
@limiter.limit("10/minute")
@handle_service_error
def update_profile():
    return proxy_request('medecins-service', f"/api/update-profile", request.method)

@app.route('/api/logout', methods=['POST'])
@limiter.limit("10/minute")
@handle_service_error
def logout():
    return proxy_request('medecins-service', f"/api/logout", request.method)

@app.route('/api/scan-visit-card', methods=['POST'])
@limiter.limit("10/minute")
@handle_service_error
def scan_visit_card():
    return proxy_request('medecins-service', f"/api/scan-visit-card", request.method)

@app.route('/api/verify-doctor', methods=['POST'])
@limiter.limit("5/minute")
@handle_service_error
def verify_doctor():
    return proxy_request('medecins-service', f"/api/verify-doctor", request.method)

@app.route('/api/update-signature', methods=['POST'])
@limiter.limit("5/minute")
@handle_service_error
def update_signature():
    return proxy_request('medecins-service', f"/api/update-signature", request.method)

# Fix medecins service routes
@app.route('/api/medecins/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("30/minute")
@handle_service_error
def medecins_service(path):
    return proxy_request('medecins-service', f"/api/{path}", request.method)

# Fix patients service routes
@app.route('/api/patients/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("30/minute")
@handle_service_error
def patients_service(path):
    return proxy_request('patients-service', f"/{path}", request.method)

# Fix radiologues service routes
@app.route('/api/radiologues/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("30/minute")
@handle_service_error
def radiologues_service(path):
    return proxy_request('radiologues-service', f"/api/{path}", request.method)

# Fix ordonnances service routes - consolidate into a single route handler
@app.route('/api/ordonnances/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
@limiter.limit("60/minute")
@handle_service_error
def ordonnances_service(path):
    return proxy_request('ordonnances-service', f"/api/ordonnances/{path}", request.method)

@app.route('/api/ordonnances', methods=['GET', 'POST'])
@limiter.limit("60/minute")
@handle_service_error
def ordonnances_root():
    return proxy_request('ordonnances-service', f"/api/ordonnances", request.method)

@app.route('/api/ordonnances/medecin/<medecin_id>/ordonnances', methods=['GET'])
@limiter.limit("30/minute")
@handle_service_error
def get_medecin_ordonnances(medecin_id):
    return proxy_request('ordonnances-service', f"/api/ordonnances/medecin/{medecin_id}/ordonnances", request.method)

@app.route('/api/ordonnances/<ordonnance_id>/pdf', methods=['GET'])
@limiter.limit("20/minute")
@handle_service_error
def get_ordonnance_pdf(ordonnance_id):
    return proxy_request('ordonnances-service', f"/api/ordonnances/{ordonnance_id}/pdf", request.method)

@app.route('/api/ordonnances/ordonnance/<ordonnance_id>', methods=['GET'])
@limiter.limit("30/minute")
@handle_service_error
def get_ordonnance(ordonnance_id):
    return proxy_request('ordonnances-service', f"/api/ordonnances/ordonnance/{ordonnance_id}", request.method)

@app.route('/api/ordonnances/ordonnances/<ordonnance_id>/pdf', methods=['POST'])
@limiter.limit("20/minute")
@handle_service_error
def save_ordonnance_pdf(ordonnance_id):
    return proxy_request('ordonnances-service', f"/api/ordonnances/ordonnances/{ordonnance_id}/pdf", request.method)

@app.route('/api/ordonnances/ordonnances/<ordonnance_id>/verify', methods=['GET'])
@limiter.limit("20/minute")
@handle_service_error
def verify_ordonnance(ordonnance_id):
    return proxy_request('ordonnances-service', f"/api/ordonnances/ordonnances/{ordonnance_id}/verify", request.method)

@app.route('/api/ordonnances/test', methods=['GET'])
@limiter.limit("30/minute")
@handle_service_error
def test_ordonnances_connection():
    return proxy_request('ordonnances-service', f"/api/ordonnances/test", request.method)

# Add registry service routes
@app.route('/registry/services', methods=['GET'])
@limiter.limit("30/minute")
@handle_service_error
def registry_services():
    return proxy_request('registry', '/services/health', 'GET')

@app.route('/registry/metadata', methods=['POST'])
@limiter.limit("30/minute")
@handle_service_error
def registry_metadata():
    return proxy_request('registry', '/services/metadata', 'POST')

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
            'timestamp': datetime.now().isoformat(),
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

@app.route('/api/services')
def list_services():
    """List all services registered in Consul"""
    try:
        _, services = consul_client.catalog.services()
        service_details = {}
        
        for service_name in services:
            _, instances = consul_client.catalog.service(service_name)
            service_details[service_name] = {
                'instances': len(instances),
                'addresses': [f"{instance['ServiceAddress']}:{instance['ServicePort']}" 
                             for instance in instances]
            }
        
        return jsonify({
            'services': service_details
        })
    except Exception as e:
        logger.error(f"Error listing services: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', 5000)),
        debug=True,
        threaded=True
    )
from flask import Flask, request, make_response, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from routes.ordonnance_routes import ordonnance_bp
import os
from config import Config
from consul_service import ConsulService
import datetime
from pymongo import MongoClient
load_dotenv()

app = Flask(__name__)
CORS(app)

# Initialize MongoDB client for health checks
mongo_client = MongoClient(Config.get_mongodb_uri())



@app.before_request
def handle_preflight():
    if request.method == "OPTIONS":
        response = make_response()
        response.headers.update({
            "Access-Control-Allow-Origin": request.headers.get("Origin", "*"),
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin",
            "Access-Control-Max-Age": "3600",
            "Access-Control-Allow-Credentials": "true"
        })
        return response

@app.after_request
def after_request(response):
    origin = request.headers.get('Origin', '')
    if origin:
        response.headers.add('Access-Control-Allow-Origin', origin)
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization,Accept,Origin')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    response.headers.add('Access-Control-Allow-Credentials', 'true')
    return response

# Add health check endpoint for Consul
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for Consul"""
    try:
        # Ping MongoDB to verify connection
        mongo_client.admin.command('ping')
        
        return jsonify({
            'status': 'UP',
            'service': 'ordonnances-service',
            'timestamp': datetime.datetime.utcnow().isoformat(),
            'dependencies': {
                'mongodb': 'UP'
            }
        }), 200
    except Exception as e:
        app.logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'status': 'DOWN',
            'error': str(e),
            'timestamp': datetime.datetime.utcnow().isoformat()
        }), 503

app.register_blueprint(ordonnance_bp, url_prefix='/api/ordonnances')

if __name__ == '__main__':
    ConsulService(Config).register_service()
    app.run(debug=True, host='0.0.0.0', port=8082)

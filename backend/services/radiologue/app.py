from flask import Flask, jsonify, request
from flask_cors import CORS
import logging
import os
import consul
from datetime import datetime
from functools import wraps
import pymongo
from bson import ObjectId
from bson.json_util import dumps, loads

app = Flask(__name__)
CORS(app)

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

# MongoDB connection setup
def get_mongodb_client():
    """Get MongoDB client using environment variables"""
    try:
        username = os.getenv('MONGODB_USERNAME', 'medapp')
        password = os.getenv('MONGODB_PASSWORD', 'medapppass')
        host = os.getenv('MONGODB_HOST', 'mongodb')
        port = int(os.getenv('MONGODB_PORT', '27017'))
        database = os.getenv('MONGODB_DATABASE', 'medapp')
        
        client = pymongo.MongoClient(f"mongodb://{username}:{password}@{host}:{port}/{database}")
        return client
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {str(e)}")
        return None

# Initialize MongoDB client
mongodb_client = get_mongodb_client()

def register_with_consul():
    """Register service with Consul"""
    try:
        service_name = "radiologue"
        service_id = f"{service_name}-{os.getenv('HOSTNAME', 'main')}"
        service_port = int(os.getenv('SERVER_PORT', '8084'))
        
        consul_client.agent.service.register(
            name=service_name,
            service_id=service_id,
            address=os.getenv('HOSTNAME', 'localhost'),
            port=service_port,
            tags=['radiologue', 'medical'],
            check={
                'http': f"http://localhost:{service_port}/health",
                'interval': '10s'
            }
        )
        logger.info("Successfully registered with Consul")
        return True
    except Exception as e:
        logger.error(f"Error registering service: {str(e)}")
        return False

# Error handling decorator
def handle_errors(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except Exception as e:
            logger.error(f"Error in {f.__name__}: {str(e)}", exc_info=True)
            return jsonify({'error': str(e)}), 500
    return wrapper

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    mongodb_status = 'up' if mongodb_client else 'down'
    return jsonify({
        'status': 'up',
        'service': 'radiologue-service',
        'version': '1.0.0',
        'mongodb': mongodb_status,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/radiologists', methods=['POST'])
@handle_errors
def create_radiologist():
    """Create a new radiologist"""
    if not mongodb_client:
        return jsonify({'error': 'Database connection not available'}), 503

    data = request.json
    if not data or not all(k in data for k in ('name', 'email', 'specialization')):
        return jsonify({'error': 'Missing required fields'}), 400

    try:
        db = mongodb_client.get_database()
        # Check if radiologist with email already exists
        if db.radiologists.find_one({'email': data['email']}):
            return jsonify({'error': 'Radiologist with this email already exists'}), 409

        radiologist = {
            'name': data['name'],
            'email': data['email'],
            'specialization': data['specialization'],
            'status': data.get('status', 'active'),
            'hospital': data.get('hospital'),
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }
        
        result = db.radiologists.insert_one(radiologist)
        radiologist['_id'] = str(result.inserted_id)
        
        return jsonify(radiologist), 201
    except Exception as e:
        logger.error(f"Error creating radiologist: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/radiologists', methods=['GET'])
@handle_errors
def get_radiologists():
    """Get list of radiologists with optional filtering"""
    if not mongodb_client:
        return jsonify({'error': 'Database connection not available'}), 503

    try:
        db = mongodb_client.get_database()
        
        # Build query from request parameters
        query = {}
        if request.args.get('status'):
            query['status'] = request.args.get('status')
        if request.args.get('specialization'):
            query['specialization'] = request.args.get('specialization')
        if request.args.get('hospital'):
            query['hospital'] = request.args.get('hospital')

        radiologists = list(db.radiologists.find(query))
        # Convert ObjectId to string
        for r in radiologists:
            r['_id'] = str(r['_id'])
            
        return jsonify({'radiologists': radiologists})
    except Exception as e:
        logger.error(f"Error getting radiologists: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/radiologists/<radiologist_id>', methods=['GET'])
@handle_errors
def get_radiologist(radiologist_id):
    """Get a specific radiologist by ID"""
    if not mongodb_client:
        return jsonify({'error': 'Database connection not available'}), 503

    try:
        db = mongodb_client.get_database()
        radiologist = db.radiologists.find_one({'_id': ObjectId(radiologist_id)})
        
        if not radiologist:
            return jsonify({'error': 'Radiologist not found'}), 404
            
        radiologist['_id'] = str(radiologist['_id'])
        return jsonify(radiologist)
    except Exception as e:
        logger.error(f"Error getting radiologist: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/radiologists/<radiologist_id>', methods=['PUT'])
@handle_errors
def update_radiologist(radiologist_id):
    """Update a radiologist's information"""
    if not mongodb_client:
        return jsonify({'error': 'Database connection not available'}), 503

    data = request.json
    if not data:
        return jsonify({'error': 'No update data provided'}), 400

    try:
        db = mongodb_client.get_database()
        
        # Check if radiologist exists
        if not db.radiologists.find_one({'_id': ObjectId(radiologist_id)}):
            return jsonify({'error': 'Radiologist not found'}), 404

        # Prepare update data
        update_data = {
            'updated_at': datetime.now().isoformat()
        }
        for field in ['name', 'email', 'specialization', 'status', 'hospital']:
            if field in data:
                update_data[field] = data[field]

        # Perform update
        db.radiologists.update_one(
            {'_id': ObjectId(radiologist_id)},
            {'$set': update_data}
        )

        # Get updated radiologist
        radiologist = db.radiologists.find_one({'_id': ObjectId(radiologist_id)})
        radiologist['_id'] = str(radiologist['_id'])
        
        return jsonify(radiologist)
    except Exception as e:
        logger.error(f"Error updating radiologist: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/radiologists/<radiologist_id>', methods=['DELETE'])
@handle_errors
def delete_radiologist(radiologist_id):
    """Delete a radiologist"""
    if not mongodb_client:
        return jsonify({'error': 'Database connection not available'}), 503

    try:
        db = mongodb_client.get_database()
        
        # Check if radiologist exists
        if not db.radiologists.find_one({'_id': ObjectId(radiologist_id)}):
            return jsonify({'error': 'Radiologist not found'}), 404

        # Delete the radiologist
        db.radiologists.delete_one({'_id': ObjectId(radiologist_id)})
        
        return '', 204
    except Exception as e:
        logger.error(f"Error deleting radiologist: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/radiologists/specializations', methods=['GET'])
@handle_errors
def get_specializations():
    """Get list of unique radiologist specializations"""
    if not mongodb_client:
        return jsonify({'error': 'Database connection not available'}), 503

    try:
        db = mongodb_client.get_database()
        specializations = db.radiologists.distinct('specialization')
        return jsonify({'specializations': specializations})
    except Exception as e:
        logger.error(f"Error getting specializations: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/radiologists/hospitals', methods=['GET'])
@handle_errors
def get_hospitals():
    """Get list of unique hospitals"""
    if not mongodb_client:
        return jsonify({'error': 'Database connection not available'}), 503

    try:
        db = mongodb_client.get_database()
        hospitals = db.radiologists.distinct('hospital')
        # Filter out None values
        hospitals = [h for h in hospitals if h]
        return jsonify({'hospitals': hospitals})
    except Exception as e:
        logger.error(f"Error getting hospitals: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Register with Consul
    register_with_consul()
    
    # Start the Flask application
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('SERVER_PORT', 8084)),
        threaded=True
    )
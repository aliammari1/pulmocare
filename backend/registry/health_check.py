from flask import Flask, jsonify
from functools import wraps
from pymongo import MongoClient
import redis
import logging
import os
import time
from datetime import datetime

logger = logging.getLogger(__name__)

def health_check_middleware(config):
    """
    Middleware factory that adds a standardized health check endpoint to Flask apps.
    This ensures consistent health reporting across all services.
    """
    def middleware(app: Flask):
        @app.route('/health', methods=['GET'])
        def health_check():
            """Standardized health check endpoint for all services"""
            try:
                service_name = config.SERVICE_NAME
                checks = {}
                
                # Check MongoDB if configured
                if hasattr(app, 'mongo_client'):
                    try:
                        app.mongo_client.admin.command('ping')
                        checks['mongodb'] = 'UP'
                    except Exception as e:
                        checks['mongodb'] = f'DOWN: {str(e)}'
                
                # Check Redis if configured
                if hasattr(app, 'redis_client'):
                    try:
                        app.redis_client.ping()
                        checks['redis'] = 'UP'
                    except Exception as e:
                        checks['redis'] = f'DOWN: {str(e)}'
                
                # Check RabbitMQ if configured
                if hasattr(app, 'rabbitmq_client'):
                    try:
                        app.rabbitmq_client.check_connection()
                        checks['rabbitmq'] = 'UP'
                    except Exception as e:
                        checks['rabbitmq'] = f'DOWN: {str(e)}'

                # Determine overall status
                status = 'UP' if all(v == 'UP' for v in checks.values()) else 'DEGRADED'
                
                response = {
                    'status': status,
                    'service': service_name,
                    'version': os.getenv('SERVICE_VERSION', '1.0'),
                    'timestamp': datetime.utcnow().isoformat(),
                    'checks': checks
                }
                
                # Return 200 even if degraded to prevent container restart loops
                return jsonify(response), 200
            except Exception as e:
                logger.error(f"Health check failed: {str(e)}")
                return jsonify({
                    'status': 'DOWN',
                    'service': config.SERVICE_NAME,
                    'error': str(e),
                    'timestamp': datetime.utcnow().isoformat()
                }), 503
        
        return app
    return middleware
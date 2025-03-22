import logging
import json
from datetime import datetime
import pika
import time

class RabbitMQClient:
    """RabbitMQ client for ordonnances service"""
    
    def __init__(self, config):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.connection = None
        self.channel = None
        self._setup_connection()
        
    def _setup_connection(self):
        """Initialize RabbitMQ connection and channel"""
        try:
            credentials = pika.PlainCredentials(
                self.config.RABBITMQ_USER,
                self.config.RABBITMQ_PASS
            )
            
            parameters = pika.ConnectionParameters(
                host=self.config.RABBITMQ_HOST,
                port=self.config.RABBITMQ_PORT,
                virtual_host=self.config.RABBITMQ_VHOST,
                credentials=credentials,
                heartbeat=600
            )
            
            self.connection = pika.BlockingConnection(parameters)
            self.channel = self.connection.channel()
            
            # Declare exchanges
            self.channel.exchange_declare(
                exchange='medical.prescriptions',
                exchange_type='topic',
                durable=True
            )
            
            # Declare queues
            self.channel.queue_declare(
                queue='prescription.notifications',
                durable=True
            )
            
            self.channel.queue_declare(
                queue='prescription.validations',
                durable=True
            )
            
            # Bind queues to exchanges
            self.channel.queue_bind(
                exchange='medical.prescriptions',
                queue='prescription.notifications',
                routing_key='prescription.#'
            )
            
            self.channel.queue_bind(
                exchange='medical.prescriptions',
                queue='prescription.validations',
                routing_key='prescription.validate'
            )
            
            self.logger.info("Successfully connected to RabbitMQ")
            
        except Exception as e:
            self.logger.error(f"Failed to connect to RabbitMQ: {str(e)}")
            raise
    
    def publish_message(self, exchange, routing_key, message, correlation_id=None):
        """Publish a message to RabbitMQ"""
        try:
            if not self.connection or self.connection.is_closed:
                self._setup_connection()
            
            if isinstance(message, dict):
                message = json.dumps(message)
            
            properties = pika.BasicProperties(
                delivery_mode=2,  # make message persistent
                content_type='application/json',
                correlation_id=correlation_id,
                timestamp=int(time.time())
            )
            
            self.channel.basic_publish(
                exchange=exchange,
                routing_key=routing_key,
                body=message,
                properties=properties
            )
            
            self.logger.debug(f"Published message to {exchange}:{routing_key}")
            
        except Exception as e:
            self.logger.error(f"Failed to publish message: {str(e)}")
            raise
    
    def publish_prescription_created(self, prescription_id, prescription_data):
        """Publish prescription creation event"""
        message = {
            'event': 'prescription_created',
            'prescription_id': str(prescription_id),
            'prescription_data': prescription_data,
            'timestamp': datetime.utcnow().isoformat()
        }
        self.publish_message(
            'medical.prescriptions',
            'prescription.created',
            message
        )
    
    def publish_prescription_updated(self, prescription_id, prescription_data):
        """Publish prescription update event"""
        message = {
            'event': 'prescription_updated',
            'prescription_id': str(prescription_id),
            'prescription_data': prescription_data,
            'timestamp': datetime.utcnow().isoformat()
        }
        self.publish_message(
            'medical.prescriptions',
            'prescription.updated',
            message
        )
    
    def publish_prescription_validation_request(self, prescription_id, doctor_id):
        """Publish prescription validation request"""
        message = {
            'event': 'prescription_validation_requested',
            'prescription_id': str(prescription_id),
            'doctor_id': str(doctor_id),
            'timestamp': datetime.utcnow().isoformat()
        }
        self.publish_message(
            'medical.prescriptions',
            'prescription.validate',
            message
        )
    
    def consume_validation_requests(self, callback):
        """Setup consumer for validation requests"""
        try:
            if not self.connection or self.connection.is_closed:
                self._setup_connection()
            
            self.channel.basic_qos(prefetch_count=1)
            self.channel.basic_consume(
                queue='prescription.validations',
                on_message_callback=callback
            )
            
            self.logger.info("Started consuming validation requests")
            self.channel.start_consuming()
            
        except Exception as e:
            self.logger.error(f"Failed to setup consumer: {str(e)}")
            raise
    
    def close(self):
        """Close RabbitMQ connection"""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
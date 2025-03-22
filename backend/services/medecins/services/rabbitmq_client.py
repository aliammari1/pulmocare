import logging
import json
from datetime import datetime
import pika
import time

class RabbitMQClient:
    """RabbitMQ client for medecins service"""
    
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
                exchange='medical.events',
                exchange_type='topic',
                durable=True
            )
            
            self.channel.exchange_declare(
                exchange='medical.appointments',
                exchange_type='topic',
                durable=True
            )
            
            # Declare queues
            self.channel.queue_declare(
                queue='doctor.notifications',
                durable=True
            )
            
            self.channel.queue_declare(
                queue='appointment.requests',
                durable=True
            )
            
            # Bind queues to exchanges
            self.channel.queue_bind(
                exchange='medical.events',
                queue='doctor.notifications',
                routing_key='doctor.#'
            )
            
            self.channel.queue_bind(
                exchange='medical.appointments',
                queue='appointment.requests',
                routing_key='appointment.requested'
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
    
    def publish_doctor_availability_changed(self, doctor_id, availability):
        """Publish doctor availability change event"""
        message = {
            'event': 'doctor_availability_changed',
            'doctor_id': str(doctor_id),
            'availability': availability,
            'timestamp': datetime.utcnow().isoformat()
        }
        self.publish_message(
            'medical.events',
            'doctor.availability',
            message
        )
    
    def publish_appointment_response(self, appointment_id, doctor_id, status):
        """Publish appointment response event"""
        message = {
            'event': 'appointment_response',
            'appointment_id': str(appointment_id),
            'doctor_id': str(doctor_id),
            'status': status,
            'timestamp': datetime.utcnow().isoformat()
        }
        self.publish_message(
            'medical.appointments',
            'appointment.response',
            message
        )
    
    def consume_appointment_requests(self, callback):
        """Setup consumer for appointment requests"""
        try:
            if not self.connection or self.connection.is_closed:
                self._setup_connection()
            
            self.channel.basic_qos(prefetch_count=1)
            self.channel.basic_consume(
                queue='appointment.requests',
                on_message_callback=callback
            )
            
            self.logger.info("Started consuming appointment requests")
            self.channel.start_consuming()
            
        except Exception as e:
            self.logger.error(f"Failed to setup consumer: {str(e)}")
            raise
    
    def close(self):
        """Close RabbitMQ connection"""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
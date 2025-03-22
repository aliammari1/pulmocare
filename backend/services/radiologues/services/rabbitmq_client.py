import logging
import json
from datetime import datetime
import pika
import time

class RabbitMQClient:
    """RabbitMQ client for radiologues service"""
    
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
                exchange='medical.reports',
                exchange_type='topic',
                durable=True
            )
            
            self.channel.exchange_declare(
                exchange='medical.analysis',
                exchange_type='topic',
                durable=True
            )
            
            # Declare queues
            self.channel.queue_declare(
                queue='radiology.reports',
                durable=True
            )
            
            self.channel.queue_declare(
                queue='radiology.analysis',
                durable=True
            )
            
            # Bind queues to exchanges
            self.channel.queue_bind(
                exchange='medical.reports',
                queue='radiology.reports',
                routing_key='report.radiology.#'
            )
            
            self.channel.queue_bind(
                exchange='medical.analysis',
                queue='radiology.analysis',
                routing_key='analysis.request.#'
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
    
    def publish_radiology_report(self, report_id, report_data):
        """Publish new radiology report event"""
        message = {
            'event': 'radiology_report_created',
            'report_id': str(report_id),
            'report_data': report_data,
            'timestamp': datetime.utcnow().isoformat()
        }
        self.publish_message(
            'medical.reports',
            'report.radiology.created',
            message
        )
    
    def publish_analysis_result(self, report_id, analysis_data):
        """Publish radiology analysis result"""
        message = {
            'event': 'analysis_completed',
            'report_id': str(report_id),
            'analysis': analysis_data,
            'timestamp': datetime.utcnow().isoformat()
        }
        self.publish_message(
            'medical.analysis',
            'analysis.result',
            message
        )
    
    def consume_analysis_requests(self, callback):
        """Setup consumer for analysis requests"""
        try:
            if not self.connection or self.connection.is_closed:
                self._setup_connection()
            
            self.channel.basic_qos(prefetch_count=1)
            self.channel.basic_consume(
                queue='radiology.analysis',
                on_message_callback=callback
            )
            
            self.logger.info("Started consuming analysis requests")
            self.channel.start_consuming()
            
        except Exception as e:
            self.logger.error(f"Failed to setup consumer: {str(e)}")
            raise
    
    def close(self):
        """Close RabbitMQ connection"""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
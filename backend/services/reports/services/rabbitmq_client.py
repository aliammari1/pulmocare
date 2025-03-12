import logging
import json
from datetime import datetime
import pika

class RabbitMQClient:
    """RabbitMQ client service for message queue operations"""
    
    def __init__(self, config):
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.connection = None
        self.channel = None
        self.init_connection()
    
    def init_connection(self):
        """Initialize RabbitMQ connection and channel"""
        try:
            credentials = pika.PlainCredentials(
                self.config.RABBITMQ_USER, 
                self.config.RABBITMQ_PASS
            )
            self.connection = pika.BlockingConnection(
                pika.ConnectionParameters(
                    host=self.config.RABBITMQ_HOST,
                    port=self.config.RABBITMQ_PORT,
                    virtual_host=self.config.RABBITMQ_VHOST,
                    credentials=credentials
                )
            )
            self.channel = self.connection.channel()
            
            # Declare exchanges
            self.channel.exchange_declare(
                exchange='medical.reports',
                exchange_type='topic',
                durable=True
            )
            
            # Declare queues
            self.channel.queue_declare(queue='report.analysis', durable=True)
            self.channel.queue_declare(queue='report.notifications', durable=True)
            
            # Bind queues to exchange
            self.channel.queue_bind(
                exchange='medical.reports',
                queue='report.analysis',
                routing_key='report.created'
            )
            self.channel.queue_bind(
                exchange='medical.reports',
                queue='report.notifications',
                routing_key='report.#'
            )
            
            self.logger.info("Connected to RabbitMQ successfully")
        except Exception as e:
            self.logger.error(f"Failed to connect to RabbitMQ: {str(e)}")
    
    def publish_event(self, routing_key, data):
        """Publish event to RabbitMQ"""
        try:
            if self.channel and self.channel.is_open:
                self.channel.basic_publish(
                    exchange='medical.reports',
                    routing_key=routing_key,
                    body=json.dumps(data),
                    properties=pika.BasicProperties(
                        delivery_mode=2,  # make message persistent
                        content_type='application/json'
                    )
                )
                self.logger.info(f"Published event {routing_key}")
                return True
            else:
                self.logger.error("RabbitMQ channel not available")
                return False
        except Exception as e:
            self.logger.error(f"Failed to publish event: {str(e)}")
            return False
    
    def publish_report_created(self, report_id):
        """Publish report.created event"""
        return self.publish_event('report.created', {
            'report_id': report_id,
            'timestamp': datetime.utcnow().isoformat()
        })
    
    def publish_report_updated(self, report_id):
        """Publish report.updated event"""
        return self.publish_event('report.updated', {
            'report_id': report_id,
            'timestamp': datetime.utcnow().isoformat()
        })
    
    def publish_report_deleted(self, report_id):
        """Publish report.deleted event"""
        return self.publish_event('report.deleted', {
            'report_id': report_id,
            'timestamp': datetime.utcnow().isoformat()
        })
    
    def close(self):
        """Close RabbitMQ connection"""
        try:
            if self.connection and not self.connection.is_closed:
                self.connection.close()
                self.logger.info("Closed RabbitMQ connection")
        except Exception as e:
            self.logger.error(f"Error closing RabbitMQ connection: {str(e)}")
    
    def check_health(self):
        """Check RabbitMQ health"""
        try:
            status = 'UP' if self.connection and self.connection.is_open else 'DOWN'
            return status
        except Exception as e:
            return f'DOWN: {str(e)}'

import pika
import logging
import time
import json
from circuit_breaker import CircuitBreaker
from config import Config
from typing import Optional, Tuple
from metrics import track_rabbitmq_metrics, update_queue_metrics

logger = logging.getLogger(__name__)

class MessageBroker:
    """Message broker with circuit breaker for RabbitMQ operations"""
    
    def __init__(self):
        self._connection: Optional[pika.BlockingConnection] = None
        self._channel: Optional[pika.channel.Channel] = None
        self.circuit = CircuitBreaker(
            name="rabbitmq",
            failure_threshold=Config.CIRCUIT_BREAKER_FAILURE_THRESHOLD,
            recovery_timeout=Config.CIRCUIT_BREAKER_RECOVERY_TIMEOUT,
            expected_exception=pika.exceptions.AMQPError
        )
    
    @property
    def connection(self) -> pika.BlockingConnection:
        """Get or create RabbitMQ connection"""
        if not self._connection or self._connection.is_closed:
            self._connection = self._create_connection()
        return self._connection
    
    @property
    def channel(self) -> pika.channel.Channel:
        """Get or create RabbitMQ channel"""
        if not self._channel or self._channel.is_closed:
            self._channel = self.connection.channel()
            self._declare_infrastructure()
        return self._channel
    
    @CircuitBreaker(name="rabbitmq_connection")
    def _create_connection(self) -> pika.BlockingConnection:
        """Create new RabbitMQ connection with retry logic"""
        max_retries = 5
        retry_delay = 1
        
        for attempt in range(max_retries):
            try:
                credentials = pika.PlainCredentials(
                    Config.RABBITMQ_USER,
                    Config.RABBITMQ_PASS
                )
                
                connection = pika.BlockingConnection(
                    pika.ConnectionParameters(
                        host=Config.RABBITMQ_HOST,
                        port=Config.RABBITMQ_PORT,
                        virtual_host=Config.RABBITMQ_VHOST,
                        credentials=credentials,
                        heartbeat=600,
                        connection_attempts=3
                    )
                )
                logger.info("Successfully connected to RabbitMQ")
                return connection
                
            except pika.exceptions.AMQPError as e:
                if attempt == max_retries - 1:
                    logger.error(f"Failed to connect to RabbitMQ after {max_retries} attempts")
                    raise
                    
                logger.warning(f"RabbitMQ connection attempt {attempt + 1} failed: {str(e)}")
                time.sleep(retry_delay)
                retry_delay *= 2
    
    def _declare_infrastructure(self):
        """Declare exchanges, queues and bindings"""
        # Declare exchanges
        self.channel.exchange_declare(
            exchange='medical.reports',
            exchange_type='topic',
            durable=True
        )
        
        # Declare queues
        self.channel.queue_declare(
            queue='report.analysis',
            durable=True
        )
        self.channel.queue_declare(
            queue='report.notifications',
            durable=True
        )
        
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
        
        # Initialize queue metrics
        update_queue_metrics(self.channel, 'report.analysis')
        update_queue_metrics(self.channel, 'report.notifications')
    
    @track_rabbitmq_metrics
    def publish(self, routing_key: str, message: dict, **properties):
        """Publish message with circuit breaker and metrics"""
        try:
            self.channel.basic_publish(
                exchange='medical.reports',
                routing_key=routing_key,
                body=json.dumps(message),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # make message persistent
                    content_type='application/json',
                    **properties
                )
            )
            logger.info(f"Published message with routing key: {routing_key}")
            
            # Update queue metrics after publish
            if routing_key.startswith('report.created'):
                update_queue_metrics(self.channel, 'report.analysis')
            update_queue_metrics(self.channel, 'report.notifications')
            
        except pika.exceptions.AMQPError as e:
            logger.error(f"Failed to publish message: {str(e)}")
            raise
    
    def close(self):
        """Close RabbitMQ connection"""
        try:
            if self._connection and not self._connection.is_closed:
                self._connection.close()
                logger.info("Closed RabbitMQ connection")
        except Exception as e:
            logger.error(f"Error closing RabbitMQ connection: {str(e)}")
            
    def __enter__(self):
        """Context manager entry"""
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.close()
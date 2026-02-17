"""
RabbitMQ client for message queue operations.
"""

import json
import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING, Any, Callable

import pika
from pika.adapters.blocking_connection import BlockingChannel
from pika.exchange_type import ExchangeType

if TYPE_CHECKING:
    from pulmocare_shared.config import BaseConfig


class RabbitMQClient:
    """RabbitMQ client for inter-service messaging."""

    _instance: "RabbitMQClient | None" = None

    def __new__(cls, config: "BaseConfig | None" = None, service_name: str | None = None) -> "RabbitMQClient":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self, config: "BaseConfig | None" = None, service_name: str | None = None) -> None:
        if self._initialized:
            return

        if config is None:
            from pulmocare_shared.config import get_config
            config = get_config()

        self.config = config
        self.host = config.rabbitmq_host
        self.port = config.rabbitmq_port
        self.username = config.rabbitmq_user
        self.password = config.rabbitmq_pass
        self.virtual_host = config.rabbitmq_vhost
        self.connection: pika.BlockingConnection | None = None
        self.channel: BlockingChannel | None = None
        self.service_name = service_name or config.service_name

        # Define exchange names for different domains
        self.exchanges = {
            "medical": "medical.exchange",
            "appointments": "medical.appointments",
            "notifications": "notifications.exchange",
            "patient": "patient.events",
            "events": "pulmocare.events",
        }
        
        self._initialized = True

    def connect(self) -> BlockingChannel:
        """Create a connection to RabbitMQ and return a channel."""
        try:
            credentials = pika.PlainCredentials(self.username, self.password)
            parameters = pika.ConnectionParameters(
                host=self.host,
                port=self.port,
                virtual_host=self.virtual_host,
                credentials=credentials,
                heartbeat=600,
                blocked_connection_timeout=300,
            )

            self.connection = pika.BlockingConnection(parameters)
            self.channel = self.connection.channel()
            self._declare_exchanges()

            print(f"Connected to RabbitMQ at {self.host}:{self.port}")
            return self.channel

        except Exception as e:
            print(f"Failed to connect to RabbitMQ: {e}")
            raise

    def disconnect(self) -> None:
        """Close the RabbitMQ connection."""
        if self.connection and self.connection.is_open:
            self.connection.close()
            self.connection = None
            self.channel = None
            print("Disconnected from RabbitMQ")

    def _declare_exchanges(self) -> None:
        """Declare the exchanges we'll use for messaging."""
        if not self.channel:
            return

        for name, exchange in self.exchanges.items():
            self.channel.exchange_declare(
                exchange=exchange,
                exchange_type=ExchangeType.topic,
                durable=True,
                auto_delete=False,
            )

    def _get_channel(self) -> BlockingChannel:
        """Get an active channel, creating a connection if needed."""
        if not self.channel or not self.connection or self.connection.is_closed:
            return self.connect()
        return self.channel

    def publish_message(
        self,
        exchange: str,
        routing_key: str,
        message: dict[str, Any],
        correlation_id: str | None = None,
    ) -> bool:
        """
        Publish a message to RabbitMQ.

        Args:
            exchange: Exchange name to publish to
            routing_key: Routing key for message
            message: Message dictionary to publish
            correlation_id: Optional correlation ID for message tracking

        Returns:
            bool: True if successful, False otherwise
        """
        try:
            channel = self._get_channel()

            # Add metadata to message
            message_with_metadata = {
                **message,
                "_metadata": {
                    "source_service": self.service_name,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "message_id": str(uuid.uuid4()),
                    "correlation_id": correlation_id or str(uuid.uuid4()),
                },
            }

            message_json = json.dumps(message_with_metadata)

            channel.basic_publish(
                exchange=exchange,
                routing_key=routing_key,
                body=message_json,
                properties=pika.BasicProperties(
                    content_type="application/json",
                    delivery_mode=2,  # Persistent
                    correlation_id=correlation_id,
                ),
            )

            print(f"Published message to exchange={exchange}, routing_key={routing_key}")
            return True

        except Exception as e:
            print(f"Failed to publish message: {e}")
            try:
                self.connect()
                return self._retry_publish(exchange, routing_key, message, correlation_id)
            except Exception:
                return False

    def _retry_publish(
        self,
        exchange: str,
        routing_key: str,
        message: dict[str, Any],
        correlation_id: str | None,
    ) -> bool:
        """Retry publishing a message after reconnection."""
        try:
            channel = self._get_channel()
            message_json = json.dumps(message)

            channel.basic_publish(
                exchange=exchange,
                routing_key=routing_key,
                body=message_json,
                properties=pika.BasicProperties(
                    content_type="application/json",
                    delivery_mode=2,
                    correlation_id=correlation_id,
                ),
            )
            return True
        except Exception:
            return False

    def subscribe(
        self,
        queue_name: str,
        exchange: str,
        routing_key: str,
        callback: Callable[[dict[str, Any]], None],
        auto_ack: bool = False,
    ) -> None:
        """
        Subscribe to messages from a queue.

        Args:
            queue_name: Name of the queue to subscribe to
            exchange: Exchange name
            routing_key: Routing key pattern
            callback: Callback function to process messages
            auto_ack: Whether to auto-acknowledge messages
        """
        channel = self._get_channel()

        # Declare queue
        channel.queue_declare(queue=queue_name, durable=True)
        channel.queue_bind(queue=queue_name, exchange=exchange, routing_key=routing_key)

        def on_message(ch, method, properties, body):
            try:
                message = json.loads(body)
                callback(message)
                if not auto_ack:
                    ch.basic_ack(delivery_tag=method.delivery_tag)
            except Exception as e:
                print(f"Error processing message: {e}")
                if not auto_ack:
                    ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

        channel.basic_qos(prefetch_count=1)
        channel.basic_consume(queue=queue_name, on_message_callback=on_message, auto_ack=auto_ack)

        print(f"Subscribed to queue: {queue_name}")

    def start_consuming(self) -> None:
        """Start consuming messages."""
        if self.channel:
            print("Starting to consume messages...")
            self.channel.start_consuming()

    def stop_consuming(self) -> None:
        """Stop consuming messages."""
        if self.channel:
            self.channel.stop_consuming()

    # Convenience methods for common event types
    def publish_event(self, event_type: str, data: dict[str, Any]) -> bool:
        """Publish a domain event."""
        return self.publish_message(
            exchange=self.exchanges["events"],
            routing_key=f"{self.service_name}.{event_type}",
            message={"event_type": event_type, "data": data},
        )

    def publish_notification(self, notification_type: str, data: dict[str, Any]) -> bool:
        """Publish a notification event."""
        return self.publish_message(
            exchange=self.exchanges["notifications"],
            routing_key=f"notification.{notification_type}",
            message={"notification_type": notification_type, "data": data},
        )

    def check_health(self) -> str:
        """Check RabbitMQ connection health."""
        try:
            self._get_channel()
            return "UP"
        except Exception as e:
            return f"DOWN: {e}"


def get_rabbitmq_client(config: "BaseConfig | None" = None, service_name: str | None = None) -> RabbitMQClient:
    """Get RabbitMQ client instance."""
    return RabbitMQClient(config, service_name)

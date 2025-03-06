import 'dart:async';
import 'package:logging/logging.dart';
import 'package:dart_amqp/dart_amqp.dart';
import '../config/environment.dart';

class RabbitMQService {
  static final _logger = Logger('RabbitMQService');
  Client? _client;
  Channel? _channel;
  final Map<String, Consumer> _consumers = {};

  Future<void> initialize() async {
    try {
      final settings = ConnectionSettings(
        host: EnvironmentConfig.rabbitmqHost,
        port: EnvironmentConfig.rabbitmqPort,
        virtualHost: '/',
      );

      _client = Client(settings: settings);
      _channel = await _client!.channel();
      _logger.info('RabbitMQ service initialized');
    } catch (e) {
      _logger.severe('Failed to initialize RabbitMQ service: $e');
      rethrow;
    }
  }

  Future<void> publish(
      String exchange, String routingKey, dynamic message) async {
    try {
      final exchangeObj =
          await _channel!.exchange(exchange, ExchangeType.TOPIC);
      exchangeObj.publish(
          message, routingKey); // Remove await since publish returns void
      _logger.fine('Published message to $exchange:$routingKey');
    } catch (e) {
      _logger.warning('Failed to publish message: $e');
      rethrow;
    }
  }

  Future<Consumer> subscribe(
    String exchange,
    String routingKey,
    void Function(AmqpMessage) onMessage,
  ) async {
    try {
      final exchangeObj =
          await _channel!.exchange(exchange, ExchangeType.TOPIC);
      final queue = await _channel!.queue('');
      await queue.bind(exchangeObj, routingKey);

      final consumer = await queue.consume();
      consumer.listen(onMessage);

      final key = '$exchange:$routingKey';
      _consumers[key] = consumer;
      _logger.fine('Subscribed to $key');

      return consumer;
    } catch (e) {
      _logger.warning('Failed to subscribe: $e');
      rethrow;
    }
  }

  Future<void> unsubscribe(String exchange, String routingKey) async {
    final key = '$exchange:$routingKey';
    final consumer = _consumers[key];
    if (consumer != null) {
      await consumer.cancel();
      _consumers.remove(key);
      _logger.fine('Unsubscribed from $key');
    }
  }

  Future<void> dispose() async {
    // Cancel all consumers
    for (final consumer in _consumers.values) {
      await consumer.cancel();
    }
    _consumers.clear();

    // Close channel and client
    await _channel?.close();
    await _client?.close();
    _logger.info('RabbitMQ service disposed');
  }
}

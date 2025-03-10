from prometheus_client import Counter, Histogram, Gauge
import functools
import time

# RabbitMQ metrics
RABBITMQ_MESSAGES_PUBLISHED = Counter(
    'rabbitmq_messages_published_total',
    'Total number of messages published',
    ['exchange', 'routing_key']
)

RABBITMQ_PUBLISH_LATENCY = Histogram(
    'rabbitmq_publish_latency_seconds',
    'Message publish latency in seconds',
    ['exchange', 'routing_key']
)

RABBITMQ_CONSUME_LATENCY = Histogram(
    'rabbitmq_consume_latency_seconds',
    'Message consume latency in seconds',
    ['queue']
)

RABBITMQ_QUEUE_SIZE = Gauge(
    'rabbitmq_queue_size',
    'Number of messages in queue',
    ['queue']
)

RABBITMQ_CONSUMER_COUNT = Gauge(
    'rabbitmq_consumers',
    'Number of consumers',
    ['queue']
)

# Circuit breaker metrics
CIRCUIT_BREAKER_STATE = Gauge(
    'circuit_breaker_state',
    'Circuit breaker state (0=closed, 1=open, 2=half-open)',
    ['name']
)

CIRCUIT_BREAKER_FAILURES = Counter(
    'circuit_breaker_failures_total',
    'Number of circuit breaker failures',
    ['name']
)

# Cache metrics
CACHE_HITS = Counter(
    'cache_hits_total',
    'Number of cache hits',
    ['cache']
)

CACHE_MISSES = Counter(
    'cache_misses_total',
    'Number of cache misses',
    ['cache']
)

def track_rabbitmq_metrics(func):
    """Decorator to track RabbitMQ operation metrics"""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        # Get exchange and routing key from args/kwargs based on the function
        exchange = kwargs.get('exchange', 'default')
        routing_key = kwargs.get('routing_key', 'default')
        queue = kwargs.get('queue', 'default')
        
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            
            # Record metrics based on operation type
            if func.__name__ == 'publish':
                RABBITMQ_MESSAGES_PUBLISHED.labels(
                    exchange=exchange,
                    routing_key=routing_key
                ).inc()
                RABBITMQ_PUBLISH_LATENCY.labels(
                    exchange=exchange,
                    routing_key=routing_key
                ).observe(time.time() - start_time)
            elif func.__name__ == 'basic_consume':
                RABBITMQ_CONSUME_LATENCY.labels(
                    queue=queue
                ).observe(time.time() - start_time)
            
            return result
        except Exception:
            raise
            
    return wrapper

def update_queue_metrics(channel, queue_name):
    """Update queue-related metrics"""
    try:
        # Get queue statistics
        queue = channel.queue_declare(queue=queue_name, passive=True)
        message_count = queue.method.message_count
        consumer_count = queue.method.consumer_count
        
        # Update Prometheus metrics
        RABBITMQ_QUEUE_SIZE.labels(queue=queue_name).set(message_count)
        RABBITMQ_CONSUMER_COUNT.labels(queue=queue_name).set(consumer_count)
    except Exception as e:
        # Log but don't fail if we can't get metrics
        print(f"Error updating queue metrics: {str(e)}")

def track_circuit_breaker_state(name: str, state: str):
    """Update circuit breaker state metric"""
    state_values = {
        'closed': 0,
        'open': 1,
        'half_open': 2
    }
    CIRCUIT_BREAKER_STATE.labels(name=name).set(state_values.get(state, 0))

def track_circuit_breaker_failure(name: str):
    """Increment circuit breaker failure counter"""
    CIRCUIT_BREAKER_FAILURES.labels(name=name).inc()

def track_cache_metrics(hit: bool, cache_name: str):
    """Track cache hit/miss metrics"""
    if hit:
        CACHE_HITS.labels(cache=cache_name).inc()
    else:
        CACHE_MISSES.labels(cache=cache_name).inc()
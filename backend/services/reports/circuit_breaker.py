import time
import logging
import functools
from enum import Enum
from metrics import track_circuit_breaker_state, track_circuit_breaker_failure

logger = logging.getLogger(__name__)

class CircuitState(Enum):
    CLOSED = 'closed'  # Normal operation
    OPEN = 'open'      # Service calls blocked
    HALF_OPEN = 'half_open'  # Testing if service is restored

class CircuitBreaker:
    """Circuit breaker implementation for handling external service failures"""
    
    def __init__(self, name, failure_threshold=5, recovery_timeout=60, expected_exception=Exception):
        self.name = name
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        self._state = CircuitState.CLOSED
        self.failure_count = 0
        self.last_failure_time = None
        
        # Initialize metrics with closed state
        track_circuit_breaker_state(self.name, self._state.value)
        
    @property
    def state(self):
        return self._state
        
    @state.setter
    def state(self, new_state):
        self._state = new_state
        track_circuit_breaker_state(self.name, new_state.value)
        
    def can_execute(self):
        """Check if the protected function can be executed"""
        if self.state == CircuitState.CLOSED:
            return True
            
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time >= self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
                logger.info(f"Circuit breaker {self.name} entering half-open state")
                return True
            return False
            
        return True  # HALF_OPEN
        
    def record_success(self):
        """Record a successful execution"""
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.last_failure_time = None
        logger.debug(f"Circuit breaker {self.name} recorded success")
        
    def record_failure(self):
        """Record a failed execution"""
        self.failure_count += 1
        self.last_failure_time = time.time()
        track_circuit_breaker_failure(self.name)
        
        if self.state == CircuitState.HALF_OPEN or self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
            logger.warning(f"Circuit breaker {self.name} opened due to failures")
            
    def __call__(self, func):
        """Decorator implementation"""
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            if not self.can_execute():
                msg = f"Circuit breaker {self.name} is {self.state.value}, requests blocked"
                logger.warning(msg)
                raise RuntimeError(msg)
                
            try:
                result = func(*args, **kwargs)
                self.record_success()
                return result
            except self.expected_exception as e:
                self.record_failure()
                raise
                
        return wrapper
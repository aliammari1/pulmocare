import consul
import logging
import socket
import os
import uuid
import sys

# Add parent directory to path to import base service
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from base_consul_service import BaseConsulService

logger = logging.getLogger(__name__)

class ConsulService(BaseConsulService):
    """Ordonnances service Consul integration"""
    pass  # Inherits all functionality from BaseConsulService
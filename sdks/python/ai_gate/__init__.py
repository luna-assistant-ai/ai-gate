"""
AI Gate SDK for Python

Official Python SDK for AI Gate - Secure proxy for OpenAI Realtime API with WebRTC support.

Example:
    >>> from ai_gate import AIGateClient
    >>> client = AIGateClient(project_id="your-project-id")
    >>> session = client.create_session(voice="echo")
    >>> print(session.id)
"""

from ai_gate.client import AIGateClient, AIGateError
from ai_gate.types import (
    SessionConfig,
    SessionResponse,
    TurnCredentials,
    UsageResponse,
)

__version__ = "1.0.0"
__all__ = [
    "AIGateClient",
    "AIGateError",
    "SessionConfig",
    "SessionResponse",
    "TurnCredentials",
    "UsageResponse",
]

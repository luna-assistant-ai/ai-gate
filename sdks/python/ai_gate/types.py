"""Type definitions for AI Gate SDK"""

from typing import Any, Dict, List, Literal, Optional, TypedDict, Union
from typing_extensions import NotRequired


class IceServer(TypedDict):
    """ICE server configuration for WebRTC"""

    urls: Union[str, List[str]]
    username: NotRequired[str]
    credential: NotRequired[str]


class TurnCredentials(TypedDict):
    """TURN server credentials for WebRTC"""

    iceServers: List[IceServer]
    _auth_method: NotRequired[str]
    _turn_enabled: NotRequired[bool]


class ClientSecret(TypedDict):
    """Client secret for WebRTC connection"""

    value: str
    expires_at: int


class SessionMetadata(TypedDict):
    """Session metadata"""

    model: str
    voice: str
    turn_server: str
    created_at: str


class SessionResponse(TypedDict):
    """OpenAI Realtime session response"""

    id: str
    model: str
    expires_at: int
    turn_credentials: TurnCredentials
    session_id: str
    metadata: SessionMetadata
    client_secret: NotRequired[ClientSecret]


class SessionConfig(TypedDict, total=False):
    """Configuration for creating a session"""

    model: str
    voice: Literal["alloy", "echo", "fable", "onyx", "nova", "shimmer"]
    temperature: float
    instructions: str


class UsageResponse(TypedDict):
    """Usage and quota information"""

    plan: Literal["free", "starter", "growth"]
    sessionsIncluded: int
    sessionsUsed: int
    sessionsRemaining: int
    estimatedMinutes: int
    minutesUsed: int
    percentUsed: float


class QuotaExceededError(TypedDict):
    """Quota exceeded error response"""

    error: Literal["quota_exceeded"]
    message: str
    usage: UsageResponse
    upgrade_url: str


class RateLimitError(TypedDict):
    """Rate limit error response"""

    error: Literal["Rate limit exceeded"]
    message: str
    limit: int
    window: str
    resetAt: str


class ConcurrentLimitError(TypedDict):
    """Concurrent limit error response"""

    error: Literal["concurrent_limit_exceeded"]
    message: str
    current: int
    max: int
    hint: str


class APIError(TypedDict):
    """Generic API error response"""

    error: str
    message: str


ErrorResponse = Union[APIError, QuotaExceededError, RateLimitError, ConcurrentLimitError]

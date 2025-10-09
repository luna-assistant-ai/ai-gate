"""AI Gate SDK Client"""

import httpx
from typing import Optional

from ai_gate.types import (
    SessionConfig,
    SessionResponse,
    TurnCredentials,
    ErrorResponse,
)


class AIGateError(Exception):
    """Exception raised for AI Gate API errors"""

    def __init__(
        self,
        message: str,
        status_code: Optional[int] = None,
        response: Optional[ErrorResponse] = None,
    ) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.response = response


class AIGateClient:
    """
    AI Gate SDK Client

    Use your project ID from the AI Gate dashboard to authenticate.
    The OpenAI API key is securely stored in the vault and never exposed to the client.

    Args:
        project_id: Your project ID from the dashboard
        base_url: API base URL (default: https://api.ai-gate.dev)
        timeout: Request timeout in seconds (default: 30)
        debug: Enable debug logging (default: False)

    Example:
        >>> client = AIGateClient(project_id="your-project-id")
        >>> session = client.create_session(voice="echo")
        >>> print(session["id"])
    """

    def __init__(
        self,
        project_id: str,
        base_url: str = "https://api.ai-gate.dev",
        timeout: float = 30.0,
        debug: bool = False,
    ) -> None:
        if not project_id:
            raise AIGateError(
                "Project ID is required. Get yours from https://www.ai-gate.dev/dashboard"
            )

        self.project_id = project_id
        self.base_url = base_url
        self.timeout = timeout
        self.debug = debug
        self._client = httpx.Client(timeout=timeout)

    def __enter__(self) -> "AIGateClient":
        return self

    def __exit__(self, *args: object) -> None:
        self.close()

    def close(self) -> None:
        """Close the HTTP client"""
        self._client.close()

    def _log(self, *args: object) -> None:
        """Log debug messages"""
        if self.debug:
            print("[AIGate SDK]", *args)

    def create_session(
        self,
        model: str = "gpt-4o-realtime-preview-2024-10-01",
        voice: str = "echo",
        temperature: float = 0.7,
        instructions: str = "You are a helpful assistant",
    ) -> SessionResponse:
        """
        Create a new OpenAI Realtime session

        This creates a session using your project's OpenAI API key stored in the vault.
        Returns session details including WebRTC configuration and TURN credentials.

        Args:
            model: OpenAI model to use (default: gpt-4o-realtime-preview-2024-10-01)
            voice: Voice to use: alloy, echo, fable, onyx, nova, shimmer (default: echo)
            temperature: Model temperature 0-1 (default: 0.7)
            instructions: System instructions for the assistant (default: "You are a helpful assistant")

        Returns:
            Session details including client_secret for WebRTC connection

        Raises:
            AIGateError: If session creation fails

        Example:
            >>> session = client.create_session(
            ...     voice="nova",
            ...     temperature=0.8,
            ...     instructions="You are a friendly customer support agent"
            ... )
            >>> print(session["client_secret"]["value"])
        """
        self._log(f"Creating session with project: {self.project_id}")

        body = {
            "project_id": self.project_id,
            "model": model,
            "voice": voice,
            "temperature": temperature,
            "instructions": instructions,
        }

        try:
            response = self._client.post(
                f"{self.base_url}/session",
                json=body,
                headers={"Content-Type": "application/json"},
            )

            if not response.is_success:
                error_data = response.json()

                # Handle quota exceeded
                if error_data.get("error") == "quota_exceeded":
                    raise AIGateError(
                        f"Quota exceeded: {error_data.get('message')}",
                        status_code=402,
                        response=error_data,
                    )

                # Handle rate limit
                if response.status_code == 429:
                    raise AIGateError(
                        f"Rate limit exceeded: {error_data.get('message')}",
                        status_code=429,
                        response=error_data,
                    )

                # Handle concurrent limit
                if error_data.get("error") == "concurrent_limit_exceeded":
                    raise AIGateError(
                        f"Concurrent limit exceeded: {error_data.get('message')}",
                        status_code=429,
                        response=error_data,
                    )

                raise AIGateError(
                    error_data.get("message", "Failed to create session"),
                    status_code=response.status_code,
                    response=error_data,
                )

            session = response.json()
            self._log(f"Session created: {session['session_id']}")
            return session

        except httpx.HTTPError as e:
            raise AIGateError(f"HTTP error: {str(e)}")

    def get_turn_credentials(self) -> TurnCredentials:
        """
        Get TURN credentials for WebRTC

        This is usually included in the session response, but you can fetch it separately.

        Returns:
            TURN server credentials for WebRTC connection

        Raises:
            AIGateError: If request fails

        Example:
            >>> turn = client.get_turn_credentials()
            >>> print(turn["iceServers"])
        """
        self._log(f"Fetching TURN credentials for project: {self.project_id}")

        try:
            response = self._client.get(
                f"{self.base_url}/turn-credentials",
                params={"identifier": self.project_id},
            )

            if not response.is_success:
                error_data = response.json()
                raise AIGateError(
                    error_data.get("message", "Failed to get TURN credentials"),
                    status_code=response.status_code,
                    response=error_data,
                )

            credentials = response.json()
            self._log("TURN credentials obtained")
            return credentials

        except httpx.HTTPError as e:
            raise AIGateError(f"HTTP error: {str(e)}")


class AsyncAIGateClient:
    """
    Async AI Gate SDK Client

    Async version of AIGateClient for use with asyncio.

    Args:
        project_id: Your project ID from the dashboard
        base_url: API base URL (default: https://api.ai-gate.dev)
        timeout: Request timeout in seconds (default: 30)
        debug: Enable debug logging (default: False)

    Example:
        >>> async with AsyncAIGateClient(project_id="your-project-id") as client:
        ...     session = await client.create_session(voice="echo")
        ...     print(session["id"])
    """

    def __init__(
        self,
        project_id: str,
        base_url: str = "https://api.ai-gate.dev",
        timeout: float = 30.0,
        debug: bool = False,
    ) -> None:
        if not project_id:
            raise AIGateError(
                "Project ID is required. Get yours from https://www.ai-gate.dev/dashboard"
            )

        self.project_id = project_id
        self.base_url = base_url
        self.timeout = timeout
        self.debug = debug
        self._client = httpx.AsyncClient(timeout=timeout)

    async def __aenter__(self) -> "AsyncAIGateClient":
        return self

    async def __aexit__(self, *args: object) -> None:
        await self.close()

    async def close(self) -> None:
        """Close the HTTP client"""
        await self._client.aclose()

    def _log(self, *args: object) -> None:
        """Log debug messages"""
        if self.debug:
            print("[AIGate SDK]", *args)

    async def create_session(
        self,
        model: str = "gpt-4o-realtime-preview-2024-10-01",
        voice: str = "echo",
        temperature: float = 0.7,
        instructions: str = "You are a helpful assistant",
    ) -> SessionResponse:
        """
        Create a new OpenAI Realtime session (async)

        Args:
            model: OpenAI model to use
            voice: Voice to use
            temperature: Model temperature 0-1
            instructions: System instructions

        Returns:
            Session details including client_secret

        Raises:
            AIGateError: If session creation fails
        """
        self._log(f"Creating session with project: {self.project_id}")

        body = {
            "project_id": self.project_id,
            "model": model,
            "voice": voice,
            "temperature": temperature,
            "instructions": instructions,
        }

        try:
            response = await self._client.post(
                f"{self.base_url}/session",
                json=body,
                headers={"Content-Type": "application/json"},
            )

            if not response.is_success:
                error_data = response.json()

                if error_data.get("error") == "quota_exceeded":
                    raise AIGateError(
                        f"Quota exceeded: {error_data.get('message')}",
                        status_code=402,
                        response=error_data,
                    )

                if response.status_code == 429:
                    raise AIGateError(
                        f"Rate limit exceeded: {error_data.get('message')}",
                        status_code=429,
                        response=error_data,
                    )

                if error_data.get("error") == "concurrent_limit_exceeded":
                    raise AIGateError(
                        f"Concurrent limit exceeded: {error_data.get('message')}",
                        status_code=429,
                        response=error_data,
                    )

                raise AIGateError(
                    error_data.get("message", "Failed to create session"),
                    status_code=response.status_code,
                    response=error_data,
                )

            session = response.json()
            self._log(f"Session created: {session['session_id']}")
            return session

        except httpx.HTTPError as e:
            raise AIGateError(f"HTTP error: {str(e)}")

    async def get_turn_credentials(self) -> TurnCredentials:
        """
        Get TURN credentials for WebRTC (async)

        Returns:
            TURN server credentials

        Raises:
            AIGateError: If request fails
        """
        self._log(f"Fetching TURN credentials for project: {self.project_id}")

        try:
            response = await self._client.get(
                f"{self.base_url}/turn-credentials",
                params={"identifier": self.project_id},
            )

            if not response.is_success:
                error_data = response.json()
                raise AIGateError(
                    error_data.get("message", "Failed to get TURN credentials"),
                    status_code=response.status_code,
                    response=error_data,
                )

            credentials = response.json()
            self._log("TURN credentials obtained")
            return credentials

        except httpx.HTTPError as e:
            raise AIGateError(f"HTTP error: {str(e)}")

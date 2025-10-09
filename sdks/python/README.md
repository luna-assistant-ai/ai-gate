# AI Gate SDK for Python

Official Python SDK for [AI Gate](https://www.ai-gate.dev) - Secure proxy for OpenAI Realtime API with WebRTC support.

## Features

- 🔐 **Secure**: Your OpenAI API key stays in the vault, never exposed to clients
- 🚀 **Simple**: Just use your project ID from the dashboard
- 📦 **Lightweight**: Minimal dependencies (only `httpx`)
- 🌐 **WebRTC Ready**: Includes TURN credentials for reliable connections
- 💪 **Type Hints**: Full type annotations for better IDE support
- ⚡ **Rate Limiting**: Built-in rate limiting and quota management
- 🔄 **Async Support**: Both sync and async clients available

## Installation

```bash
pip install ai-gate
```

Or with poetry:

```bash
poetry add ai-gate
```

## Quick Start

### 1. Get Your Project ID

1. Go to [AI Gate Dashboard](https://www.ai-gate.dev/dashboard)
2. Create a new project
3. Add your OpenAI API key to the project vault
4. Copy your project ID

### 2. Create a Session

```python
from ai_gate import AIGateClient

client = AIGateClient(project_id="your-project-id-from-dashboard")

# Create a session
session = client.create_session(
    model="gpt-4o-realtime-preview-2024-10-01",
    voice="echo",
    instructions="You are a helpful assistant"
)

print("Session ID:", session["id"])
print("Client Secret:", session["client_secret"]["value"])
print("TURN Credentials:", session["turn_credentials"])
```

### 3. Use with Context Manager

```python
from ai_gate import AIGateClient

with AIGateClient(project_id="your-project-id") as client:
    session = client.create_session(voice="nova")
    print("Session created:", session["session_id"])
```

## Async Usage

```python
import asyncio
from ai_gate.client import AsyncAIGateClient

async def main():
    async with AsyncAIGateClient(project_id="your-project-id") as client:
        session = await client.create_session(voice="echo")
        print("Session ID:", session["id"])

asyncio.run(main())
```

## API Reference

### `AIGateClient`

Main SDK client class (synchronous).

#### Constructor

```python
AIGateClient(
    project_id: str,
    base_url: str = "https://api.ai-gate.dev",
    timeout: float = 30.0,
    debug: bool = False
)
```

**Parameters:**
- `project_id` (required): Your project ID from the dashboard
- `base_url` (optional): API base URL (default: `https://api.ai-gate.dev`)
- `timeout` (optional): Request timeout in seconds (default: `30.0`)
- `debug` (optional): Enable debug logging (default: `False`)

#### Methods

##### `create_session()`

Create a new OpenAI Realtime API session.

```python
create_session(
    model: str = "gpt-4o-realtime-preview-2024-10-01",
    voice: str = "echo",
    temperature: float = 0.7,
    instructions: str = "You are a helpful assistant"
) -> SessionResponse
```

**Parameters:**
- `model`: OpenAI model (default: `gpt-4o-realtime-preview-2024-10-01`)
- `voice`: Voice: `alloy`, `echo`, `fable`, `onyx`, `nova`, `shimmer` (default: `echo`)
- `temperature`: Model temperature 0-1 (default: `0.7`)
- `instructions`: System instructions (default: `"You are a helpful assistant"`)

**Returns:**
- `SessionResponse` dict with OpenAI session details, client secret, and TURN credentials

**Raises:**
- `AIGateError` if session creation fails

**Example:**

```python
session = client.create_session(
    voice="nova",
    temperature=0.8,
    instructions="You are a friendly customer support agent"
)
```

##### `get_turn_credentials()`

Get TURN server credentials for WebRTC.

```python
get_turn_credentials() -> TurnCredentials
```

**Note:** TURN credentials are already included in the session response.

**Returns:**
- `TurnCredentials` dict with ICE servers configuration

**Example:**

```python
turn = client.get_turn_credentials()
print("ICE Servers:", turn["iceServers"])
```

##### `close()`

Close the HTTP client.

```python
close() -> None
```

### `AsyncAIGateClient`

Async version of AIGateClient for use with asyncio.

Same API as `AIGateClient` but all methods are async (use `await`).

## Error Handling

The SDK raises `AIGateError` for all API errors:

```python
from ai_gate import AIGateClient, AIGateError

client = AIGateClient(project_id="your-project-id")

try:
    session = client.create_session()
except AIGateError as error:
    print("Error:", error)
    print("Status Code:", error.status_code)

    if error.status_code == 402:
        # Quota exceeded
        print("Upgrade URL:", error.response["upgrade_url"])
    elif error.status_code == 429:
        # Rate limit or concurrent limit
        print("Too many requests, try again later")
```

## Rate Limits & Quotas

### Free Plan
- **5 concurrent sessions per project**
- Rate limit: 100 requests per 15 minutes
- Session expires after 1 hour of inactivity

### Paid Plans
Check [AI Gate Pricing](https://www.ai-gate.dev/pricing) for current limits.

## Examples

### Basic Example

```python
from ai_gate import AIGateClient

client = AIGateClient(
    project_id="your-project-id",
    debug=True
)

try:
    session = client.create_session(
        voice="echo",
        instructions="You are a helpful coding assistant"
    )

    print("✅ Session created!")
    print(f"  Session ID: {session['session_id']}")
    print(f"  Model: {session['metadata']['model']}")
    print(f"  Voice: {session['metadata']['voice']}")

except Exception as error:
    print(f"❌ Error: {error}")
finally:
    client.close()
```

### With Context Manager

```python
from ai_gate import AIGateClient

with AIGateClient(project_id="your-project-id") as client:
    session = client.create_session(voice="nova")
    print("Session:", session["id"])
# Client automatically closed
```

### Async Example

```python
import asyncio
from ai_gate.client import AsyncAIGateClient

async def create_multiple_sessions():
    async with AsyncAIGateClient(project_id="your-project-id") as client:
        # Create multiple sessions concurrently
        tasks = [
            client.create_session(voice="echo"),
            client.create_session(voice="nova"),
            client.create_session(voice="alloy"),
        ]

        sessions = await asyncio.gather(*tasks)

        for i, session in enumerate(sessions):
            print(f"Session {i+1}: {session['id']}")

asyncio.run(create_multiple_sessions())
```

### Error Handling Example

```python
from ai_gate import AIGateClient, AIGateError
import os

client = AIGateClient(
    project_id=os.getenv("AI_GATE_PROJECT_ID"),
    debug=True
)

try:
    session = client.create_session()
    print("✅ Session created:", session["id"])

except AIGateError as error:
    if error.status_code == 402:
        print("💰 Quota exceeded!")
        print(f"   Plan: {error.response['usage']['plan']}")
        print(f"   Sessions used: {error.response['usage']['sessionsUsed']}")
        print(f"   Upgrade: {error.response['upgrade_url']}")

    elif error.status_code == 429:
        if error.response.get("error") == "concurrent_limit_exceeded":
            print("🔄 Too many concurrent sessions!")
            print(f"   Current: {error.response['current']}")
            print(f"   Max: {error.response['max']}")
        else:
            print("⏱️ Rate limit exceeded!")
            print(f"   Reset at: {error.response['resetAt']}")

    else:
        print(f"❌ Error: {error}")

except Exception as error:
    print(f"❌ Unexpected error: {error}")

finally:
    client.close()
```

## Type Hints

The SDK includes full type annotations:

```python
from ai_gate import AIGateClient
from ai_gate.types import SessionResponse, TurnCredentials

def handle_session(session: SessionResponse) -> None:
    # Full autocomplete and type checking
    print(session["metadata"]["model"])
    print(session["turn_credentials"]["iceServers"])

client: AIGateClient = AIGateClient(project_id="your-project-id")
session: SessionResponse = client.create_session()
handle_session(session)
```

## Development

### Setup

```bash
# Clone the repository
git clone https://github.com/luna-assistant-ai/ai-gate.git
cd ai-gate/sdks/python

# Install dependencies
pip install -e ".[dev]"

# Run tests
pytest

# Format code
black ai_gate

# Type checking
mypy ai_gate
```

## Support

- 📚 [Documentation](https://www.ai-gate.dev/docs)
- 💬 [GitHub Issues](https://github.com/luna-assistant-ai/ai-gate/issues)
- 📧 [Support Email](mailto:support@ai-gate.dev)

## License

MIT © AI Gate

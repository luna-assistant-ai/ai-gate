# AI Gate SDKs

Official SDKs for [AI Gate](https://www.ai-gate.dev) - Secure proxy for OpenAI Realtime API with WebRTC support.

## Available SDKs

### [TypeScript/JavaScript SDK](./typescript)

[![npm version](https://img.shields.io/npm/v/@ai-gate/sdk)](https://www.npmjs.com/package/@ai-gate/sdk)

For Node.js and browser applications.

```bash
npm install @ai-gate/sdk
```

```typescript
import { AIGateClient } from '@ai-gate/sdk';

const client = new AIGateClient({
  projectId: 'your-project-id'
});

const session = await client.createSession({
  voice: 'echo',
  instructions: 'You are a helpful assistant'
});
```

[📚 TypeScript Documentation](./typescript/README.md)

---

### [Python SDK](./python)

[![PyPI version](https://img.shields.io/pypi/v/ai-gate)](https://pypi.org/project/ai-gate/)

For Python applications with sync and async support.

```bash
pip install ai-gate
```

```python
from ai_gate import AIGateClient

client = AIGateClient(project_id="your-project-id")

session = client.create_session(
    voice="echo",
    instructions="You are a helpful assistant"
)
```

[📚 Python Documentation](./python/README.md)

---

## Quick Start

### 1. Get Your Project ID

1. Go to [AI Gate Dashboard](https://www.ai-gate.dev/dashboard)
2. Create a new project
3. Add your OpenAI API key to the project vault
4. Copy your project ID

### 2. Install SDK

Choose your preferred language and install the SDK:

**TypeScript/JavaScript:**
```bash
npm install @ai-gate/sdk
```

**Python:**
```bash
pip install ai-gate
```

### 3. Create a Session

Use your project ID to create sessions:

**TypeScript:**
```typescript
import { AIGateClient } from '@ai-gate/sdk';

const client = new AIGateClient({
  projectId: 'your-project-id-from-dashboard'
});

const session = await client.createSession();
console.log('Session ID:', session.id);
```

**Python:**
```python
from ai_gate import AIGateClient

client = AIGateClient(project_id="your-project-id-from-dashboard")

session = client.create_session()
print("Session ID:", session["id"])
```

## Features

✅ **All SDKs include:**

- 🔐 **Secure Authentication**: Your OpenAI API key stays in the vault
- 🚀 **Simple API**: Just use your project ID
- 📦 **Lightweight**: Minimal dependencies
- 🌐 **WebRTC Ready**: TURN credentials included
- 💪 **Type Safety**: Full type definitions (TS) / hints (Python)
- ⚡ **Rate Limiting**: Built-in rate limiting and quota management
- 🔄 **Error Handling**: Comprehensive error handling with typed responses
- 📊 **Concurrent Control**: Automatic session limits

## Authentication

All SDKs use **project-based authentication**:

1. **Create a project** in the [AI Gate Dashboard](https://www.ai-gate.dev/dashboard)
2. **Store your OpenAI API key** in the project vault (secure, never exposed to clients)
3. **Use your project ID** in the SDK (safe to use in client-side code)

### Why Project-Based?

- ✅ Your OpenAI API key **never** leaves the server
- ✅ Safe to use in browsers and mobile apps
- ✅ Centralized key management
- ✅ Easy key rotation without code changes
- ✅ Built-in quota and rate limiting per project

## API Reference

### Create Session

Create a new OpenAI Realtime API session.

**TypeScript:**
```typescript
const session = await client.createSession({
  model: 'gpt-4o-realtime-preview-2024-10-01',
  voice: 'echo' | 'alloy' | 'fable' | 'onyx' | 'nova' | 'shimmer',
  temperature: 0.7,
  instructions: 'You are a helpful assistant'
});
```

**Python:**
```python
session = client.create_session(
    model="gpt-4o-realtime-preview-2024-10-01",
    voice="echo",  # or: alloy, fable, onyx, nova, shimmer
    temperature=0.7,
    instructions="You are a helpful assistant"
)
```

**Returns:**
- `session.id` - OpenAI session ID
- `session.client_secret` - Client secret for WebRTC connection
- `session.turn_credentials` - TURN server credentials
- `session.metadata` - Session metadata (model, voice, timestamps)

### Get TURN Credentials

Get TURN server credentials for WebRTC (usually included in session response).

**TypeScript:**
```typescript
const turn = await client.getTurnCredentials();
```

**Python:**
```python
turn = client.get_turn_credentials()
```

## Error Handling

All SDKs throw/raise specific errors for different scenarios:

### Quota Exceeded (HTTP 402)

When monthly session quota is exceeded.

**TypeScript:**
```typescript
try {
  const session = await client.createSession();
} catch (error) {
  if (error.statusCode === 402) {
    console.log('Quota exceeded!');
    console.log('Upgrade:', error.response.upgrade_url);
  }
}
```

**Python:**
```python
try:
    session = client.create_session()
except AIGateError as error:
    if error.status_code == 402:
        print("Quota exceeded!")
        print("Upgrade:", error.response["upgrade_url"])
```

### Rate Limit (HTTP 429)

When rate limit is exceeded (100 requests per 15 minutes).

**TypeScript:**
```typescript
if (error.statusCode === 429) {
  console.log('Rate limit exceeded');
  console.log('Reset at:', error.response.resetAt);
}
```

**Python:**
```python
if error.status_code == 429:
    print("Rate limit exceeded")
    print("Reset at:", error.response["resetAt"])
```

### Concurrent Limit (HTTP 429)

When project concurrent session limit is reached (5 for free plan).

**TypeScript:**
```typescript
if (error.response.error === 'concurrent_limit_exceeded') {
  console.log('Too many concurrent sessions');
  console.log('Current:', error.response.current);
  console.log('Max:', error.response.max);
}
```

**Python:**
```python
if error.response.get("error") == "concurrent_limit_exceeded":
    print("Too many concurrent sessions")
    print("Current:", error.response["current"])
    print("Max:", error.response["max"])
```

## Rate Limits & Quotas

### Free Plan
- ✅ 5 concurrent sessions per project
- ✅ 100 requests per 15 minutes
- ✅ Sessions expire after 1 hour of inactivity
- ✅ TURN server included

### Paid Plans
Check [AI Gate Pricing](https://www.ai-gate.dev/pricing) for current limits.

## Examples

### TypeScript Examples

- [Basic Usage](./typescript/examples/basic.ts)
- [WebRTC Integration](./typescript/examples/webrtc.ts)

### Python Examples

- [Basic Usage](./python/examples/basic.py)
- [Async Usage](./python/examples/async_example.py)

## WebRTC Integration

Both SDKs provide TURN credentials for WebRTC connections. Here's a basic flow:

1. **Create session** with AI Gate
2. **Extract credentials** from response
3. **Setup RTCPeerConnection** with TURN servers
4. **Create offer** and send to OpenAI
5. **Set remote description** from OpenAI response
6. **Send/receive events** via data channel

See language-specific documentation for complete examples.

## Support

- 📚 [Documentation](https://www.ai-gate.dev/docs)
- 💬 [GitHub Issues](https://github.com/luna-assistant-ai/ai-gate/issues)
- 📧 [Support Email](mailto:support@ai-gate.dev)
- 💼 [Dashboard](https://www.ai-gate.dev/dashboard)

## Contributing

We welcome contributions! Please see each SDK's directory for development instructions.

### TypeScript SDK

```bash
cd sdks/typescript
npm install
npm run build
npm test
```

### Python SDK

```bash
cd sdks/python
pip install -e ".[dev]"
pytest
black ai_gate
mypy ai_gate
```

## License

MIT © AI Gate

---

## Roadmap

### Planned SDKs

- [ ] Go SDK
- [ ] Ruby SDK
- [ ] PHP SDK
- [ ] Java/Kotlin SDK
- [ ] Swift SDK
- [ ] C# SDK

Want to contribute an SDK for your favorite language? Open an issue or PR!

---

Made with ❤️ by the AI Gate team

# AI Gate SDK for TypeScript/JavaScript

Official SDK for [AI Gate](https://www.ai-gate.dev) - Secure proxy for OpenAI Realtime API with WebRTC support.

## Features

- 🔐 **Secure**: Your OpenAI API key stays in the vault, never exposed to clients
- 🚀 **Simple**: Just use your project ID from the dashboard
- 📦 **Lightweight**: Zero dependencies, works in Node.js and browsers
- 🌐 **WebRTC Ready**: Includes TURN credentials for reliable connections
- 💪 **TypeScript**: Full type definitions included
- ⚡ **Rate Limiting**: Built-in rate limiting and quota management
- 🔄 **Concurrent Control**: Automatic session limits for projects

## Installation

```bash
npm install @ai-gate/sdk
```

Or with yarn:

```bash
yarn add @ai-gate/sdk
```

Or with pnpm:

```bash
pnpm add @ai-gate/sdk
```

## Quick Start

### 1. Get Your Project ID

1. Go to [AI Gate Dashboard](https://www.ai-gate.dev/dashboard)
2. Create a new project
3. Add your OpenAI API key to the project vault
4. Copy your project ID

### 2. Create a Session

```typescript
import { AIGateClient } from '@ai-gate/sdk';

const client = new AIGateClient({
  projectId: 'your-project-id-from-dashboard'
});

// Create a session
const session = await client.createSession({
  model: 'gpt-4o-realtime-preview-2024-10-01',
  voice: 'echo',
  instructions: 'You are a helpful assistant'
});

console.log('Session ID:', session.id);
console.log('Client Secret:', session.client_secret.value);
console.log('TURN Credentials:', session.turn_credentials);
```

### 3. Connect with WebRTC

```typescript
// Create peer connection with TURN credentials
const pc = new RTCPeerConnection({
  iceServers: session.turn_credentials.iceServers
});

// Add data channel
const dc = pc.createDataChannel('oai-events');

// Create and set local description
const offer = await pc.createOffer();
await pc.setLocalDescription(offer);

// Send offer to OpenAI
const sdpResponse = await fetch(
  `https://api.openai.com/v1/realtime?model=${session.model}`,
  {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${session.client_secret.value}`,
      'Content-Type': 'application/sdp'
    },
    body: offer.sdp
  }
);

const answer = {
  type: 'answer' as RTCSdpType,
  sdp: await sdpResponse.text()
};

await pc.setRemoteDescription(answer);

// Now you can send/receive events via data channel
dc.onopen = () => {
  console.log('Connected to OpenAI Realtime API!');
};

dc.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Received event:', message);
};
```

## API Reference

### `AIGateClient`

Main SDK client class.

#### Constructor

```typescript
new AIGateClient(config: AIGateConfig)
```

**Parameters:**
- `config.projectId` (required): Your project ID from the dashboard
- `config.baseUrl` (optional): API base URL (default: `https://api.ai-gate.dev`)
- `config.timeout` (optional): Request timeout in ms (default: `30000`)
- `config.debug` (optional): Enable debug logging (default: `false`)

#### Methods

##### `createSession(config?: SessionConfig): Promise<SessionResponse>`

Create a new OpenAI Realtime API session.

**Parameters:**
- `config.model` (optional): OpenAI model (default: `gpt-4o-realtime-preview-2024-10-01`)
- `config.voice` (optional): Voice to use: `alloy`, `echo`, `fable`, `onyx`, `nova`, `shimmer` (default: `echo`)
- `config.temperature` (optional): Model temperature 0-1 (default: `0.7`)
- `config.instructions` (optional): System instructions (default: `"You are a helpful assistant"`)

**Returns:**
- `SessionResponse` with OpenAI session details, client secret, and TURN credentials

**Throws:**
- `AIGateError` if session creation fails
- Quota exceeded (HTTP 402)
- Rate limit exceeded (HTTP 429)
- Concurrent limit exceeded (HTTP 429)

**Example:**

```typescript
const session = await client.createSession({
  voice: 'nova',
  temperature: 0.8,
  instructions: 'You are a friendly customer support agent'
});
```

##### `getTurnCredentials(): Promise<TurnCredentials>`

Get TURN server credentials for WebRTC.

**Note:** TURN credentials are already included in the session response, so you typically don't need to call this separately.

**Returns:**
- `TurnCredentials` with ICE servers configuration

**Example:**

```typescript
const turn = await client.getTurnCredentials();
const pc = new RTCPeerConnection({
  iceServers: turn.iceServers
});
```

## Error Handling

The SDK throws `AIGateError` for all API errors. You can check the error type and handle accordingly:

```typescript
import { AIGateClient, AIGateError } from '@ai-gate/sdk';

try {
  const session = await client.createSession();
} catch (error) {
  if (error instanceof AIGateError) {
    console.error('AI Gate Error:', error.message);
    console.error('Status Code:', error.statusCode);

    if (error.statusCode === 402) {
      // Quota exceeded
      console.error('Upgrade your plan:', error.response.upgrade_url);
    } else if (error.statusCode === 429) {
      // Rate limit or concurrent limit
      console.error('Too many requests, try again later');
    }
  }
}
```

## Rate Limits & Quotas

### Free Plan
- **5 concurrent sessions per project**
- Rate limit: 100 requests per 15 minutes
- Session expires after 1 hour of inactivity

### Paid Plans
Check [AI Gate Pricing](https://www.ai-gate.dev/pricing) for current limits.

## Examples

### Node.js Example

```typescript
import { AIGateClient } from '@ai-gate/sdk';

const client = new AIGateClient({
  projectId: process.env.AI_GATE_PROJECT_ID!,
  debug: true
});

async function main() {
  try {
    const session = await client.createSession({
      voice: 'echo',
      instructions: 'You are a helpful coding assistant'
    });

    console.log('✅ Session created successfully!');
    console.log('Session ID:', session.id);
    console.log('Expires at:', new Date(session.expires_at * 1000));
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

main();
```

### Browser Example

```html
<!DOCTYPE html>
<html>
<head>
  <title>AI Gate WebRTC Example</title>
</head>
<body>
  <button id="connect">Connect to AI</button>
  <div id="status"></div>

  <script type="module">
    import { AIGateClient } from '@ai-gate/sdk';

    const client = new AIGateClient({
      projectId: 'your-project-id'
    });

    document.getElementById('connect').addEventListener('click', async () => {
      const status = document.getElementById('status');

      try {
        status.textContent = 'Creating session...';
        const session = await client.createSession();

        status.textContent = 'Connecting to OpenAI...';

        // Setup WebRTC
        const pc = new RTCPeerConnection({
          iceServers: session.turn_credentials.iceServers
        });

        const dc = pc.createDataChannel('oai-events');

        dc.onopen = () => {
          status.textContent = '✅ Connected!';
        };

        dc.onmessage = (event) => {
          const message = JSON.parse(event.data);
          console.log('Event:', message);
        };

        // Create offer
        const offer = await pc.createOffer();
        await pc.setLocalDescription(offer);

        // Send to OpenAI
        const response = await fetch(
          `https://api.openai.com/v1/realtime?model=${session.model}`,
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${session.client_secret.value}`,
              'Content-Type': 'application/sdp'
            },
            body: offer.sdp
          }
        );

        const answer = {
          type: 'answer',
          sdp: await response.text()
        };

        await pc.setRemoteDescription(answer);
      } catch (error) {
        status.textContent = `❌ Error: ${error.message}`;
      }
    });
  </script>
</body>
</html>
```

## TypeScript Support

The SDK is written in TypeScript and provides full type definitions:

```typescript
import type { SessionResponse, TurnCredentials } from '@ai-gate/sdk';

function handleSession(session: SessionResponse) {
  // Full autocomplete and type safety
  console.log(session.metadata.model);
  console.log(session.turn_credentials.iceServers);
}
```

## Support

- 📚 [Documentation](https://www.ai-gate.dev/docs)
- 💬 [GitHub Issues](https://github.com/luna-assistant-ai/ai-gate/issues)
- 📧 [Support Email](mailto:support@ai-gate.dev)

## License

MIT © AI Gate

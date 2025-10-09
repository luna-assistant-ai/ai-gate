# Testing the SDKs Locally

This guide shows you how to test the TypeScript and Python SDKs with a real project from your dashboard.

## Prerequisites

1. **Access to AI Gate Dashboard**: https://www.ai-gate.dev/dashboard
2. **An OpenAI API key**
3. **Node.js** (for TypeScript SDK) or **Python 3.8+** (for Python SDK)

## Step 1: Create a Project in the Dashboard

1. Go to https://www.ai-gate.dev/dashboard
2. Login with your account
3. Navigate to the **Projects** section
4. Click **"Create New Project"**
5. Enter:
   - **Project Name**: e.g., "SDK Test Project"
   - **OpenAI API Key**: Your OpenAI API key (will be stored securely in the vault)
6. Click **Create**
7. **Copy the Project ID** - it looks like: `proj_abc123xyz...`

## Step 2: Test TypeScript SDK

### Install Dependencies

```bash
cd sdks/typescript
npm install
```

### Create Test Script

Create a file `test-local.ts`:

```typescript
import { AIGateClient, AIGateError } from './src';

async function main() {
  // Replace with your actual project ID from the dashboard
  const PROJECT_ID = process.env.AI_GATE_PROJECT_ID || 'your-project-id-here';

  console.log('🚀 Testing AI Gate TypeScript SDK\n');
  console.log('Project ID:', PROJECT_ID);

  const client = new AIGateClient({
    projectId: PROJECT_ID,
    debug: true,
  });

  try {
    console.log('\n📝 Creating session...\n');

    const session = await client.createSession({
      voice: 'echo',
      temperature: 0.7,
      instructions: 'You are a helpful assistant for testing the SDK',
    });

    console.log('\n✅ SUCCESS! Session created:\n');
    console.log('  Session ID:', session.session_id);
    console.log('  OpenAI Session:', session.id);
    console.log('  Model:', session.metadata.model);
    console.log('  Voice:', session.metadata.voice);
    console.log('  TURN Server:', session.metadata.turn_server);
    console.log('  Created:', session.metadata.created_at);

    if (session.client_secret) {
      console.log('\n🔐 Client Secret (for WebRTC):');
      console.log('  ', session.client_secret.value.substring(0, 30) + '...');
    }

    console.log('\n🌐 TURN Credentials:');
    session.turn_credentials.iceServers.forEach((server, i) => {
      console.log(`  Server ${i + 1}:`, server.urls);
    });

    console.log('\n✅ SDK is working correctly!');
  } catch (error) {
    if (error instanceof AIGateError) {
      console.error('\n❌ AI Gate Error:');
      console.error('  Message:', error.message);
      console.error('  Status Code:', error.statusCode);

      if (error.statusCode === 402) {
        console.error('\n💡 Quota exceeded. Upgrade your plan:');
        console.error('  ', error.response?.upgrade_url);
      } else if (error.statusCode === 429) {
        console.error('\n💡 Rate limit or concurrent limit exceeded.');
        console.error('  Please wait and try again.');
      } else if (error.statusCode === 401) {
        console.error('\n💡 Authentication failed.');
        console.error('  Check that your project ID is correct.');
      }
    } else {
      console.error('\n❌ Unexpected error:', error);
    }
    process.exit(1);
  }
}

main();
```

### Run the Test

```bash
# Using environment variable (recommended)
export AI_GATE_PROJECT_ID="your-project-id-from-dashboard"
npx tsx test-local.ts

# Or directly in the script (replace PROJECT_ID in the file)
npx tsx test-local.ts
```

## Step 3: Test Python SDK

### Install Dependencies

```bash
cd sdks/python
pip install -e .
```

### Create Test Script

Create a file `test_local.py`:

```python
#!/usr/bin/env python3
"""Test script for AI Gate Python SDK"""

import os
from ai_gate import AIGateClient, AIGateError


def main():
    # Replace with your actual project ID from the dashboard
    project_id = os.getenv("AI_GATE_PROJECT_ID", "your-project-id-here")

    print("🚀 Testing AI Gate Python SDK\n")
    print(f"Project ID: {project_id}")

    with AIGateClient(project_id=project_id, debug=True) as client:
        try:
            print("\n📝 Creating session...\n")

            session = client.create_session(
                voice="echo",
                temperature=0.7,
                instructions="You are a helpful assistant for testing the SDK",
            )

            print("\n✅ SUCCESS! Session created:\n")
            print(f"  Session ID: {session['session_id']}")
            print(f"  OpenAI Session: {session['id']}")
            print(f"  Model: {session['metadata']['model']}")
            print(f"  Voice: {session['metadata']['voice']}")
            print(f"  TURN Server: {session['metadata']['turn_server']}")
            print(f"  Created: {session['metadata']['created_at']}")

            if "client_secret" in session:
                print("\n🔐 Client Secret (for WebRTC):")
                print(f"  {session['client_secret']['value'][:30]}...")

            print("\n🌐 TURN Credentials:")
            for i, server in enumerate(session["turn_credentials"]["iceServers"]):
                print(f"  Server {i + 1}: {server['urls']}")

            print("\n✅ SDK is working correctly!")

        except AIGateError as error:
            print("\n❌ AI Gate Error:")
            print(f"  Message: {error}")
            print(f"  Status Code: {error.status_code}")

            if error.status_code == 402:
                print("\n💡 Quota exceeded. Upgrade your plan:")
                print(f"  {error.response.get('upgrade_url')}")
            elif error.status_code == 429:
                print("\n💡 Rate limit or concurrent limit exceeded.")
                print("  Please wait and try again.")
            elif error.status_code == 401:
                print("\n💡 Authentication failed.")
                print("  Check that your project ID is correct.")

            exit(1)

        except Exception as error:
            print(f"\n❌ Unexpected error: {error}")
            exit(1)


if __name__ == "__main__":
    main()
```

### Run the Test

```bash
# Using environment variable (recommended)
export AI_GATE_PROJECT_ID="your-project-id-from-dashboard"
python test_local.py

# Or directly in the script (replace project_id in the file)
python test_local.py
```

## Expected Output

If everything works correctly, you should see:

```
🚀 Testing AI Gate Python SDK

Project ID: proj_abc123xyz...
[AIGate SDK] Creating session with project: proj_abc123xyz...

📝 Creating session...

[AIGate SDK] Session created: aigate_session_xyz123...

✅ SUCCESS! Session created:

  Session ID: aigate_session_xyz123...
  OpenAI Session: sess_abc123...
  Model: gpt-4o-realtime-preview-2024-10-01
  Voice: echo
  TURN Server: cloudflare
  Created: 2025-10-10T12:34:56.789Z

🔐 Client Secret (for WebRTC):
  eph-abc123xyz456def789ghi012...

🌐 TURN Credentials:
  Server 1: stun:stun.cloudflare.com:3478
  Server 2: turn:turn.cloudflare.com:3478

✅ SDK is working correctly!
```

## Common Errors

### Error: "Project ID is required"
**Cause**: No project ID provided
**Solution**: Make sure to set `AI_GATE_PROJECT_ID` environment variable or update the script

### Error: "Authentication required" (HTTP 401)
**Cause**: Invalid or missing project ID
**Solution**:
- Check that you copied the correct project ID from dashboard
- Verify the project exists in https://www.ai-gate.dev/dashboard

### Error: "Quota exceeded" (HTTP 402)
**Cause**: Monthly session quota reached
**Solution**: Upgrade your plan or wait for quota reset

### Error: "Rate limit exceeded" (HTTP 429)
**Cause**: Too many requests (100 per 15 minutes)
**Solution**: Wait a few minutes and try again

### Error: "Concurrent limit exceeded" (HTTP 429)
**Cause**: Too many active sessions (5 for free plan)
**Solution**: Wait for sessions to expire (1 hour) or close existing sessions

## Next Steps

Once the SDKs are tested and working:

1. **Integrate into your application** using the examples in the README
2. **Test WebRTC connection** (see `examples/webrtc.ts` or SDK README)
3. **Monitor usage** in the dashboard
4. **Read the full documentation** in each SDK's README

## Troubleshooting

### Enable Debug Mode

**TypeScript:**
```typescript
const client = new AIGateClient({
  projectId: 'your-project-id',
  debug: true  // Shows detailed logs
});
```

**Python:**
```python
client = AIGateClient(
    project_id="your-project-id",
    debug=True  # Shows detailed logs
)
```

### Check API Logs

Monitor the API in real-time:

```bash
cd luna-proxy-api
wrangler tail --env production
```

Then run your test and watch the logs.

### Verify Project Exists

Check your dashboard at https://www.ai-gate.dev/dashboard to confirm:
- Project is created
- OpenAI API key is stored
- Project ID is correct

## Support

If you encounter issues:

- 📚 Check the [SDK README](./README.md)
- 💬 Open an issue on GitHub
- 📧 Contact support@ai-gate.dev

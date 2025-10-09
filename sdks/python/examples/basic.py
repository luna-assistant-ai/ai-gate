"""
Basic Example: Create a session with AI Gate
"""

import os
from ai_gate import AIGateClient, AIGateError


def main():
    # Initialize the client with your project ID
    client = AIGateClient(
        project_id=os.getenv("AI_GATE_PROJECT_ID", "your-project-id"),
        debug=True
    )

    try:
        print("🚀 Creating OpenAI Realtime session...\n")

        # Create a session
        session = client.create_session(
            model="gpt-4o-realtime-preview-2024-10-01",
            voice="echo",
            temperature=0.7,
            instructions="You are a helpful and friendly assistant."
        )

        print("✅ Session created successfully!\n")
        print("📋 Session Details:")
        print(f"  - Session ID: {session['session_id']}")
        print(f"  - OpenAI Session: {session['id']}")
        print(f"  - Model: {session['metadata']['model']}")
        print(f"  - Voice: {session['metadata']['voice']}")
        print(f"  - TURN Server: {session['metadata']['turn_server']}")
        print(f"  - Created: {session['metadata']['created_at']}\n")

        if "client_secret" in session:
            print("🔐 Client Secret (for WebRTC):")
            print(f"  {session['client_secret']['value'][:20]}...")
            print()

        print("🌐 TURN Credentials:")
        for i, server in enumerate(session["turn_credentials"]["iceServers"]):
            print(f"  Server {i + 1}:")
            urls = server["urls"]
            if isinstance(urls, list):
                urls = ", ".join(urls)
            print(f"    URLs: {urls}")
            if "username" in server:
                print(f"    Username: {server['username']}")
        print()

    except AIGateError as error:
        print(f"❌ AI Gate Error: {error}")
        print(f"   Status Code: {error.status_code}")

        if error.status_code == 402:
            print("   💡 Your quota is exceeded. Please upgrade your plan.")
            if error.response:
                print(f"   Upgrade URL: {error.response.get('upgrade_url')}")

        elif error.status_code == 429:
            print("   💡 Rate limit exceeded. Please try again later.")

    except Exception as error:
        print(f"❌ Unexpected error: {error}")

    finally:
        client.close()


if __name__ == "__main__":
    main()

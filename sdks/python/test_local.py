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
                if error.response:
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

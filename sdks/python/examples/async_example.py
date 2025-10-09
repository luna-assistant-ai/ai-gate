"""
Async Example: Create multiple sessions concurrently
"""

import asyncio
import os
from ai_gate.client import AsyncAIGateClient, AIGateError


async def create_session_with_voice(client: AsyncAIGateClient, voice: str) -> None:
    """Create a session with a specific voice"""
    try:
        print(f"🎤 Creating session with voice: {voice}")

        session = await client.create_session(
            voice=voice,
            instructions=f"You are an assistant using the {voice} voice."
        )

        print(f"✅ Session created with {voice}: {session['session_id']}")

    except AIGateError as error:
        print(f"❌ Error creating session with {voice}: {error}")


async def main():
    """Main async function"""

    # Initialize async client
    async with AsyncAIGateClient(
        project_id=os.getenv("AI_GATE_PROJECT_ID", "your-project-id"),
        debug=True
    ) as client:

        print("🚀 Creating multiple sessions concurrently...\n")

        # Create multiple sessions concurrently with different voices
        voices = ["echo", "nova", "alloy"]

        tasks = [
            create_session_with_voice(client, voice)
            for voice in voices
        ]

        # Wait for all sessions to be created
        await asyncio.gather(*tasks)

        print("\n✅ All sessions created!")


if __name__ == "__main__":
    asyncio.run(main())

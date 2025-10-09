/**
 * Basic Example: Create a session with AI Gate
 */

import { AIGateClient, AIGateError } from '../src';

async function main() {
  // Initialize the client with your project ID
  const client = new AIGateClient({
    projectId: process.env.AI_GATE_PROJECT_ID || 'your-project-id',
    debug: true
  });

  try {
    console.log('🚀 Creating OpenAI Realtime session...\n');

    // Create a session
    const session = await client.createSession({
      model: 'gpt-4o-realtime-preview-2024-10-01',
      voice: 'echo',
      temperature: 0.7,
      instructions: 'You are a helpful and friendly assistant.'
    });

    console.log('✅ Session created successfully!\n');
    console.log('📋 Session Details:');
    console.log(`  - Session ID: ${session.session_id}`);
    console.log(`  - OpenAI Session: ${session.id}`);
    console.log(`  - Model: ${session.metadata.model}`);
    console.log(`  - Voice: ${session.metadata.voice}`);
    console.log(`  - TURN Server: ${session.metadata.turn_server}`);
    console.log(`  - Expires: ${new Date(session.expires_at * 1000).toLocaleString()}`);
    console.log(`  - Created: ${session.metadata.created_at}\n`);

    console.log('🔐 Client Secret (for WebRTC):');
    console.log(`  ${session.client_secret?.value.substring(0, 20)}...`);
    console.log(`  Expires: ${new Date((session.client_secret?.expires_at || 0) * 1000).toLocaleString()}\n`);

    console.log('🌐 TURN Credentials:');
    session.turn_credentials.iceServers.forEach((server, i) => {
      console.log(`  Server ${i + 1}:`);
      console.log(`    URLs: ${Array.isArray(server.urls) ? server.urls.join(', ') : server.urls}`);
      if (server.username) {
        console.log(`    Username: ${server.username}`);
      }
    });

  } catch (error) {
    if (error instanceof AIGateError) {
      console.error('❌ AI Gate Error:', error.message);
      console.error('   Status Code:', error.statusCode);

      if (error.statusCode === 402) {
        console.error('   💡 Your quota is exceeded. Please upgrade your plan.');
        console.error(`   Upgrade URL: ${(error.response as any)?.upgrade_url}`);
      } else if (error.statusCode === 429) {
        console.error('   💡 Rate limit exceeded. Please try again later.');
      }
    } else {
      console.error('❌ Unexpected error:', error);
    }
    process.exit(1);
  }
}

main();

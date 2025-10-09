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
        console.error('  ', (error.response as any)?.upgrade_url);
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

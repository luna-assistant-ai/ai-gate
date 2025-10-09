/**
 * WebRTC Example: Complete integration with OpenAI Realtime API
 *
 * This example shows how to:
 * 1. Create a session with AI Gate
 * 2. Setup WebRTC peer connection
 * 3. Connect to OpenAI Realtime API
 * 4. Send/receive events
 *
 * Note: This requires a WebRTC implementation (Node.js needs 'wrtc' package)
 */

import { AIGateClient, AIGateError } from '../src';

// For Node.js, you need to install 'wrtc' package:
// npm install wrtc
// import { RTCPeerConnection } from 'wrtc';

// For browsers, use the built-in RTCPeerConnection

async function main() {
  const client = new AIGateClient({
    projectId: process.env.AI_GATE_PROJECT_ID || 'your-project-id',
    debug: true
  });

  try {
    console.log('🚀 Creating session...\n');

    // Step 1: Create session
    const session = await client.createSession({
      voice: 'echo',
      instructions: 'You are a helpful assistant. Be concise in your responses.'
    });

    console.log('✅ Session created:', session.session_id);
    console.log('🔐 Client secret obtained\n');

    // Step 2: Setup WebRTC
    console.log('🌐 Setting up WebRTC connection...\n');

    // Note: In Node.js, you need to import RTCPeerConnection from 'wrtc'
    // In browsers, RTCPeerConnection is available globally
    const pc = new RTCPeerConnection({
      iceServers: session.turn_credentials.iceServers
    });

    // Create data channel for OpenAI events
    const dc = pc.createDataChannel('oai-events', {
      ordered: true
    });

    // Setup event handlers
    dc.onopen = () => {
      console.log('✅ Data channel opened! Connected to OpenAI Realtime API\n');

      // Send a conversation item
      const message = {
        type: 'conversation.item.create',
        item: {
          type: 'message',
          role: 'user',
          content: [{
            type: 'input_text',
            text: 'Hello! Can you hear me?'
          }]
        }
      };

      console.log('📤 Sending message to AI...');
      dc.send(JSON.stringify(message));

      // Trigger response
      dc.send(JSON.stringify({
        type: 'response.create'
      }));
    };

    dc.onmessage = (event: MessageEvent) => {
      const message = JSON.parse(event.data);
      console.log('📥 Received event:', message.type);

      // Handle specific events
      if (message.type === 'response.done') {
        console.log('✅ Response completed\n');

        // Close connection after response
        setTimeout(() => {
          dc.close();
          pc.close();
          console.log('👋 Connection closed');
        }, 1000);
      } else if (message.type === 'response.audio_transcript.delta') {
        process.stdout.write(message.delta);
      } else if (message.type === 'response.text.delta') {
        process.stdout.write(message.delta);
      } else if (message.type === 'error') {
        console.error('❌ OpenAI Error:', message.error);
      }
    };

    dc.onerror = (error: Event) => {
      console.error('❌ Data channel error:', error);
    };

    dc.onclose = () => {
      console.log('📡 Data channel closed');
    };

    // ICE candidate handling
    pc.onicecandidate = (event: RTCPeerConnectionIceEvent) => {
      if (event.candidate) {
        console.log('🧊 ICE candidate:', event.candidate.candidate.substring(0, 50) + '...');
      }
    };

    pc.oniceconnectionstatechange = () => {
      console.log('🔗 ICE connection state:', pc.iceConnectionState);
    };

    // Step 3: Create offer
    console.log('📝 Creating WebRTC offer...\n');
    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    // Step 4: Send offer to OpenAI
    console.log('📤 Sending offer to OpenAI...\n');
    const response = await fetch(
      `https://api.openai.com/v1/realtime?model=${session.model}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${session.client_secret?.value}`,
          'Content-Type': 'application/sdp'
        },
        body: offer.sdp
      }
    );

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`);
    }

    // Step 5: Set remote description
    const answerSdp = await response.text();
    const answer: RTCSessionDescriptionInit = {
      type: 'answer',
      sdp: answerSdp
    };

    await pc.setRemoteDescription(answer);
    console.log('✅ Remote description set. Waiting for connection...\n');

    // Keep the process alive for a while
    await new Promise(resolve => setTimeout(resolve, 30000));

  } catch (error) {
    if (error instanceof AIGateError) {
      console.error('❌ AI Gate Error:', error.message);
      console.error('   Status Code:', error.statusCode);
    } else {
      console.error('❌ Error:', error);
    }
    process.exit(1);
  }
}

main();

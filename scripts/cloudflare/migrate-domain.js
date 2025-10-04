#!/usr/bin/env node

const { execSync } = require('child_process');
const https = require('https');

const ACCOUNT_ID = '602a3ee367f65632af4cab4ca55b46e7';
const PROJECT_NAME = 'luna-proxy-web-frontend';
const WORKER_NAME = 'luna-proxy-web-frontend';
const DOMAIN = 'www.ai-gate.dev';

// Get Cloudflare API token from wrangler config
function getApiToken() {
  try {
    const fs = require('fs');
    const os = require('os');
    const path = require('path');

    // Try to read from wrangler config
    const configPath = path.join(os.homedir(), '.wrangler', 'config', 'default.toml');
    if (fs.existsSync(configPath)) {
      const content = fs.readFileSync(configPath, 'utf8');
      const match = content.match(/api_token\s*=\s*"([^"]+)"/);
      if (match) {
        return match[1];
      }
    }

    // Fallback: try environment variable
    if (process.env.CLOUDFLARE_API_TOKEN) {
      return process.env.CLOUDFLARE_API_TOKEN;
    }

    throw new Error('Could not find Cloudflare API token');
  } catch (err) {
    console.error('❌ Error getting API token:', err.message);
    console.log('\n💡 Please set CLOUDFLARE_API_TOKEN environment variable');
    process.exit(1);
  }
}

// Make API request
function apiRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const token = getApiToken();
    const options = {
      hostname: 'api.cloudflare.com',
      port: 443,
      path: path,
      method: method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const response = JSON.parse(body);
          if (response.success) {
            resolve(response);
          } else {
            reject(new Error(JSON.stringify(response.errors || response.messages)));
          }
        } catch (err) {
          reject(new Error(`Parse error: ${body}`));
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

async function main() {
  console.log('🚀 Migration du domaine www.ai-gate.dev vers Worker\n');

  // Step 1: List Pages domains
  console.log('1️⃣ Listing Pages project domains...');
  try {
    const response = await apiRequest('GET', `/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}`);
    console.log('   ✅ Pages project found');
    console.log('   Domains:', response.result.domains || []);

    if (response.result.domains && response.result.domains.includes(DOMAIN)) {
      console.log(`   ⚠️  ${DOMAIN} is currently on Pages project`);
    }
  } catch (err) {
    console.error('   ❌ Error:', err.message);
  }

  // Step 2: Remove from Pages
  console.log('\n2️⃣ Removing www.ai-gate.dev from Pages project...');
  try {
    const response = await apiRequest('DELETE', `/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/domains/${DOMAIN}`);
    console.log('   ✅ Domain removed from Pages project');
  } catch (err) {
    console.error('   ⚠️  Error removing domain:', err.message);
    console.log('   (This might be OK if domain was already removed)');
  }

  // Step 3: Add to Worker
  console.log('\n3️⃣ Adding www.ai-gate.dev to Worker...');
  try {
    const response = await apiRequest('PUT', `/client/v4/accounts/${ACCOUNT_ID}/workers/domains/records/${DOMAIN}`, {
      environment: 'production',
      service: WORKER_NAME,
      zone_name: 'ai-gate.dev'
    });
    console.log('   ✅ Domain added to Worker');
  } catch (err) {
    console.error('   ❌ Error adding domain to Worker:', err.message);
    console.log('\n   Trying alternative API endpoint...');

    try {
      const response = await apiRequest('POST', `/client/v4/accounts/${ACCOUNT_ID}/workers/scripts/${WORKER_NAME}/routes`, {
        pattern: DOMAIN,
        zone_name: 'ai-gate.dev'
      });
      console.log('   ✅ Route added to Worker');
    } catch (err2) {
      console.error('   ❌ Error with alternative endpoint:', err2.message);
    }
  }

  // Step 4: Verify
  console.log('\n4️⃣ Verifying configuration...');
  console.log('   Testing https://www.ai-gate.dev ...');

  setTimeout(() => {
    try {
      execSync('curl -I https://www.ai-gate.dev', { stdio: 'inherit' });
      console.log('\n✅ Migration complete! Test the site at https://www.ai-gate.dev');
    } catch (err) {
      console.log('\n⚠️  Site not yet accessible. DNS propagation may take a few minutes.');
    }
  }, 3000);
}

main().catch(err => {
  console.error('\n❌ Migration failed:', err.message);
  process.exit(1);
});

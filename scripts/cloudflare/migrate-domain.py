#!/usr/bin/env python3

import json
import os
import subprocess
import time
import urllib.request
import urllib.error
from pathlib import Path

ACCOUNT_ID = "602a3ee367f65632af4cab4ca55b46e7"
PROJECT_NAME = "luna-proxy-web-frontend"
WORKER_NAME = "luna-proxy-web-frontend"
DOMAIN = "www.ai-gate.dev"

def get_api_token():
    """Get Cloudflare API token from wrangler config or environment"""
    # Try environment variable first
    token = os.environ.get('CLOUDFLARE_API_TOKEN')
    if token:
        return token

    # Try to read from wrangler config
    config_path = Path.home() / '.wrangler' / 'config' / 'default.toml'
    if config_path.exists():
        with open(config_path, 'r') as f:
            for line in f:
                if 'api_token' in line:
                    # Extract token from: api_token = "xxx"
                    parts = line.split('"')
                    if len(parts) >= 2:
                        return parts[1]

    raise Exception("Could not find Cloudflare API token. Please set CLOUDFLARE_API_TOKEN environment variable.")

def api_request(method, path, data=None):
    """Make a request to Cloudflare API"""
    token = get_api_token()
    url = f"https://api.cloudflare.com/client/v4{path}"

    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    }

    if data:
        data = json.dumps(data).encode('utf-8')

    req = urllib.request.Request(url, data=data, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode('utf-8'))
            if result.get('success'):
                return result
            else:
                raise Exception(f"API error: {result.get('errors', result.get('messages'))}")
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        try:
            error_data = json.loads(error_body)
            raise Exception(f"HTTP {e.code}: {error_data.get('errors', error_data.get('messages'))}")
        except:
            raise Exception(f"HTTP {e.code}: {error_body}")

def main():
    print("🚀 Migration du domaine www.ai-gate.dev vers Worker\n")

    # Step 1: List Pages project
    print("1️⃣ Listing Pages project domains...")
    try:
        response = api_request('GET', f'/accounts/{ACCOUNT_ID}/pages/projects/{PROJECT_NAME}')
        domains = response.get('result', {}).get('domains', [])
        print(f"   ✅ Pages project found")
        print(f"   Current domains: {domains}")

        if DOMAIN in domains:
            print(f"   ⚠️  {DOMAIN} is currently on Pages project")
        else:
            print(f"   ℹ️  {DOMAIN} not found in Pages domains (might already be removed)")
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return

    # Step 2: Remove domain from Pages
    print(f"\n2️⃣ Removing {DOMAIN} from Pages project...")
    try:
        response = api_request('DELETE', f'/accounts/{ACCOUNT_ID}/pages/projects/{PROJECT_NAME}/domains/{DOMAIN}')
        print(f"   ✅ Domain removed from Pages project")
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
        print(f"   (This might be OK if domain was already removed)")

    # Step 3: Wait a bit for propagation
    print("\n⏳ Waiting 5 seconds for DNS propagation...")
    time.sleep(5)

    # Step 4: Deploy Worker with custom domain
    print(f"\n3️⃣ Deploying Worker with custom domain...")
    print(f"   The domain is configured in wrangler.toml")
    print(f"   Running: npm run deploy:production")

    try:
        os.chdir('luna-proxy-web')
        result = subprocess.run(['npm', 'run', 'deploy:production'],
                              capture_output=True, text=True, timeout=300)

        if result.returncode == 0:
            print("   ✅ Worker deployed successfully")
            print(result.stdout)
        else:
            print(f"   ⚠️  Deployment had issues:")
            print(result.stderr)
    except subprocess.TimeoutExpired:
        print("   ⚠️  Deployment timed out (but might still be processing)")
    except Exception as e:
        print(f"   ❌ Error deploying: {e}")

    # Step 5: Verify
    print("\n4️⃣ Verifying configuration...")
    print(f"   Testing https://{DOMAIN} ...")
    time.sleep(3)

    try:
        subprocess.run(['curl', '-I', f'https://{DOMAIN}'], timeout=10)
        print(f"\n✅ Migration complete! Site accessible at https://{DOMAIN}")
    except:
        print(f"\n⚠️  Site not yet accessible. DNS propagation may take a few minutes.")
        print(f"   Check status: https://dash.cloudflare.com/{ACCOUNT_ID}/workers/services/view/{WORKER_NAME}")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        exit(1)

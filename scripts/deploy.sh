#!/bin/bash
# Luna Proxy Deployment Script
# Usage: ./deploy.sh [staging|production] [api|web|all]

set -e  # Exit on error

ENV=${1:-staging}
TARGET=${2:-all}

echo "🚀 Luna Proxy Deployment"
echo "Environment: $ENV"
echo "Target: $TARGET"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

info() {
    echo -e "ℹ  $1"
}

# Validation
if [[ "$ENV" != "staging" && "$ENV" != "production" ]]; then
    error "Environment must be 'staging' or 'production'"
fi

if [[ "$TARGET" != "api" && "$TARGET" != "web" && "$TARGET" != "all" ]]; then
    error "Target must be 'api', 'web', or 'all'"
fi

# Pre-deployment checks
info "Running pre-deployment checks..."

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    error "wrangler CLI not found. Install with: npm install -g wrangler"
fi

# Check wrangler authentication
if ! wrangler whoami &> /dev/null; then
    error "Not logged in to Cloudflare. Run: wrangler login"
fi

success "Pre-deployment checks passed"
echo ""

# Deploy API
deploy_api() {
    local env=$1
    info "Deploying luna-proxy-api to $env..."

    cd luna-proxy-api || error "luna-proxy-api directory not found"

    # Verify secrets
    if [[ "$env" == "production" ]]; then
        info "Verifying production secrets..."
        if ! wrangler secret list | grep -q "ADMIN_API_KEY"; then
            warning "ADMIN_API_KEY not found in secrets"
        fi
        wrangler deploy
    else
        info "Verifying staging secrets..."
        if ! wrangler secret list --env staging | grep -q "ADMIN_API_KEY"; then
            warning "ADMIN_API_KEY not found in staging secrets"
        fi
        wrangler deploy --env staging
    fi

    cd ..
    success "API deployed successfully"
}

# Deploy Web
deploy_web() {
    local env=$1
    info "Deploying luna-proxy-web to $env..."

    cd luna-proxy-web || error "luna-proxy-web directory not found"

    # Build
    info "Building Next.js application..."
    npm run build:cf || error "Build failed"

    # Verify D1 database
    info "Verifying D1 database..."
    if ! wrangler d1 list | grep -q "luna-proxy-users"; then
        warning "D1 database 'luna-proxy-users' not found"
    fi

    # Deploy
    if [[ "$env" == "production" ]]; then
        info "Verifying production secrets..."
        if ! wrangler secret list | grep -q "ADMIN_API_KEY"; then
            warning "ADMIN_API_KEY not found in secrets"
        fi
        if ! wrangler secret list | grep -q "AUTH_SECRET"; then
            warning "AUTH_SECRET not found in secrets"
        fi

        wrangler deploy --name luna-proxy-web-frontend
    else
        info "Verifying staging secrets..."
        if ! wrangler secret list --env staging | grep -q "ADMIN_API_KEY"; then
            warning "ADMIN_API_KEY not found in staging secrets"
        fi

        wrangler deploy --env staging
    fi

    cd ..
    success "Web deployed successfully"
}

# Execute deployment
echo "═══════════════════════════════════"
echo "Starting deployment..."
echo "═══════════════════════════════════"
echo ""

if [[ "$TARGET" == "api" ]] || [[ "$TARGET" == "all" ]]; then
    deploy_api "$ENV"
    echo ""
fi

if [[ "$TARGET" == "web" ]] || [[ "$TARGET" == "all" ]]; then
    deploy_web "$ENV"
    echo ""
fi

# Post-deployment
echo "═══════════════════════════════════"
echo "Post-deployment tasks"
echo "═══════════════════════════════════"
echo ""

info "Waiting 30 seconds for propagation..."
sleep 30

# Health checks
if [[ "$ENV" == "production" ]]; then
    info "Running health checks..."

    if [[ "$TARGET" == "api" ]] || [[ "$TARGET" == "all" ]]; then
        API_HEALTH=$(curl -s https://api.ai-gate.dev/health | jq -r '.status' 2>/dev/null || echo "error")
        if [[ "$API_HEALTH" == "healthy" ]]; then
            success "API health check passed"
        else
            warning "API health check failed"
        fi
    fi

    if [[ "$TARGET" == "web" ]] || [[ "$TARGET" == "all" ]]; then
        WEB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://www.ai-gate.dev)
        if [[ "$WEB_STATUS" == "200" ]]; then
            success "Web health check passed"
        else
            warning "Web health check returned status $WEB_STATUS"
        fi
    fi
else
    info "Staging deployment - skipping health checks"
fi

echo ""
echo "═══════════════════════════════════"
success "Deployment completed!"
echo "═══════════════════════════════════"
echo ""

if [[ "$ENV" == "production" ]]; then
    info "🌐 Production URLs:"
    echo "   Web: https://www.ai-gate.dev"
    echo "   API: https://api.ai-gate.dev"
    echo ""
    warning "Don't forget to:"
    echo "   1. Hard refresh your browser (Cmd+Shift+R / Ctrl+Shift+R)"
    echo "   2. Test signup/login"
    echo "   3. Test project creation"
    echo "   4. Monitor logs: wrangler tail luna-proxy-web-frontend"
else
    info "🧪 Staging URLs:"
    echo "   Web: https://luna-proxy-web-frontend-staging.joffrey-vanasten.workers.dev"
    echo "   API: https://staging.ai-gate.dev"
fi

echo ""
info "View logs:"
if [[ "$TARGET" == "api" ]] || [[ "$TARGET" == "all" ]]; then
    echo "   wrangler tail luna-proxy-api"
fi
if [[ "$TARGET" == "web" ]] || [[ "$TARGET" == "all" ]]; then
    echo "   wrangler tail luna-proxy-web-frontend"
fi

echo ""

# TODO: Transfer Dashboard Repository

## Action Required

The `luna-proxy-dashboard` repository needs to be transferred to the `luna-assistant-ai` organization.

### Current State
- Owner: `CosteGieF`
- URL: https://github.com/CosteGieF/luna-proxy-dashboard

### Target State
- Owner: `luna-assistant-ai`
- URL: https://github.com/luna-assistant-ai/luna-proxy-dashboard

### Steps to Transfer

1. **Go to Repository Settings**
   - Visit: https://github.com/CosteGieF/luna-proxy-dashboard/settings

2. **Transfer Ownership**
   - Scroll to "Danger Zone"
   - Click "Transfer ownership"
   - Enter: `luna-assistant-ai`
   - Confirm transfer

3. **Update Submodule URL**
   ```bash
   cd ai-gate
   git submodule set-url luna-proxy-dashboard https://github.com/luna-assistant-ai/luna-proxy-dashboard.git
   git add .gitmodules
   git commit -m "chore: update dashboard submodule URL after transfer"
   git push
   ```

### Why This Matters

All AI Gate repositories should be under the `luna-assistant-ai` organization for:
- Centralized management
- Consistent permissions
- Professional organization structure
- Easier collaboration

---

**Created**: 2025-10-04
**Status**: Pending transfer

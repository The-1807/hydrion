#!/bin/bash

# deploy_firebase.sh - Deploy Firebase for Hydrion.ai
# Usage: ./scripts/deploy_firebase.sh
# Prerequisites: firebase CLI logged in (firebase login)
# Author: Hydrion.ai Team
# Version: 1.0

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Deploy Functions
log "Deploying Firebase Functions..."
cd cloud/functions && firebase deploy --only functions && cd ../..

# Deploy Hosting (for web)
log "Deploying Firebase Hosting..."
firebase deploy --only hosting

log "Firebase deployment complete for Hydrion.ai."
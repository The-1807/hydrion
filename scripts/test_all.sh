#!/bin/bash

# test_all.sh - Run all tests for Hydrion.ai
# Usage: ./scripts/test_all.sh
# Prerequisites: Flutter, Gradle
# Author: Hydrion.ai Team
# Version: 1.0

set -euo pipefail

LOG_FILE="logs/test_all.log"
echo "$(date): Starting tests..." | tee -a "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Flutter tests
log "Running Flutter tests..."
cd app && flutter test && cd ..

# KMP tests
log "Running KMP tests..."
cd core && ./gradlew test && cd ..

# Python tests (AI models)
log "Running Python tests..."
pytest models/training/  # Assume pytest setup in requirements.txt

# Integration/E2E (via Flutter)
log "Running integration tests..."
flutter test integration_tests/

log "All tests passed! Check $LOG_FILE for details."
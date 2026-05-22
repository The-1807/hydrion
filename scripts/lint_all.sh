#!/bin/bash

# lint_all.sh - Lint all code in Hydrion.ai project
# Usage: ./scripts/lint_all.sh
# Prerequisites: dartanalyzer, ktlint, pylint installed
# Author: Hydrion.ai Team
# Version: 1.0

set -euo pipefail

LOG_FILE="logs/lint_all.log"
echo "$(date): Starting linting..." | tee -a "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Dart lint (Flutter)
log "Linting Flutter code..."
cd app && dart analyze . && cd ..

# Kotlin lint (KMP)
log "Linting KMP core..."
cd core && ./gradlew ktlintCheck && cd ..

# Python lint
log "Linting Python code..."
pylint models/training/*.py

log "Linting complete! Check $LOG_FILE for issues."
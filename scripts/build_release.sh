#!/bin/bash

# build_release.sh - Build release artifacts for Hydrion.ai
# Usage: ./scripts/build_release.sh [platform] (e.g., android, ios, web, all)
# Prerequisites: Flutter, Xcode (for iOS), Android SDK
# Author: Hydrion.ai Team
# Version: 1.0

set -euo pipefail

PLATFORM=${1:-all}
BUILD_DIR="build/releases"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

mkdir -p "$BUILD_DIR"

case $PLATFORM in
    android)
        log "Building Android APK..."
        flutter build apk --release -t lib/main.dart
        cp build/app/outputs/flutter-apk/app-release.apk "$BUILD_DIR/hydrion-android.apk"
        ;;
    ios)
        log "Building iOS IPA..."
        flutter build ios --release -t lib/main.dart
        # Use Xcode to archive (manual step or integrate xcodebuild)
        log "iOS build complete; archive in Xcode."
        ;;
    web)
        log "Building Web..."
        flutter build web --release -t lib/main.dart
        cp -r build/web "$BUILD_DIR/hydrion-web"
        ;;
    all)
        $0 android
        $0 ios
        $0 web
        ;;
    *)
        log "ERROR: Invalid platform. Use android, ios, web, or all."
        exit 1
        ;;
esac

log "Build complete in $BUILD_DIR."
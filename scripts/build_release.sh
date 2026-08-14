#!/bin/bash

# build_release.sh - Build validated release artifacts for Hydrion
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

require_android_signing() {
    if [ ! -f android/key.properties ]; then
        log "ERROR: android/key.properties is required for a production release."
        exit 1
    fi
    if [ -z "${HYDRION_ANDROID_SIGNING_CERT_SHA256:-}" ]; then
        log "ERROR: HYDRION_ANDROID_SIGNING_CERT_SHA256 is required."
        exit 1
    fi
}

version="$(sed -n 's/^version: \([^+]*\)+\(.*\)$/\1/p' pubspec.yaml)"
build="$(sed -n 's/^version: \([^+]*\)+\(.*\)$/\2/p' pubspec.yaml)"
git_sha="$(git rev-parse HEAD)"
test -n "$version" && test -n "$build" && test -n "$git_sha"

mkdir -p "$BUILD_DIR"

case $PLATFORM in
    android)
        require_android_signing
        log "Building and validating production Android APK..."
        flutter build apk --release -t lib/main.dart
        dart run tool/validate_android_release.dart \
            --apk build/app/outputs/flutter-apk/app-release.apk \
            --output-dir "$BUILD_DIR" \
            --signing-kind production \
            --expected-certificate-sha256 "$HYDRION_ANDROID_SIGNING_CERT_SHA256" \
            --git-sha "$git_sha"
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
        tar -C build/web -czf \
            "$BUILD_DIR/hydrion-${version}-${build}-web-release.tar.gz" .
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

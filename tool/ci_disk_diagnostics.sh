#!/usr/bin/env bash
set -euo pipefail

phase="${1:-unspecified}"
echo "::group::Disk and inode diagnostics: ${phase}"
df -h /
df -i /

report_size() {
  local label="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    printf '%s: ' "$label"
    timeout 20s du -sh "$path" 2>/dev/null || echo "size unavailable or timed out"
  else
    echo "$label: not present"
  fi
}

report_size "Gradle home" "${HOME}/.gradle"
report_size "Gradle transforms" "${HOME}/.gradle/caches/8.12/transforms"
if [[ -n "${PUB_CACHE:-}" ]]; then
  report_size "Pub cache" "$PUB_CACHE"
else
  report_size "Pub cache" "${HOME}/.pub-cache"
fi
if [[ -n "${ANDROID_HOME:-}" ]]; then
  report_size "Android SDK" "$ANDROID_HOME"
elif [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
  report_size "Android SDK" "$ANDROID_SDK_ROOT"
else
  echo "Android SDK: path not exported"
fi
report_size "Workspace" "$GITHUB_WORKSPACE"
report_size "Flutter build output" "$GITHUB_WORKSPACE/build"
report_size "Android build output" "$GITHUB_WORKSPACE/build/app/outputs"
report_size "Project Gradle state" "$GITHUB_WORKSPACE/android/.gradle"

echo "Largest relevant workspace entries:"
timeout 20s du -x -d 2 -h "$GITHUB_WORKSPACE" 2>/dev/null |
  sort -h | tail -n 15 || true
echo "Largest Gradle cache entries:"
if [[ -d "${HOME}/.gradle" ]]; then
  timeout 20s du -x -d 2 -h "${HOME}/.gradle" 2>/dev/null |
    sort -h | tail -n 15 || true
fi
echo "::endgroup::"

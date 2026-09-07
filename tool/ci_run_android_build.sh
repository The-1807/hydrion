#!/usr/bin/env bash
set -uo pipefail

mode="${1:-}"
case "$mode" in
  debug|release|appbundle) ;;
  *)
    echo "usage: $0 <debug|release|appbundle>" >&2
    exit 64
    ;;
esac

artifact_root="${CI_ARTIFACTS_DIRECTORY:-ci-artifacts}/android-${mode}"
mkdir -p "$artifact_root"
build_log="$artifact_root/flutter-build-${mode}.log"
phase_log="$artifact_root/build-phase-summary.txt"
heartbeat_log="$artifact_root/build-heartbeats.txt"
script_start_utc="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
build_start_epoch=""
build_start_utc=""
build_pid=""
monitor_pid=""

stop_monitor() {
  if [[ -n "$monitor_pid" ]] && kill -0 "$monitor_pid" 2>/dev/null; then
    kill "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true
  fi
}

record_heartbeat() {
  local now elapsed
  now="$(date +%s)"
  elapsed=$((now - build_start_epoch))
  {
    echo "timestamp_utc=$(date -u +'%Y-%m-%dT%H:%M:%SZ') elapsed_seconds=${elapsed}"
    df -h /
    df -i /
    echo "Active build processes:"
    if ! ps -eo pid,ppid,etime,%cpu,%mem,rss,comm --sort=-rss 2>/dev/null |
      awk 'NR == 1 || $8 ~ /^(java|dart|flutter|gradle)$/ {print}' |
      head -n 20; then
      echo "Process snapshot unavailable on this host."
    fi
    printf 'workspace_size=' 
    timeout 8s du -sh "${GITHUB_WORKSPACE:-.}" 2>/dev/null || echo "unavailable"
    printf 'build_size=' 
    timeout 8s du -sh "${GITHUB_WORKSPACE:-.}/build" 2>/dev/null || echo "unavailable"
    printf 'project_gradle_size=' 
    timeout 8s du -sh "${GITHUB_WORKSPACE:-.}/android/.gradle" 2>/dev/null || echo "unavailable"
    echo
  } | tee -a "$heartbeat_log"
}

monitor_build() {
  while kill -0 "$build_pid" 2>/dev/null; do
    sleep 60
    kill -0 "$build_pid" 2>/dev/null || break
    record_heartbeat
  done
}

trap stop_monitor EXIT
trap 'stop_monitor; exit 130' INT
trap 'stop_monitor; exit 143' TERM

echo "::notice::Android ${mode} build preparation started at ${script_start_utc}."
if ! timeout 1m bash tool/ci_disk_diagnostics.sh "before Android ${mode} build"; then
  echo "::warning::Pre-build disk diagnostics failed or exceeded one minute."
fi

build_start_epoch="$(date +%s)"
build_start_utc="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "::notice::Android ${mode} compilation started at ${build_start_utc}."

set +e
if [[ "$mode" == "appbundle" ]]; then
  build_command=(flutter build appbundle --release --verbose)
else
  build_command=(flutter build apk "--${mode}" --verbose)
fi
"${build_command[@]}" > >(tee "$build_log") 2>&1 &
build_pid=$!
monitor_build &
monitor_pid=$!
wait "$build_pid"
exit_code=$?
set -e
stop_monitor

end_epoch="$(date +%s)"
end_utc="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
duration=$((end_epoch - build_start_epoch))

{
  echo "mode=${mode}"
  echo "preparation_start_utc=${script_start_utc}"
  echo "build_start_utc=${build_start_utc}"
  echo "end_utc=${end_utc}"
  echo "duration_seconds=${duration}"
  echo "exit_code=${exit_code}"
  echo
  echo "Last Android/Gradle phase lines:"
  grep -E 'Running Gradle task|Gradle task|> Task |:app:|Built build/' "$build_log" |
    tail -n 100 || true
} | tee "$phase_log"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### Android ${mode} build"
    echo "- Preparation started: ${script_start_utc}"
    echo "- Compilation started: ${build_start_utc}"
    echo "- Ended: ${end_utc}"
    echo "- Duration: ${duration} seconds"
    echo "- Exit code: ${exit_code}"
  } >> "$GITHUB_STEP_SUMMARY"
fi

if ! timeout 1m bash tool/ci_disk_diagnostics.sh "after Android ${mode} build"; then
  echo "::warning::Post-build disk diagnostics failed or exceeded one minute."
fi
echo "::notice::Android ${mode} build ended at ${end_utc}; duration=${duration}s; exit_code=${exit_code}."
exit "$exit_code"

#!/usr/bin/env bash
#
# dev_setup.sh - Hydrion Rust-Core + Flutter + Python Dev Environment
# Version: 2.0 (October 2025)
#
# Features:
#   • Rust + Cargo + flutter_rust_bridge
#   • SQLCipher + TFLite + btleplug
#   • Flutter SDK (pinned stable)
#   • Python ML venv
#   • Android NDK + CMake
#   • SBOM, audit, lint
#   • Zero Gradle/KMP
#
# Usage:
#   ./scripts/dev_setup.sh [--skip-rust] [--skip-flutter] [--quiet]
#

set -euo pipefail
IFS=$'\n\t'

# ---------------------------- Config ---------------------------------
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/dev_setup.log"
BIN_DIR="$HOME/.local/bin"
RUSTUP_DIR="$HOME/.rustup"
CARGO_DIR="$HOME/.cargo"
FLUTTER_DIR="$HOME/.hydriontools/flutter"
PY_ENV_DIR="$PROJECT_ROOT/models/training/.venv"
ANDROID_SDK_DIR="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
NDK_VERSION="26.1.10909125"
CMAKE_VERSION="3.28.1"

# Flags
SKIP_RUST=false
SKIP_FLUTTER=false
QUIET=false

# ---------------------------- Args -----------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-rust)    SKIP_RUST=true; shift ;;
    --skip-flutter) SKIP_FLUTTER=true; shift ;;
    --quiet)        QUIET=true; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# --------------------------- Logging ---------------------------------
mkdir -p "$LOG_DIR" "$BIN_DIR"
touch "$LOG_FILE"

ts() { date '+%Y-%m-%d %H:%M:%S'; }
c() { printf "\033[%sm%s\033[0m" "$1" "$2"; }
log() {
  local lvl="$1"; shift; local msg="$*"; local line="[$(ts)] [$lvl] $msg"
  echo "$line" >> "$LOG_FILE"
  $QUIET || case "$lvl" in
    INFO)  echo "$(c 32 "$line")" ;;
    WARN)  echo "$(c 33 "$line")" ;;
    ERROR) echo "$(c 31 "$line")" ;;
    *)     echo "$line" ;;
  esac
}

trap 'log ERROR "Setup failed at line $LINENO. See $LOG_FILE"' ERR
log INFO "Starting Hydrion dev setup (Rust-First) in $PROJECT_ROOT"

# ------------------------- Sanity ---------------------------------
[[ -d "$PROJECT_ROOT/core" ]] || { log ERROR "Missing core/ — run from repo root"; exit 1; }
for cmd in git curl unzip tar; do command -v "$cmd" &>/dev/null || { log ERROR "Missing: $cmd"; exit 1; }; done

OS="$(uname -s)"; ARCH="$(uname -m)"
log INFO "Detected: $OS $ARCH"

# ------------------------ Helpers ---------------------------------
need_cmd() { command -v "$1" &>/dev/null || { log ERROR "Missing: $1"; return 1; }; }
ensure_dir() { mkdir -p "$1"; }
add_to_path() { [[ ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"; }
persist_path() { grep -qxF "$1" "$HOME/.bashrc" "$HOME/.zshrc" 2>/dev/null || echo "$1" >> "$HOME/.$( [[ -n "${ZSH_VERSION:-}" ]] && echo zshrc || echo bashrc)"; }

# ----------------------- 1. RUST + CARGO --------------------------
setup_rust() {
  $SKIP_RUST && { log INFO "Skipping Rust (requested)"; return; }

  if [[ -d "$CARGO_DIR" ]]; then
    log INFO "Rust/Cargo found"
  else
    log INFO "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path >>"$LOG_FILE" 2>&1
  fi

  # Source cargo env
  export PATH="$CARGO_DIR/bin:$PATH"
  . "$CARGO_DIR/env" 2>/dev/null || true

  need_cmd rustc || { log ERROR "rustc not in PATH"; exit 1; }
  need_cmd cargo || { log ERROR "cargo not in PATH"; exit 1; }

  log INFO "Rust $(rustc --version)"
  rustup default stable
  rustup target add aarch64-apple-ios x86_64-apple-ios || true
  rustup target add aarch64-linux-android armv7-linux-androideabi || true

  # Core tools
  cargo install flutter_rust_bridge_codegen --locked >>"$LOG_FILE" 2>&1 || log WARN "FRB codegen failed"
  cargo install cargo-audit cargo-deny cargo-outdated cbindgen >>"$LOG_FILE" 2>&1

  persist_path "export PATH=\"\$HOME/.cargo/bin:\$PATH\""
  log INFO "Rust toolchain ready"
}

# ----------------------- 2. SQLCIPHER -----------------------------
setup_sqlcipher() {
  log INFO "Setting up SQLCipher..."

  if pkg-config --exists sqlcipher 2>/dev/null; then
    log INFO "SQLCipher found via pkg-config"
    return
  fi

  case "$OS" in
    Darwin)
      brew install sqlcipher || log WARN "SQLCipher install failed"
      ;;
    Linux)
      sudo apt-get update
      sudo apt-get install -y libsqlcipher-dev || log WARN "libsqlcipher-dev failed"
      ;;
  esac

  export SQLCIPHER_LIB_DIR=$(pkg-config --libs-only-L sqlcipher 2>/dev/null | sed 's/-L//g' || echo "")
  export SQLCIPHER_INCLUDE_DIR=$(pkg-config --cflags-only-I sqlcipher 2>/dev/null | sed 's/-I//g' || echo "")
  log INFO "SQLCipher ready"
}

# ----------------------- 3. TFLITE --------------------------------
setup_tflite() {
  log INFO "Downloading TFLite runtime..."
  local tflite_dir="$HOME/.hydriontools/tflite"
  mkdir -p "$tflite_dir/lib" "$tflite_dir/include"

  if [[ ! -f "$tflite_dir/lib/libtensorflowlite_c.so" ]]; then
    curl -L https://github.com/tensorflow/tensorflow/releases/download/v2.15.0/libtensorflowlite_c-linux-x86_64-2.15.0.tar.gz \
      | tar -xz -C "$tflite_dir" --strip-components=1
  fi

  export TFLITE_LIB_DIR="$tflite_dir/lib"
  export TFLITE_INCLUDE_DIR="$tflite_dir/include"
  log INFO "TFLite ready at $tflite_dir"
}

# ----------------------- 4. FLUTTER -------------------------------
setup_flutter() {
  $SKIP_FLUTTER && { log INFO "Skipping Flutter"; return; }

  if command -v flutter >/dev/null; then
    log INFO "Flutter $(flutter --version | head -1)"
  else
    log INFO "Installing Flutter..."
    mkdir -p "$(dirname "$FLUTTER_DIR")"
    local url=""
    case "$OS-$ARCH" in
      Darwin-arm64)  url="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.3-stable.zip" ;;
      Darwin-x86_64) url="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.3-stable.zip" ;;
      *)             url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz" ;;
    esac

    curl -fsSL "$url" -o /tmp/flutter.archive
    if [[ "$url" == *.zip ]]; then
      unzip -q /tmp/flutter.archive -d "$(dirname "$FLUTTER_DIR")"
    else
      tar -xf /tmp/flutter.archive -C "$(dirname "$FLUTTER_DIR")"
    fi
  fi

  add_to_path "$FLUTTER_DIR/bin"
  persist_path "export PATH=\"$FLUTTER_DIR/bin:\$PATH\""
  flutter config --no-analytics
  flutter doctor --android-licenses --no-version-check || true
  log INFO "Flutter ready"
}

# ----------------------- 5. ANDROID NDK + CMAKE -------------------
setup_android_ndk() {
  [[ -z "$ANDROID_SDK_DIR" || ! -d "$ANDROID_SDK_DIR" ]] && return

  local ndk_path="$ANDROID_SDK_DIR/ndk/$NDK_VERSION"
  if [[ ! -d "$ndk_path" ]]; then
    log INFO "Installing NDK $NDK_VERSION..."
    yes | sdkmanager "ndk;$NDK_VERSION" >>"$LOG_FILE" 2>&1 || true
  fi

  export ANDROID_NDK_HOME="$ndk_path"
  persist_path "export ANDROID_NDK_HOME=\"$ndk_path\""

  # CMake
  if ! command -v cmake >/dev/null; then
    log INFO "Installing CMake..."
    case "$OS" in
      Darwin) brew install cmake ;;
      Linux) sudo apt-get install -y cmake ;;
    esac
  fi
}

# ----------------------- 6. PYTHON VENV ---------------------------
setup_python() {
  log INFO "Setting up Python ML venv..."
  need_cmd python3
  python3 -m venv "$PY_ENV_DIR"
  # shellcheck source=/dev/null
  source "$PY_ENV_DIR/bin/activate"
  pip install --upgrade pip
  pip install -r "$PROJECT_ROOT/models/training/requirements.txt" >>"$LOG_FILE" 2>&1
  deactivate
  log INFO "ML venv ready at $PY_ENV_DIR"
}

# ----------------------- 7. .ENV ----------------------------------
setup_env() {
  [[ ! -f "$PROJECT_ROOT/.env" ]] && cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env" && log INFO ".env created"
}

# ----------------------- 8. FINAL CHECKS --------------------------
final_checks() {
  log INFO "Running final checks..."
  pushd "$PROJECT_ROOT/core" >/dev/null
  cargo check --workspace >>"$LOG_FILE" 2>&1 || log WARN "cargo check failed"
  popd >/dev/null

  pushd "$PROJECT_ROOT/app" >/dev/null
  flutter pub get >>"$LOG_FILE" 2>&1
  popd >/dev/null

  log INFO "Generating FRB bindings..."
  flutter_rust_bridge_codegen --rust-input core/crates/hydrion-ffi/src/frb_api.rs \
    --dart-output app/lib/ffi/core_bridge.dart --c-output core/crates/hydrion-ffi/bindings/c/core_bridge.h || log WARN "FRB failed"
}

# ----------------------- RUN --------------------------------------
log INFO "=== HYDRION DEV SETUP START ==="

setup_rust
setup_sqlcipher
setup_tflite
setup_flutter
setup_android_ndk
setup_python
setup_env
final_checks

# ----------------------- SUCCESS ----------------------------------
log INFO "Hydrion dev environment READY!"
$QUIET || cat <<'EOF'

   ██████╗  █████╗  ██╗   ██╗███████╗██████╗ 
   ██╔══██╗██╔══██╗██║   ██║██╔════╝██╔══██╗
   ██████╔╝███████║██║   ██║█████╗  ██║  ██║
   ██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║  ██║
   ██║  ██║██║  ██║ ╚████╔╝ ███████╗██████╔╝
   ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═════╝ 

   Next steps:
     • source ~/.bashrc  (or open new terminal)
     • flutter doctor
     • cargo test --workspace
     • ./scripts/gen_frb_bindings.sh
     • Edit .env with API keys

   Log: logs/dev_setup.log
EOF
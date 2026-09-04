#!/bin/sh
# haql-rs installer — rustup/uv style (public releases repo)
# Usage: curl -sSL https://raw.githubusercontent.com/No1MLEngineer/haql-releases/master/install.sh | sh
set -eu

REPO="No1MLEngineer/haql-releases"
BIN_NAME="haql-rs"
INSTALL_DIR="${HAQL_INSTALL_DIR:-$HOME/.local/bin}"
FALLBACK_DIR="/usr/local/bin"

die() { echo "error: $*" >&2; exit 1; }
info() { echo "info: $*" >&2; }

OS="$(uname -s 2>/dev/null || echo unknown)"
ARCH="$(uname -m 2>/dev/null || echo unknown)"
case "$OS" in
  Linux) OS="linux" ;;
  Darwin) OS="darwin" ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT) OS="windows" ;;
  *) die "unsupported OS: $OS (supported: Linux, macOS)" ;;
esac
case "$ARCH" in
  x86_64|amd64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) die "unsupported arch: $ARCH (supported: x86_64, arm64)" ;;
esac

ASSET=""
case "${OS}-${ARCH}" in
  linux-x86_64) ASSET="haql-rs-linux-x86_64" ;;
  linux-arm64) ASSET="haql-rs-linux-arm64" ;;
  darwin-x86_64) ASSET="haql-rs-darwin-x86_64" ;;
  darwin-arm64) ASSET="haql-rs-darwin-arm64" ;;
  windows-x86_64) ASSET="haql-rs-windows-x86_64.exe" ;;
  *) die "unsupported platform: ${OS}-${ARCH}" ;;
esac

TAG="${HAQL_VERSION:-}"
if [ -z "$TAG" ]; then
  if command -v curl >/dev/null 2>&1; then
    TAG=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)
  elif command -v wget >/dev/null 2>&1; then
    TAG=$(wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)
  fi
  if [ -z "$TAG" ] || [ "$TAG" = "null" ]; then
    TAG="v0.1.1"
    info "could not fetch latest tag via API, using $TAG"
  fi
fi

info "installing ${BIN_NAME} ${TAG} for ${OS}-${ARCH} -> ${INSTALL_DIR}"

BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
BIN_URL="${BASE_URL}/${ASSET}"
SUM_URL="${BASE_URL}/SHASUMS256.txt"

TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t haql)"
trap 'rm -rf "$TMPDIR"' EXIT INT TERM
BIN_TMP="$TMPDIR/$ASSET"
SUM_TMP="$TMPDIR/SHASUMS256.txt"

download() {
  _url="$1"; _dst="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar "$_url" -o "$_dst" || return 1
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress "$_url" -O "$_dst" || return 1
  else
    die "need curl or wget to download"
  fi
}

info "downloading $BIN_URL"
if ! download "$BIN_URL" "$BIN_TMP"; then
  die "failed to download $BIN_URL (tag $TAG may not have asset $ASSET — check https://github.com/${REPO}/releases)"
fi

info "downloading $SUM_URL"
if download "$SUM_URL" "$SUM_TMP" 2>/dev/null; then
  if command -v sha256sum >/dev/null 2>&1; then
    info "verifying checksum"
    if ! (cd "$TMPDIR" && sha256sum -c --ignore-missing --status "$SUM_TMP" 2>&1); then
      EXPECTED=$(grep -F "$ASSET" "$SUM_TMP" | awk '{print $1}' || true)
      if [ -n "$EXPECTED" ]; then
        ACTUAL=$(sha256sum "$BIN_TMP" | awk '{print $1}')
        if [ "$EXPECTED" != "$ACTUAL" ]; then
          echo "expected: $EXPECTED" >&2
          echo "actual:   $ACTUAL" >&2
          die "checksum mismatch for $ASSET"
        else
          info "checksum ok (manual)"
        fi
      else
        info "warning: no checksum entry for $ASSET in SHASUMS256.txt, skipping strict verify"
      fi
    else
      info "checksum ok"
    fi
  elif command -v shasum >/dev/null 2>&1; then
    info "verifying checksum (shasum)"
    EXPECTED=$(grep -F "$ASSET" "$SUM_TMP" | awk '{print $1}' || true)
    ACTUAL=$(shasum -a 256 "$BIN_TMP" | awk '{print $1}' || true)
    if [ -n "$EXPECTED" ] && [ "$EXPECTED" != "$ACTUAL" ]; then
      die "checksum mismatch"
    fi
  else
    info "warning: no sha256sum/shasum found, skipping verify"
  fi
else
  info "warning: could not download SHASUMS256.txt — skipping verify"
fi

mkdir -p "$INSTALL_DIR" 2>/dev/null || {
  info "$INSTALL_DIR not writable, trying $FALLBACK_DIR with sudo"
  INSTALL_DIR="$FALLBACK_DIR"
  if [ ! -w "$INSTALL_DIR" ]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo mkdir -p "$INSTALL_DIR"
    else
      die "cannot create $INSTALL_DIR (no sudo)"
    fi
  fi
}

DEST="$INSTALL_DIR/$BIN_NAME"
if [ "$OS" = "windows" ]; then
  DEST="$INSTALL_DIR/${BIN_NAME}.exe"
fi

if [ -w "$INSTALL_DIR" ]; then
  cp "$BIN_TMP" "$DEST"
  chmod +x "$DEST"
else
  if command -v sudo >/dev/null 2>&1; then
    sudo cp "$BIN_TMP" "$DEST"
    sudo chmod +x "$DEST"
  else
    die "cannot write to $INSTALL_DIR (no sudo, no write perm)"
  fi
fi

info "installed to $DEST"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) info "$INSTALL_DIR is on PATH" ;;
  *)
    echo "" >&2
    echo "warning: $INSTALL_DIR is not on your PATH" >&2
    echo "  add to shell:  export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2
    echo "  then:          $BIN_NAME status" >&2
    ;;
esac

if [ -x "$DEST" ]; then
  info "testing binary"
  if "$DEST" --help >/dev/null 2>&1; then
    info "ok — run '$DEST --help' or '$BIN_NAME status'"
  else
    info "installed but binary --help failed (try ldd $DEST)"
  fi
else
  die "install failed: $DEST not executable"
fi

echo ""
echo "haql-rs $TAG installed successfully to $DEST"
echo "  haql-rs status              # verify license + HWID"
echo "  haql-rs run -e 5 -n 500 -q  # quick test"

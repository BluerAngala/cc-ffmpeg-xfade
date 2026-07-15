#!/usr/bin/env bash
# Build FFmpeg with xfade-easing (GLSL page curl transitions)
#
# Usage: bash scripts/build.sh [--prefix DIR]
# Output: ./build/ffmpeg-xfade
#
# Supports: Linux (Ubuntu/Debian), macOS (Homebrew)

set -euo pipefail
cd "$(dirname "$0")/.."

FFMPEG_VERSION="8.1.2"
BUILD_DIR="${1:-./build}"
CUSTOM_BIN="$BUILD_DIR/ffmpeg-xfade"
VENDOR_DIR="vendor/xfade-easing/src"

echo "═══════════════════════════════════════════════════"
echo "  FFmpeg ${FFMPEG_VERSION} + xfade-easing"
echo "  Target: gl_InvertedPageCurl + gl_swap GLSL transitions"
echo "═══════════════════════════════════════════════════"

mkdir -p "$BUILD_DIR"

# ── Detect platform ──
OS="$(uname -s)"
case "$OS" in
  Linux)  PLATFORM="linux" ;;
  Darwin) PLATFORM="macos" ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
  *)      echo "❌ Unsupported platform: $OS"; exit 1 ;;
esac
echo "🖥  Platform: $PLATFORM"

# ── Install dependencies ──
install_deps_linux() {
  if command -v apt-get &>/dev/null; then
    echo "📦 Installing dependencies via apt..."
    apt-get update -qq
    apt-get install -y -qq \
      build-essential nasm yasm pkg-config \
      libx264-dev libmp3lame-dev libopus-dev libvpx-dev \
      libfreetype-dev libfontconfig1-dev \
      libssl-dev zlib1g-dev \
      curl tar xz-utils \
      2>&1 | tail -1
  else
    echo "⚠️  Non-apt system. Ensure these are installed:"
    echo "   nasm yasm pkg-config libx264 libmp3lame libopus libvpx"
  fi
}

install_deps_macos() {
  if ! command -v brew &>/dev/null; then
    echo "❌ Homebrew required. Install: https://brew.sh"
    exit 1
  fi
  echo "📦 Installing dependencies via brew..."
  brew install nasm x264 lame libopus vpx pkg-config 2>&1 | tail -1
}

if [ "${SKIP_DEPS:-0}" != "1" ]; then
  "install_deps_${PLATFORM}"
fi

# ── Download FFmpeg source ──
FFMPEG_DIR="$BUILD_DIR/ffmpeg-${FFMPEG_VERSION}"
if [ ! -d "$FFMPEG_DIR" ]; then
  echo ""
  echo "📥 Downloading FFmpeg ${FFMPEG_VERSION} source..."
  curl -sL "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" \
    -o "$BUILD_DIR/ffmpeg-${FFMPEG_VERSION}.tar.xz"
  tar -xf "$BUILD_DIR/ffmpeg-${FFMPEG_VERSION}.tar.xz" -C "$BUILD_DIR"
  rm "$BUILD_DIR/ffmpeg-${FFMPEG_VERSION}.tar.xz"
else
  echo "✅ FFmpeg source already exists"
fi

# ── Patch with xfade-easing ──
echo ""
echo "🔧 Applying xfade-easing patch..."
cp -f "$VENDOR_DIR/vf_xfade.c"     "$FFMPEG_DIR/libavfilter/vf_xfade.c"
cp -f "$VENDOR_DIR/xfade-easing.h"  "$FFMPEG_DIR/libavfilter/xfade-easing.h"
echo "  ✅ vf_xfade.c replaced"
echo "  ✅ xfade-easing.h added"

# ── Configure ──
echo ""
echo "⚙️  Configuring FFmpeg..."
cd "$FFMPEG_DIR"

COMMON_FLAGS=(
  --prefix="$BUILD_DIR/install"
  --enable-gpl
  --enable-version3
  --enable-libx264
  --enable-libmp3lame
  --enable-libopus
  --enable-libvpx
  --enable-openssl
  --disable-doc
  --disable-debug
  --disable-programs
  --enable-ffmpeg
  --disable-ffplay
  --disable-ffprobe
)

if [ "$PLATFORM" = "macos" ]; then
  COMMON_FLAGS+=(--cc=clang)
  export PKG_CONFIG_PATH="$(brew --prefix openssl)/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
elif [ "$PLATFORM" = "windows" ]; then
  MINGW_PREFIX="${MINGW_PREFIX:-/mingw64}"
  COMMON_FLAGS+=(
    --extra-cflags="-I${MINGW_PREFIX}/include"
    --extra-ldflags="-L${MINGW_PREFIX}/lib"
  )
fi

./configure "${COMMON_FLAGS[@]}" 2>&1 | tail -5

# ── Build ──
echo ""
echo "🔨 Building (this takes a few minutes)..."
NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
ECFLAGS=""
[ "$PLATFORM" = "macos" ] && ECFLAGS="-Wno-declaration-after-statement"
make -j"$NPROC" ${ECFLAGS:+ECFLAGS=$ECFLAGS} 2>&1 | tail -3

# ── Install binary ──
echo ""
echo "📦 Installing..."
make install 2>&1 | tail -1
if [ "$PLATFORM" = "windows" ]; then
  cp -f "$BUILD_DIR/install/bin/ffmpeg.exe" "$BUILD_DIR/ffmpeg-xfade.exe"
  CUSTOM_BIN="$BUILD_DIR/ffmpeg-xfade.exe"
else
  cp -f "$BUILD_DIR/install/bin/ffmpeg" "$CUSTOM_BIN"
fi

cd ../..

# ── Verify ──
echo ""
echo "═══════════════════════════════════════════════════"
if [ -x "$CUSTOM_BIN" ]; then
  VERSION=$("$CUSTOM_BIN" -version 2>&1 | head -1)
  HAS_EASING=$("$CUSTOM_BIN" -hide_banner --help filter=xfade 2>&1 | grep -c "easing" || true)
  echo "  ✅ Build complete!"
  echo "  Binary: $(pwd)/$CUSTOM_BIN"
  echo "  Version: $VERSION"
  echo "  xfade-easing: $([ "$HAS_EASING" -gt 0 ] && echo 'YES' || echo 'NO')"
  echo ""
  echo "  Quick test:"
  echo "    $CUSTOM_BIN -hide_banner --help filter=xfade | grep easing"
else
  echo "  ❌ Build failed — binary not found"
  exit 1
fi
echo "═══════════════════════════════════════════════════"

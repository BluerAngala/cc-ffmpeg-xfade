# ffmpeg-xfade

Pre-built FFmpeg with [xfade-easing](https://github.com/scriptituk/xfade-easing) — GLSL page curl and advanced transitions for the XFade filter.

## What's included

Custom FFmpeg build with patched `vf_xfade.c` adding these transitions:

| Transition | Description |
|---|---|
| `gl_InvertedPageCurl` | Realistic page curl with shadow and backside |
| `gl_swap` | 3D card swap with reflection and perspective |
| `sweep-glow` | Wipe with animated glow strip |
| All standard xfade | `fade`, `dissolve`, `wipeleft`, `wiperight`, etc. |
| Easing support | `cubic-in-out`, `elastic`, `bounce`, CSS `cubic-bezier`, etc. |

## Download

Grab the latest binary from [Releases](../../releases).

```bash
# Linux x86_64
curl -sL https://github.com/BluerAngala/cc-ffmpeg-xfade/releases/latest/download/ffmpeg-xfade-linux-x86_64.tar.gz | tar xz

# macOS ARM64 (Apple Silicon)
curl -sL https://github.com/BluerAngala/cc-ffmpeg-xfade/releases/latest/download/ffmpeg-xfade-macos-arm64.tar.gz | tar xz

# Windows x86_64
curl -sLO https://github.com/BluerAngala/cc-ffmpeg-xfade/releases/latest/download/ffmpeg-xfade-windows-x86_64.zip
unzip ffmpeg-xfade-windows-x86_64.zip

./ffmpeg-xfade -version
```

## Build from source

```bash
# Linux (Ubuntu/Debian)
bash scripts/build.sh

# macOS (Homebrew)
bash scripts/build.sh

# Skip dependency installation (CI or pre-installed envs)
SKIP_DEPS=1 bash scripts/build.sh
```

Output: `./build/ffmpeg-xfade`

## Usage in other projects

```bash
# Set via environment variable
export FFMPEG_XFADE=/path/to/ffmpeg-xfade

# Or place at expected path
cp ffmpeg-xfade /usr/local/bin/ffmpeg-xfade
```

## How it works

1. Downloads FFmpeg source (configurable version)
2. Replaces `libavfilter/vf_xfade.c` with the xfade-easing patched version
3. Adds `libavfilter/xfade-easing.h` (GLSL transitions + easing functions)
4. Compiles with standard codecs (x264, lame, opus, vpx)

## Updating xfade-easing

```bash
# Pull latest from upstream
curl -sL https://raw.githubusercontent.com/scriptituk/xfade-easing/main/src/vf_xfade.c -o vendor/xfade-easing/src/vf_xfade.c
curl -sL https://raw.githubusercontent.com/scriptituk/xfade-easing/main/src/xfade-easing.h -o vendor/xfade-easing/src/xfade-easing.h

# Rebuild
bash scripts/build.sh
```

## License

- FFmpeg: [LGPL/GPL](https://www.ffmpeg.org/legal.html) (this build enables GPL)
- xfade-easing: [MIT](vendor/xfade-easing/LICENSE)

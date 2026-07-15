# cc-ffmpeg-xfade

Pre-built FFmpeg with [xfade-easing](https://github.com/scriptituk/xfade-easing) — GLSL page curl、3D swap 等高级转场效果，开箱即用。

## 快速开始

### 1. 下载二进制

```bash
# Linux x86_64
curl -sL https://github.com/BluerAngala/cc-ffmpeg-xfade/releases/latest/download/ffmpeg-xfade-linux-x86_64.tar.gz | tar xz

# macOS ARM64 (Apple Silicon / M 系列芯片)
curl -sL https://github.com/BluerAngala/cc-ffmpeg-xfade/releases/latest/download/ffmpeg-xfade-macos-arm64.tar.gz | tar xz

# Windows x86_64
curl -sLO https://github.com/BluerAngala/cc-ffmpeg-xfade/releases/latest/download/ffmpeg-xfade-windows-x86_64.zip
unzip ffmpeg-xfade-windows-x86_64.zip
```

### 2. 验证安装

```bash
./ffmpeg-xfade -version
# 应输出: ffmpeg version 8.1.2 ...

# 确认 xfade-easing 补丁生效（应看到 easing 选项）
./ffmpeg-xfade -hide_banner --help filter=xfade | grep easing
```

### 3. 体验转场效果（无需任何素材）

用纯色背景 + 文字生成测试视频，**不需要任何图片或视频文件**：

```bash
# ── 生成两个测试片段 ──
# 片段 A: 蓝色背景 + "封面" 文字，3 秒
./ffmpeg-xfade -y -f lavfi \
  -i "color=c=0x1a5276:s=1080x1920:d=3,drawtext=text='封面':fontsize=120:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2" \
  -c:v libx264 -pix_fmt yuv420p -t 3 cover.mp4

# 片段 B: 白色背景 + "正文" 文字，3 秒
./ffmpeg-xfade -y -f lavfi \
  -i "color=c=0xf0f0f0:s=1080x1920:d=3,drawtext=text='正文内容':fontsize=80:fontcolor=0x333333:x=(w-text_w)/2:y=(h-text_h)/2" \
  -c:v libx264 -pix_fmt yuv420p -t 3 content.mp4

# ── 翻页转场: gl_InvertedPageCurl ──
./ffmpeg-xfade -y \
  -i cover.mp4 -i content.mp4 \
  -filter_complex "xfade=transition=gl_InvertedPageCurl:duration=2:offset=1" \
  -c:v libx264 -pix_fmt yuv420p demo-curl.mp4

# ── 3D 卡片翻转: gl_swap ──
./ffmpeg-xfade -y \
  -i cover.mp4 -i content.mp4 \
  -filter_complex "xfade=transition=gl_swap:duration=1.5:offset=1.5" \
  -c:v libx264 -pix_fmt yuv420p demo-swap.mp4

# ── 带缓动的翻页（先慢后快） ──
./ffmpeg-xfade -y \
  -i cover.mp4 -i content.mp4 \
  -filter_complex "xfade=easing=cubic-in-out:transition=gl_InvertedPageCurl:duration=2:offset=1" \
  -c:v libx264 -pix_fmt yuv420p demo-curl-eased.mp4
```

生成的 `demo-*.mp4` 可直接播放查看效果。

## 转场效果一览

| transition 值 | 效果 | 典型用途 |
|---|---|---|
| `gl_InvertedPageCurl` | 真实翻页卷曲，带阴影和背面 | 文档翻页、书本效果 |
| `gl_swap` | 3D 卡片翻转，带反射和透视 | 封面切换、卡片翻转 |
| `fadeblack` | 黑场过渡 | 场景切换 |
| `dissolve` | 溶解叠化 | 柔和过渡 |
| `wipeleft` / `wiperight` | 水平擦除 | 滑动效果 |
| `slideup` / `slidedown` | 垂直滑动 | 幻灯片 |

完整列表：`./ffmpeg-xfade -hide_banner --help filter=xfade`

## 缓动函数 (easing)

通过 `easing=` 参数控制转场动画曲线：

| easing 值 | 效果 |
|---|---|
| `cubic-in-out` | 先慢后快再慢（默认推荐） |
| `quadratic-in-out` | 二次缓动 |
| `elastic-in-out` | 弹性回弹 |
| `bounce-in-out` | 弹跳效果 |
| `cubic-bezier(.25,.1,.25,1)` | CSS 自定义贝塞尔曲线 |

## 完整示例：法务视频翻页

用两段文字生成带翻页效果的视频：

```bash
FFMPEG=./ffmpeg-xfade

# 生成封面图（竖版 1080x1920）
$FFMPEG -y -f lavfi \
  -i "color=c=0x0d47a1:s=1080x1920:d=5, \
      drawtext=text='法律资讯':fontsize=100:fontcolor=white:x=(w-text_w)/2:y=600, \
      drawtext=text='第001期':fontsize=60:fontcolor=0xaaaaaa:x=(w-text_w)/2:y=800" \
  -c:v libx264 -pix_fmt yuv420p -t 5 cover.mp4

# 生成正文图
$FFMPEG -y -f lavfi \
  -i "color=c=0xffffff:s=1080x1920:d=5, \
      drawtext=text='正文内容区域':fontsize=60:fontcolor=0x333333:x=(w-text_w)/2:y=900" \
  -c:v libx264 -pix_fmt yuv420p -t 5 body.mp4

# 翻页转场 + 淡出
$FFMPEG -y \
  -i cover.mp4 -i body.mp4 \
  -filter_complex " \
    [0:v][1:v]xfade=easing=cubic-in-out:transition=gl_InvertedPageCurl:duration=2.5:offset=2.5, \
    fade=t=out:st=7:d=2 \
  " \
  -c:v libx264 -pix_fmt yuv420p output.mp4
```

## 集成到项目

```bash
# 方式 1: 环境变量
export FFMPEG_XFADE=/path/to/ffmpeg-xfade

# 方式 2: 放入 PATH
sudo cp ffmpeg-xfade /usr/local/bin/

# 方式 3: 直接引用路径
/path/to/ffmpeg-xfade -i input.mp4 ...
```

## 从源码构建

```bash
git clone https://github.com/BluerAngala/cc-ffmpeg-xfade.git
cd cc-ffmpeg-xfade

# Linux / macOS
bash scripts/build.sh

# 跳过依赖安装（CI 环境或已安装依赖）
SKIP_DEPS=1 bash scripts/build.sh

# 输出: ./build/ffmpeg-xfade
```

## 技术细节

- 基于 FFmpeg 8.1.2，GPL 授权
- 补丁来源: [xfade-easing](https://github.com/scriptituk/xfade-easing) (MIT)
- 内置编码器: libx264, libmp3lame, libopus, libvpx
- 构建产物: Linux x86_64 / macOS ARM64 / Windows x86_64

## License

- FFmpeg: [LGPL/GPL](https://www.ffmpeg.org/legal.html) (本构建启用 GPL)
- xfade-easing: [MIT](vendor/xfade-easing/LICENSE)

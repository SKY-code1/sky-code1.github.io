# SKY 吴渊博 · 作品集

纯静态站点（手写 HTML / CSS / JS，零框架、零构建、零依赖），可直接双击打开，
也可直接部署到 GitHub Pages。

```
portfolio/
├─ index.html                    首页：首屏 / 作品 / 制作过程 / 关于 / 联系
├─ work/
│  └─ desktop-organizer.html     案例：桌面整理器的初衷、成品与迭代过程
├─ assets/
│  ├─ css/style.css              全部样式（含响应式与动效）
│  ├─ js/main.js                 菜单、滚动揭示、复制邮箱
│  ├─ img/
│  │  ├─ favicon.svg
│  │  ├─ demo-poster.jpg         视频封面 / 首页代表图（桌面上的分组）
│  │  └─ demo-settings.jpg       设置面板截图
│  ├─ video/
│  │  └─ desktop-organizer-demo.mp4   演示视频（1 分 37 秒 / 720p / 2.7 MB）
│  └─ resume-sky.pdf             简历下载
├─ 404.html
├─ preview.ps1                   本地预览服务器（.NET，无需 Node/Python）
└─ .github/workflows/pages.yml   推送到 main 自动部署
```

## 本地预览

**方式一：直接打开** — 双击 `index.html`。资源都是相对路径，`file://` 下也能用。

**方式二：本地服务器（推荐）**

```powershell
powershell -ExecutionPolicy Bypass -File preview.ps1
# 浏览器打开 http://127.0.0.1:8080
# 端口被占用：-Port 8081
```

服务器支持 Range 请求，视频可以拖动进度条。

## 部署到 GitHub Pages

### 方式 A：分支部署（最简单）

1. 新建仓库（如 `portfolio`），把本目录所有文件推到 `main`；
2. **Settings → Pages → Build and deployment**：Source 选 **Deploy from a branch**，
   Branch 选 `main`、目录选 `/ (root)`，保存；
3. 约 1 分钟后访问 `https://sky-code1.github.io/portfolio/`。

> ⚠️ **简历里写的是 https://sky-code1.github.io/**，所以仓库必须命名为 sky-code1.github.io（用户名站点），
> 不要叫 portfolio，否则地址会变成 https://sky-code1.github.io/portfolio/，和简历对不上。

### 方式 B：GitHub Actions（已配好工作流）

1. 同样先推代码；
2. **Settings → Pages → Source** 选 **GitHub Actions**；
3. 之后每次推送 `main` 自动发布。

两种方式选一种，不要同时开。

## 演示视频的构成

`desktop-organizer-demo.mp4` 是两段录屏拼接的：

1. 主演示（原始 1:46，掐头去尾）——桌面上的分组、工具栏、设置面板
2. 一张约 2 秒的过场卡
3. 补充演示（原始 0:36，跳过开头的录制提示）——右键菜单、改色、清空分组的二次确认

两段都做了同样的处理：**裁掉左侧桌面图标列和底部任务栏**（只保留壁纸和产品界面）、
缩到 1280×720、去掉音轨、`+faststart`。原始素材 151 MB，成品 2.7 MB（1 分 37 秒）。

### 换视频

```powershell
# 单段压缩
ffmpeg -i 原始录屏.mp4 -ss 2 -t 104 -vf "crop=1560:878:340:0,scale=1280:720" `
  -c:v libx264 -crf 30 -preset slow -pix_fmt yuv420p -an -movflags +faststart 输出1.mp4

# 拼接（需要先做一张 1280×720 的过场卡 card.png）
ffmpeg -i 输出1.mp4 -loop 1 -framerate 30 -t 2 -i card.png -i 输出2.mp4 `
  -filter_complex "[1:v]scale=1280:720,setsar=1,fps=30[b];[0:v]setsar=1,fps=30[a];[2:v]setsar=1,fps=30[c];[a][b][c]concat=n=3:v=1:a=0[v]" `
  -map "[v]" -c:v libx264 -crf 30 -preset slow -pix_fmt yuv420p -an -movflags +faststart `
  assets/video/desktop-organizer-demo.mp4

# 换封面帧
ffmpeg -ss 30 -i assets/video/desktop-organizer-demo.mp4 -frames:v 1 -q:v 3 assets/img/demo-poster.jpg
```

## 内容怎么改

| 想改什么 | 改哪里 |
| --- | --- |
| 姓名 / 邮箱 / GitHub / 电话 | `index.html` 顶部、联系区、页脚 |
| 首页三条作品要点 | `index.html` 的 `.work-points` 三段 `.point` |
| 制作过程的四个阶段 | `index.html` 的 `#process` 里 `.timeline` |
| 关于我 + 实习简述 | `index.html` 的 `#about`（`.brief` 每条一行） |
| 案例正文 | `work/desktop-organizer.html` |
| 简历文件 | 覆盖 `assets/resume-sky.pdf`（保持文件名） |

### 加一个新作品

在首页 `#work` 的 `.work-more` 里，把 `.mini-card.ghost` 换成真实内容：

```html
<article class="mini-card">
  <span class="ph-label">2026.01 – 2026.03 · 角色</span>
  <h4>项目名称</h4>
  <p>一句话说明解决了什么问题，加一个能验证的数字。</p>
</article>
```

要给它单独一页，就复制 `work/desktop-organizer.html` 改名后重写内容。

## 设计说明

- 深色 + 单一强调色（`--accent: #5fe3c4`）、等宽字体做标签，整体偏"文档感"；
- 首页是作品集结构：首屏只有一段话，紧接着就是整幅演示视频；
- 案例页把"教训"和"技术细节"降级为迭代记录，主角是成品和制作过程；
- 动效遵守 `prefers-reduced-motion`，并提供打印样式；
- 无外部字体、无 CDN、无统计脚本；视频 `preload="metadata"`，不点播放几乎不耗流量。

## 上线前检查

- [ ] 手机宽度下导航能展开、视频可播放、要点单列显示
- [ ] 视频能播放且可拖动进度（GitHub Pages 原生支持 mp4 + Range）
- [ ] 简历 PDF 是最新版
- [ ] 首页和案例页之间互跳正常

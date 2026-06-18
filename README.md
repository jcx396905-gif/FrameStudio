# Frame Studio — Liquid Glass 相机品牌相框

> 给照片添加相机品牌 Logo 水印相框的 iOS/macOS 原生应用
> 
> iOS 26 Liquid Glass 风格 · SwiftUI + UIKit 混合 · 14 品牌支持

![Platform](https://img.shields.io/badge/platform-iOS%2026%2B%20%7C%20macOS%2015%2B-lightgrey)
![Swift](https://img.shields.io/badge/swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## 📸 功能一览

### 🎨 核心功能
- **品牌 Logo 水印**：14 个相机品牌 (Sony, Nikon, Canon, Fujifilm, Hasselblad, Leica, Ricoh, Zeiss, Sigma, Panasonic, Tamron, Olympus, DJI, Kodak)
- **EXIF 自动识别**：读取照片原始 EXIF 数据，自动匹配相机品牌、型号、拍摄参数
- **Liquid Glass 相框**：iOS 26 原生液态玻璃效果，三种背景模式
- **双管线渲染**：预览用 SwiftUI `.glassEffect()` 60fps 实时，导出用 Core Image 滤镜链高质量输出

### 🎛 可调参数 (21 项)

| 分类 | 参数 | 范围 |
|------|------|------|
| **背景** | 模式 (原背景/柔光/玻璃) · 模糊强度 · 照片缩放 · 圆角 · 阴影 | 5 项 |
| **Logo** | 品牌选择(14) · 大小 · 显隐 | 3 项 |
| **型号** | 文字 · 显隐 · 斜体 | 3 项 |
| **EXIF** | 文字 · 显隐 · 识别 · 字体(标准/衬线/等宽) · 字号 | 5 项 |
| **间距** | Logo 距照片 · 文字距 Logo · 底部边距 | 3 项 |
| **导出** | 格式(PNG/HEIF/JPEG) · 质量 | 2 项 |

### 🌍 其他
- 中英双语界面
- 深色/浅色主题
- 配置保存/恢复
- 智能品牌别名匹配 (Fuji Film→Fujifilm, Lumix→Panasonic, OM System→Olympus 等)

---

## 🏗 架构

```
liquidglassphotoframe/
├── App/
│   └── liquidglassphotoframeApp.swift     # @main 入口
├── Models/
│   ├── FrameConfig.swift                  # 核心配置模型 (21 参数, Codable)
│   ├── BrandData.swift                    # 14 品牌数据 + 别名匹配
│   └── FrameRenderLayout.swift            # 比例化布局计算引擎
├── Services/
│   ├── ExifReaderService.swift            # EXIF 读取 (焦距/光圈/快门/ISO/品牌/型号)
│   ├── FrameConfigStore.swift             # 配置持久化 (UserDefaults JSON)
│   ├── GlassExportService.swift           # 导出渲染管线 (Core Image 滤镜链)
│   └── PhotoLibraryService.swift          # 相册保存 (PNG/HEIF/JPEG)
├── Utils/
│   └── Localization.swift                 # 中英双语
├── Views/
│   ├── ContentView.swift                  # 主视图 (三 Tab + 照片加载 + Toast)
│   ├── FramePreviewView.swift             # 相框预览 (SwiftUI 渲染)
│   ├── LayoutTab.swift                    # 布局面板
│   ├── StyleParamsTab.swift               # 质感参数面板
│   ├── ExportTab.swift                    # 导出面板 + 设置
│   ├── GlassSegmentedPicker.swift         # 玻璃分段选择器
│   ├── GlassSlider.swift                  # 玻璃滑块
│   └── GlassTabBar.swift                  # 三 Tab 底栏
└── Assets.xcassets/
    └── 14 品牌 Logo (PNG) + AppIcon
```

### 渲染架构：双管线

```
                FrameConfig (唯一数据源)
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
 ┌─────────────────┐      ┌─────────────────────┐
 │   预览管线       │      │     导出管线          │
 │ SwiftUI         │  ≈   │ Core Image 滤镜链    │
 │ .glassEffect()  │      │ CIGaussianBlur       │
 │ 60fps 实时      │      │ + colorControls      │
 │                 │      │ + 渐变叠加           │
 └─────────────────┘      └─────────────────────┘
```

---

## 📦 构建

### iOS (Simulator)
```bash
xcodebuild -project liquidglassphotoframe.xcodeproj \
  -scheme liquidglassphotoframe \
  -configuration Release \
  -sdk iphonesimulator \
  -arch x86_64 build
```

### macOS Catalyst
```bash
xcodebuild -project liquidglassphotoframe.xcodeproj \
  -scheme liquidglassphotoframe \
  -configuration Release \
  -destination 'platform=macOS,arch=x86_64' build

xcodebuild -project liquidglassphotoframe.xcodeproj \
  -scheme liquidglassphotoframe \
  -destination 'platform=macOS,arch=arm64' build
```

### 创建 DMG
```bash
hdiutil create -volname "Frame Studio" \
  -srcfolder /path/to/FrameStudio.app \
  -ov -format UDZO FrameStudio-macOS-arch.dmg
```

---

## 📝 设计规范

完整设计文档见 [docs/superpowers/specs/2026-05-23-frame-studio-design.md](docs/superpowers/specs/2026-05-23-frame-studio-design.md)

### 设计方向
- **基调**：克制、编辑级 —— Leica 精品店质感
- **基底色**：Dark-first (`#0A0A0A`)，琥珀金强调 (`#D4A853`)
- **字体**：SF Pro Display / SF Pro Text
- **玻璃**：iOS 26 Liquid Glass（相框背景 + 控制面板）

---

## 📄 License

MIT License — 作者 jcx

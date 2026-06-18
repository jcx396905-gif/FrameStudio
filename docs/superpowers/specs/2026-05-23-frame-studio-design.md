# Frame Studio — iOS 原生相框工具 设计规范 v2

**日期：** 2026-05-23（修订版）
**状态：** 已确认（含四项关键修订）
**参考：** https://app.proplusmax.com/apro/mobileUI.html

---

## 修订记录

| # | 问题 | 原方案 | 修订方案 |
|---|------|--------|---------|
| 1 | 相框背景=普通高斯模糊，缺少玻璃质感 | 只用 `.blur()` | 预览用 `.glassEffect()`，导出用 Core Image 模拟 |
| 2 | `scale: 4.0` 写死，像素/内存失控 | 固定 4 倍 | 动态 scale = 原图尺寸 / 预览尺寸 |
| 3 | 水印字体用固定 pt，导出后大小失衡 | 固定 16pt 等 | GeometryReader 取当前宽度 × 百分比 |
| 4 | FrameConfig 不支持序列化 | 纯 @Observable | 遵循 Codable 协议 |

---

## 1. 概述

Frame Studio 是一款 iOS 26 原生相框水印工具。用户选择照片后，照片被嵌入一个**具有流体玻璃质感的相框**中，底部叠加品牌 Logo、相机型号和 EXIF 参数。预览和导出视觉一致。

### 核心承诺
> 一张照片 → 一个精美液态玻璃相框 → 一次导出。所见即所得。

---

## 2. 设计方向

| 属性 | 决策 |
|------|------|
| **目的** | 摄影师级照片水印展示工具 |
| **基调** | 克制、编辑级 —— Leica 精品店质感 |
| **基底色** | Dark-first（`#0A0A0A`），琥珀金强调（`#D4A853`） |
| **字体** | SF Pro Display（标题），SF Pro Text（正文），层级明确 |
| **玻璃** | 相框背景 + 控制面板均用 Liquid Glass |
| **图标** | 仅 SF Symbols，UI 中不使用 emoji |
| **布局** | 三 Tab 底栏：布局 / 质感参数 / 导出 |

---

## 3. 架构

### 3.1 双管线渲染（关键修订 #1）

**核心事实：** ImageRenderer **无法**捕获 `.glassEffect()` 输出。Liquid Glass 是 UIKit 层的 `UIGlassEffect`，依赖实时窗口上下文（陀螺仪、动态光照采样），ImageRenderer 离屏渲染只能输出黑色占位图。

**解决方案：预览和导出走不同渲染路径，但保证视觉一致。**

```
                    FrameConfig (唯一数据源)
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
     ┌─────────────────┐      ┌─────────────────────┐
     │   预览管线       │      │     导出管线          │
     │                 │      │                      │
     │ ZStack:         │      │ Core Image 滤镜链:    │
     │ ├ 模糊背景      │      │ ├ CIGaussianBlur      │
     │ ├ .glassEffect()│  ≈   │ ├ CIMaskedVariableBlur│
     │ ├ 原图(裁剪)    │      │ ├ CISmoothLinearGrad  │
     │ └ 叠加层(Logo)  │      │ ├ CIBlendWithMask     │
     │                 │      │ ├ CIHighlightShadow   │
     │ 60fps 实时      │      │ └ CIContext → PNG     │
     └─────────────────┘      └─────────────────────┘
```

**CI 滤镜链如何模拟 Liquid Glass 的视觉特征：**

| Liquid Glass 特征 | Core Image 模拟手段 |
|-------------------|-------------------|
| 毛玻璃模糊 | `CIGaussianBlur` + `CIMaskedVariableBlur`（渐变模糊：边缘更糊，中心更清） |
| 光线折射/高光 | `CISmoothLinearGradient`（左上→右下，白→透明）+ `CIHighlightShadowAdjust` |
| 玻璃边缘定义 | 1px 白色半透明描边 |
| 暖色调 | `tintColor` 混合（琥珀 `#D4A853` alpha 0.08） |
| 有机颗粒感 | 可选：`CIRandomGenerator` 噪声叠加 |

**参考实现：**
- [dejager Gist](https://gist.github.com/dejager/e27aa55b2276ff77f60b33042a6ecc2b) — CIMaskedVariableBlur + 渐变合成
- [BarredEwe/LiquidGlass](https://github.com/BarredEwe/LiquidGlass) — Metal shader 完整管线
- [usagimaru/ProgressiveBlur](https://github.com/usagimaru/ProgressiveBlur) — 渐进模糊封装

### 3.2 动态导出分辨率（关键修订 #2）

```swift
func exportScale(sourceImage: UIImage, previewWidth: CGFloat) -> CGFloat {
    let sourcePixels = max(sourceImage.size.width, sourceImage.size.height) * sourceImage.scale
    let rawScale = sourcePixels / previewWidth
    return min(8.0, max(1.0, rawScale))  // 上限 8x，下限 1x
}
```

| 场景 | 预览宽度 | 原图像素 | scale | 输出宽度 |
|------|---------|---------|-------|---------|
| 1200 万像素 | 300pt | 4000px | 8x (截断) | 2400px |
| 800 万像素 | 300pt | 3200px | 8x (截断) | 2400px |
| 200 万像素 | 300pt | 1600px | 5.3x | 1600px |

**内存保护：** 估算 `estimatedMemoryFootprint`，超 200MB 自动降一档。

### 3.3 比例化尺寸（关键修订 #3）

所有文字/间距写死在 `FrameView` 的 `GeometryReader` 中按 `viewWidth` 比例计算：

```swift
let exifFontSize = viewWidth * config.exifFontScale     // 0.016 → 300pt=4.8pt, 4000px=64px
let logoHeight   = viewWidth * config.logoSizeScale     // 0.03
let bottomPad    = viewWidth * config.bottomMarginScale // 0.06
```

| 字段 | 默认比例 | 300pt 预览 | 4000px 导出 |
|------|---------|-----------|------------|
| `exifFontScale` | 0.016 | 4.8pt | 64pt |
| `logoSizeScale` | 0.03 | 9pt | 120px |
| `cornerRadiusScale` | 0.016 | 4.8pt | 64pt |
| `bottomMarginScale` | 0.06 | 18pt | 240px |
| `textToLogoScale` | 0.015 | 4.5pt | 60px |
| `logoToPhotoScale` | 0.04 | 12pt | 160px |

---

## 4. 数据模型（关键修订 #4）

```swift
@Observable
final class FrameConfig: Codable {
    var backgroundMode: BackgroundMode = .original
    var blurRadius: CGFloat = 40
    var photoScale: CGFloat = 0.88
    var cornerRadiusScale: CGFloat = 0.016
    var shadowDepth: CGFloat = 0.4

    var selectedBrand: String = "sony"
    var logoSizeScale: CGFloat = 0.03
    var logoVisible: Bool = true

    var cameraModel: String = "A7R V"
    var cameraModelVisible: Bool = true
    var cameraModelItalic: Bool = false

    var exifText: String = "200mm f/4 1/800s ISO400"
    var exifVisible: Bool = true
    var exifFontName: String = "Standard"
    var exifFontScale: CGFloat = 0.016

    var logoToPhotoScale: CGFloat = 0.04
    var textToLogoScale: CGFloat = 0.015
    var bottomMarginScale: CGFloat = 0.06

    var exportFormat: ExportFormat = .png
    var exportQuality: CGFloat = 1.0
}
```

**Codable 前瞻价值：** MVP 不做预设模板，但随时可 `JSONEncoder().encode(config)` 序列化为 JSON。后续模板功能只需存取 JSON，无需重构数据层。

---

## 5. 三 Tab 规格

### 5.1 布局 Tab（6 项）

| # | 控件 | 默认值 | 范围 | API |
|---|------|--------|------|-----|
| 1 | PhotosPicker | — | 单张 | `PhotosPicker` |
| 2 | 背景模式 | Original | Original/Custom/None | 玻璃分段选择器 |
| 3 | 模糊强度 | 40 | 0–100 | `.blur()` |
| 4 | 照片缩放 | 88% | 60–95% | `.scaleEffect()` |
| 5 | 圆角比例 | 0.016 | 0–0.04 | `.clipShape()` |
| 6 | 阴影深度 | 0.4 | 0–1.0 | `.shadow()` |

### 5.2 质感参数 Tab（15 项）

| # | 区域 | 控件 | 默认值 |
|---|------|------|--------|
| 7-10 | Logo | 品牌网格/自定义/大小/显示 | Sony / 0.03 / 显示 |
| 11-13 | 型号 | 文字/显示/斜体 | "A7R V" / 显示 / 常规 |
| 14-18 | EXIF | 文字/显示/识别/字体/字号 | 200mm.../显示/Standard/0.016 |
| 19-21 | 间距 | Logo距照片/文字距Logo/底边 | 0.04 / 0.015 / 0.06 |

### 5.3 导出 Tab（4 项）

| # | 控件 | 默认值 | 备注 |
|---|------|--------|------|
| 22 | 导出按钮 | — | 触发 CI 管线 |
| 23 | 格式 | PNG | PNG / HEIF / JPEG |
| 24 | 质量 | 100% | JPEG 压缩比 |
| 25 | 保存/分享 | — | PHPhotoLibrary / ShareLink |

---

## 6. 导出管线详细流程

```
用户点击导出
    │
计算 dynamicScale（基于原图尺寸 ÷ 预览宽度，clamp 1-8x）
    │
CIContext(workingColorSpace: Display P3)
    │
Core Image 滤镜链:
  ├─ CIGaussianBlur(radius: 40)
  ├─ CIMaskedVariableBlur(mask: 径向渐变, radius: 28)
  ├─ CIBlendWithMask(blurred, original, mask)
  ├─ CISmoothLinearGradient(光泽层，白→透明)
  ├─ CIHighlightShadowAdjust(highlight: 0.15)
  └─ CIContext.createCGImage()
    │
UIGraphicsImageRenderer 绘制 Logo/文字叠加
    │
PNG/HEIF/JPEG 写入 → Photos 或 ShareLink
```

---

## 7. MVP 范围

| 里程碑 | 内容 |
|--------|------|
| M1 | FrameConfig + PhotosPicker + 玻璃预览 + Layout Tab |
| M2 | Logo 网格 + 相机型号 + EXIF 识别 + 字体 + 间距 |
| M3 | CI 导出管线 + 动态 scale + Photos/Share |

**延迟：** 预设模板、批量处理、自定义背景、iPad 自适应、Widget

---

## 8. 自审清单

- [x] 无占位符或 TODO
- [x] 双管线架构，预览玻璃 = 导出 CI 模拟
- [x] 动态导出 scale（不再写死 4.0）
- [x] 比例化尺寸（GeometryReader + viewWidth 百分比）
- [x] FrameConfig 遵循 Codable
- [x] Liquid Glass 遵循 HIG（相框背景 + 控件层用玻璃，内容层不用）
- [x] UI 无 emoji

# Frame Studio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS 26 native photo frame tool with Liquid Glass frame overlay, brand logo, EXIF parameters, and 4K Core Image export.

**Architecture:** Single `@Observable FrameConfig` (Codable) drives Preview (`.glassEffect()` live) and Export (Core Image CI filter chain simulating glass). Three-tab bottom bar: Layout / Style & Params / Export. All dimensions are geometrically proportional (% of viewWidth), not fixed pt.

**Tech Stack:** SwiftUI, iOS 26, Liquid Glass, Core Image, PhotosPicker, PHPhotoLibrary, ImageRenderer, Swift 6 strict concurrency.

---

## File Structure

### Create (new files)
```
Models/
  FrameConfig.swift          — @Observable + Codable config model (25 params)
  BrandData.swift            — 14 built-in brand definitions

Views/
  ContentView.swift          — Root: TabView + glass tab bar
  FramePreviewView.swift     — ZStack render pipeline (preview mode)
  GlassControlPanel.swift    — Tab content wrapper with glass background
  LayoutTab.swift            — 6 layout controls
  StyleParamsTab.swift       — 15 brand/params controls
  ExportTab.swift            — 4 export controls
  GlassSlider.swift          — Reusable custom glass slider component
  GlassSegmentedPicker.swift — Reusable glass segmented picker
  GlassTabBar.swift          — Bottom 3-tab glass bar

Services/
  GlassExportService.swift   — Core Image filter chain for glass simulation
  ExifReaderService.swift    — CGImageSource EXIF extraction
  PhotoLibraryService.swift  — PHPhotoLibrary save
```

### Modify (existing files)
```
liquidglassphotoframeApp.swift  — Update to use ContentView (remove Item/ModelContainer)
ContentView.swift               — Replace template scaffold with app root
```

### Delete (template files)
```
Item.swift  — Remove Xcode scaffold model
```

---

## Milestone 1: Data Model + Core Architecture

### Task 1.1: Remove Template Code

**Files:**
- Delete: `liquidglassphotoframe/Item.swift`
- Modify: `liquidglassphotoframe/liquidglassphotoframeApp.swift`
- Modify: `liquidglassphotoframe/ContentView.swift`

- [ ] **Step 1: Delete Item.swift**

```bash
rm /Volumes/资料库45G/x/lgf/liquidglassphotoframe/liquidglassphotoframe/Item.swift
```

- [ ] **Step 2: Simplify liquidglassphotoframeApp.swift**

Replace entire file:

```swift
import SwiftUI

@main
struct liquidglassphotoframeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 3: Clear ContentView.swift boot template**

Replace entire file with empty app root:

```swift
import SwiftUI

struct ContentView: View {
    @State private var config = FrameConfig()
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            FramePreviewView(image: selectedImage, config: config)
            GlassTabBar(selectedTab: .layout) { tab in
                // Tab content will be added in later tasks
            }
        }
        .background(Color(hex: "#0A0A0A"))
    }
}
```

- [ ] **Step 4: Build to verify no compile errors**

```bash
xcodebuild -project liquidglassphotoframe.xcodeproj -scheme liquidglassphotoframe -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: BUILD FAILED (FrameConfig not yet defined — OK, will define in next task)

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: remove template scaffold, prepare for Frame Studio architecture"
```

---

### Task 1.2: Create FrameConfig Model

**Files:**
- Create: `liquidglassphotoframe/Models/FrameConfig.swift`

- [ ] **Step 1: Create Models directory**

```bash
mkdir -p /Volumes/资料库45G/x/lgf/liquidglassphotoframe/liquidglassphotoframe/Models
```

- [ ] **Step 2: Write FrameConfig.swift**

```swift
import Foundation
import Observation
import UIKit

enum BackgroundMode: String, Codable, CaseIterable {
    case original, custom, none
}

enum ExportFormat: String, Codable, CaseIterable {
    case png, heif, jpeg
}

@Observable
final class FrameConfig: Codable {
    // === Layout ===
    var backgroundMode: BackgroundMode = .original
    var blurRadius: CGFloat = 40
    var photoScale: CGFloat = 0.88
    var cornerRadiusScale: CGFloat = 0.016
    var shadowDepth: CGFloat = 0.4

    // === Brand Logo ===
    var selectedBrand: String = "sony"
    var logoSizeScale: CGFloat = 0.03
    var logoVisible: Bool = true

    // === Camera Model ===
    var cameraModel: String = "A7R V"
    var cameraModelVisible: Bool = true
    var cameraModelItalic: Bool = false

    // === EXIF ===
    var exifText: String = "200mm f/4 1/800s ISO400"
    var exifVisible: Bool = true
    var exifFontName: String = "Standard"
    var exifFontScale: CGFloat = 0.016

    // === Spacing (all proportional to viewWidth) ===
    var logoToPhotoScale: CGFloat = 0.04
    var textToLogoScale: CGFloat = 0.015
    var bottomMarginScale: CGFloat = 0.06

    // === Export ===
    var exportFormat: ExportFormat = .png
    var exportQuality: CGFloat = 1.0

    // === Codable ===
    enum CodingKeys: String, CodingKey {
        case backgroundMode, blurRadius, photoScale,
             cornerRadiusScale, shadowDepth,
             selectedBrand, logoSizeScale, logoVisible,
             cameraModel, cameraModelVisible, cameraModelItalic,
             exifText, exifVisible, exifFontName, exifFontScale,
             logoToPhotoScale, textToLogoScale, bottomMarginScale,
             exportFormat, exportQuality
    }

    init() {}
}
```

- [ ] **Step 3: Build to verify FrameConfig compiles**

```bash
xcodebuild -project liquidglassphotoframe.xcodeproj -scheme liquidglassphotoframe -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: BUILD FAILED (GlassTabBar not yet defined — expected)

- [ ] **Step 4: Commit**

```bash
git add Models/FrameConfig.swift && git commit -m "feat: add FrameConfig model (25 params, Codable)"
```

---

### Task 1.3: Create BrandData

**Files:**
- Create: `liquidglassphotoframe/Models/BrandData.swift`

- [ ] **Step 1: Write BrandData.swift**

```swift
import Foundation

struct BrandData {
    static let all: [String] = [
        "sony", "nikon", "canon", "fujifilm",
        "hasselblad", "leica", "ricoh", "zeiss",
        "sigma", "panasonic", "tamron", "olympus",
        "dji", "kodak"
    ]

    static let displayNames: [String: String] = [
        "sony": "Sony", "nikon": "Nikon", "canon": "Canon",
        "fujifilm": "Fujifilm", "hasselblad": "Hasselblad",
        "leica": "Leica", "ricoh": "Ricoh", "zeiss": "Zeiss",
        "sigma": "Sigma", "panasonic": "Panasonic",
        "tamron": "Tamron", "olympus": "Olympus",
        "dji": "DJI", "kodak": "Kodak"
    ]
}
```

- [ ] **Step 2: Commit**

```bash
git add Models/BrandData.swift && git commit -m "feat: add BrandData with 14 built-in camera brands"
```

---

## Milestone 2: Core Views

### Task 2.1: Create GlassSlider Component

**Files:**
- Create: `liquidglassphotoframe/Views/GlassSlider.swift`

- [ ] **Step 1: Write GlassSlider.swift**

```swift
import SwiftUI

struct GlassSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let label: String
    let format: String

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                Text(String(format: format, value))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.2))
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.05))
                        .frame(height: 4)

                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(width: geo.size.width * normalizedValue, height: 4)

                    Circle()
                        .fill(.white.opacity(0.85))
                        .frame(width: 18, height: 18)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                        .offset(x: geo.size.width * normalizedValue - 9)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    let ratio = gesture.location.x / geo.size.width
                                    value = range.lowerBound + (range.upperBound - range.lowerBound) * max(0, min(1, ratio))
                                }
                        )
                }
            }
            .frame(height: 18)
        }
    }

    private var normalizedValue: CGFloat {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Views/GlassSlider.swift && git commit -m "feat: add reusable GlassSlider component"
```

---

### Task 2.2: Create GlassSegmentedPicker

**Files:**
- Create: `liquidglassphotoframe/Views/GlassSegmentedPicker.swift`

- [ ] **Step 1: Write GlassSegmentedPicker.swift**

```swift
import SwiftUI

struct GlassSegmentedPicker<T: Hashable & CustomStringConvertible>: View {
    @Binding var selection: T
    let options: [T]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = option
                    }
                } label: {
                    Text(option.description)
                        .font(.system(size: 10, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white.opacity(0.08))
                            }
                        }
                        .foregroundStyle(selection == option ? .white : .white.opacity(0.35))
                }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.03))
        )
    }
}

// Make enums CustomStringConvertible for picker labels
extension BackgroundMode: CustomStringConvertible {
    var description: String {
        switch self {
        case .original: return "Original"
        case .custom: return "Custom"
        case .none: return "None"
        }
    }
}

extension ExportFormat: CustomStringConvertible {
    var description: String {
        switch self {
        case .png: return "PNG"
        case .heif: return "HEIF"
        case .jpeg: return "JPEG"
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Views/GlassSegmentedPicker.swift && git commit -m "feat: add reusable GlassSegmentedPicker"
```

---

### Task 2.3: Create FramePreviewView

**Files:**
- Create: `liquidglassphotoframe/Views/FramePreviewView.swift`

- [ ] **Step 1: Write FramePreviewView.swift**

```swift
import SwiftUI

struct FramePreviewView: View {
    let image: UIImage?
    let config: FrameConfig

    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width
            let viewHeight = geometry.size.height

            if let image {
                let exifFontSz = viewWidth * config.exifFontScale
                let logoHt = viewWidth * config.logoSizeScale
                let cornerRad = viewWidth * config.cornerRadiusScale
                let bottomPad = viewWidth * config.bottomMarginScale
                let textLogoGap = viewWidth * config.textToLogoScale
                let logoPhotoGap = viewWidth * config.logoToPhotoScale

                ZStack {
                    // Layer 0: Blurred background
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: viewWidth, height: viewHeight)
                        .blur(radius: config.blurRadius)
                        .clipped()
                        .overlay(Color.black.opacity(0.15))

                    // Layer 1: Liquid Glass frame (preview only)
                    if config.backgroundMode == .original {
                        Rectangle()
                            .fill(.clear)
                            .glassEffect(.regular, in: Rectangle())
                    }

                    // Layer 2: Original photo
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(config.photoScale)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRad))
                        .shadow(
                            color: .black.opacity(config.shadowDepth),
                            radius: viewWidth * 0.03 * config.shadowDepth,
                            y: viewWidth * 0.02 * config.shadowDepth
                        )

                    // Layer 3: Logo + Camera Model + EXIF overlay
                    VStack(spacing: textLogoGap) {
                        Spacer()
                            .frame(height: logoPhotoGap)

                        if config.logoVisible {
                            BrandLogoView(
                                brand: config.selectedBrand,
                                height: logoHt
                            )
                        }

                        if config.cameraModelVisible {
                            Text(config.cameraModel)
                                .font(.system(size: exifFontSz * 0.9, weight: .semibold))
                                .italic(config.cameraModelItalic)
                                .foregroundStyle(.white.opacity(0.95))
                                .letterSpacing(1)
                        }

                        if config.exifVisible {
                            Text(config.exifText)
                                .font(.system(size: exifFontSz, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .letterSpacing(1)
                                .fontDesign(fontDesignForName(config.exifFontName))
                        }
                    }
                    .padding(.bottom, bottomPad)
                }
            } else {
                // Empty state with PhotosPicker trigger area
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.15))
                    Text("Tap to select a photo")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.25))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                )
                .padding(24)
            }
        }
    }

    private func fontDesignForName(_ name: String) -> Font.Design {
        switch name {
        case "Serif": return .serif
        case "Monospace": return .monospaced
        default: return .default
        }
    }
}

// Temporary placeholder until brand assets are added
struct BrandLogoView: View {
    let brand: String
    let height: CGFloat

    var body: some View {
        Text(brand.uppercased())
            .font(.system(size: height * 0.4, weight: .bold))
            .foregroundStyle(.white.opacity(0.9))
            .letterSpacing(2)
            .frame(height: height)
    }
}
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild -project liquidglassphotoframe.xcodeproj -scheme liquidglassphotoframe -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED (or failing on unresolved symbols from remaining files — proceed if FramePreviewView itself compiles)

- [ ] **Step 4: Commit**

```bash
git add Views/FramePreviewView.swift && git commit -m "feat: add FramePreviewView with glass ZStack pipeline"
```

---

### Task 2.4: Create GlassTabBar

**Files:**
- Create: `liquidglassphotoframe/Views/GlassTabBar.swift`

```swift
import SwiftUI

enum AppTab: String, CaseIterable {
    case layout = "Layout"
    case styleParams = "Style & Params"
    case export = "Export"

    var icon: String {
        switch self {
        case .layout: return "rectangle.3.group"
        case .styleParams: return "textformat.alt"
        case .export: return "square.and.arrow.up"
        }
    }
}

struct GlassTabBar<Content: View>: View {
    @State private var selectedTab: AppTab = .layout
    @Namespace private var namespace
    @ViewBuilder let content: (AppTab) -> Content

    var body: some View {
        VStack(spacing: 0) {
            content(selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.35))
                        .background {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.white.opacity(0.08))
                                    .matchedGeometryEffect(id: "tab", in: namespace)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Views/GlassTabBar.swift && git commit -m "feat: add GlassTabBar with Liquid Glass morphing tabs"
```

---

### Task 2.5: Wire ContentView with TabBar

**Files:**
- Modify: `liquidglassphotoframe/ContentView.swift`

- [ ] **Step 1: Rewrite ContentView.swift**

```swift
import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var config = FrameConfig()
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                FramePreviewView(image: selectedImage, config: config)
                    .frame(height: geometry.size.height * 0.48)

                GlassTabBar { tab in
                    ScrollView {
                        switch tab {
                        case .layout:
                            LayoutTab(
                                config: $config,
                                selectedPhotoItem: $selectedPhotoItem
                            )
                        case .styleParams:
                            StyleParamsTab(config: $config)
                        case .export:
                            ExportTab(
                                config: config,
                                image: selectedImage,
                                previewWidth: geometry.size.width * 0.88
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(Color(hex: "#0A0A0A").ignoresSafeArea())
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 2: Build to verify compilation setup**

```bash
xcodebuild -project liquidglassphotoframe.xcodeproj -scheme liquidglassphotoframe -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: BUILD FAILED (tab views not yet defined — will create in next tasks)

- [ ] **Step 3: Commit**

```bash
git add ContentView.swift && git commit -m "feat: wire ContentView with PhotosPicker, FramePreview, and GlassTabBar"
```

---

## Milestone 3: Tab Views

### Task 3.1: Create LayoutTab

**Files:**
- Create: `liquidglassphotoframe/Views/LayoutTab.swift`

- [ ] **Step 1: Write LayoutTab.swift**

```swift
import SwiftUI
import PhotosUI

struct LayoutTab: View {
    @Binding var config: FrameConfig
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Layout")

            // Photo Source
            groupBox {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 14))
                        Text("Select Photo")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    )
                }
                .buttonStyle(.plain)
            }

            // Background Mode
            groupBox {
                Text("Background")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                GlassSegmentedPicker(
                    selection: $config.backgroundMode,
                    options: BackgroundMode.allCases
                )
            }

            // Sliders
            groupBox {
                GlassSlider(value: $config.blurRadius, range: 0...100, label: "Blur", format: "%.0f")
                GlassSlider(value: $config.photoScale, range: 0.6...0.95, label: "Scale", format: "%.0f%%")
                    .onChange(of: config.photoScale) { _, new in
                        config.photoScale = new
                    }
                GlassSlider(value: $config.cornerRadiusScale, range: 0...0.04, label: "Corner Radius", format: "%.3f")
                GlassSlider(value: $config.shadowDepth, range: 0...1, label: "Shadow", format: "%.2f")
            }
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.35))
            .letterSpacing(2)
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func groupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Views/LayoutTab.swift && git commit -m "feat: add LayoutTab with PhotosPicker, background mode, and 4 glass sliders"
```

---

### Task 3.2: Create StyleParamsTab

**Files:**
- Create: `liquidglassphotoframe/Views/StyleParamsTab.swift`

- [ ] **Step 1: Write StyleParamsTab.swift**

```swift
import SwiftUI

struct StyleParamsTab: View {
    @Binding var config: FrameConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Style & Params")

            // Brand Logo Section
            brandSection

            // Camera Model Section
            cameraModelSection

            // EXIF Section
            exifSection

            // Spacing Section
            spacingSection
        }
        .padding(.top, 12)
    }

    // MARK: - Brand Logo

    private var brandSection: some View {
        groupBox {
            Text("Brand Logo")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(BrandData.all, id: \.self) { brand in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            config.selectedBrand = brand
                        }
                    } label: {
                        Text(BrandData.displayNames[brand] ?? brand)
                            .font(.system(size: 8, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(config.selectedBrand == brand ? .white.opacity(0.08) : .white.opacity(0.02))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(config.selectedBrand == brand ? .white.opacity(0.1) : .white.opacity(0.03), lineWidth: 1)
                            )
                            .foregroundStyle(config.selectedBrand == brand ? .white : .white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
            }

            GlassSlider(value: $config.logoSizeScale, range: 0.01...0.08, label: "Logo Size", format: "%.3f")

            Toggle("Show Logo", isOn: $config.logoVisible)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
                .tint(.white.opacity(0.3))
        }
    }

    // MARK: - Camera Model

    private var cameraModelSection: some View {
        groupBox {
            Text("Camera Model")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))

            Toggle("Show Model", isOn: $config.cameraModelVisible)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
                .tint(.white.opacity(0.3))

            TextField("Camera Model", text: $config.cameraModel)
                .font(.system(size: 13))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )

            Toggle("Italic", isOn: $config.cameraModelItalic)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
                .tint(.white.opacity(0.3))
        }
    }

    // MARK: - EXIF

    private var exifSection: some View {
        groupBox {
            Text("EXIF Parameters")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))

            Toggle("Show EXIF", isOn: $config.exifVisible)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
                .tint(.white.opacity(0.3))

            TextField("EXIF Text", text: $config.exifText)
                .font(.system(size: 13))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )

            GlassSlider(value: $config.exifFontScale, range: 0.008...0.04, label: "Font Size", format: "%.3f")

            Picker("Font", selection: $config.exifFontName) {
                Text("Standard").tag("Standard")
                Text("Serif").tag("Serif")
                Text("Monospace").tag("Monospace")
            }
            .pickerStyle(.menu)
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.45))
        }
    }

    // MARK: - Spacing

    private var spacingSection: some View {
        groupBox {
            Text("Spacing")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))

            GlassSlider(value: $config.logoToPhotoScale, range: 0...0.15, label: "Logo to Photo", format: "%.3f")
            GlassSlider(value: $config.textToLogoScale, range: 0...0.1, label: "Text to Logo", format: "%.3f")
            GlassSlider(value: $config.bottomMarginScale, range: 0.02...0.2, label: "Bottom Margin", format: "%.3f")
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.35))
            .letterSpacing(2)
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func groupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Views/StyleParamsTab.swift && git commit -m "feat: add StyleParamsTab with brand grid, camera model, EXIF, and spacing controls"
```

---

### Task 3.3: Create ExportTab

**Files:**
- Create: `liquidglassphotoframe/Views/ExportTab.swift`

- [ ] **Step 1: Write ExportTab.swift**

```swift
import SwiftUI

struct ExportTab: View {
    let config: FrameConfig
    let image: UIImage?
    let previewWidth: CGFloat
    @State private var isExporting = false
    @State private var exportMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Export")

            // Export Button
            Button {
                exportImage()
            } label: {
                HStack(spacing: 8) {
                    if isExporting {
                        ProgressView()
                            .tint(.black)
                    }
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text(isExporting ? "Exporting..." : "Export Frame")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#D4A853").opacity(isExporting ? 0.5 : 1))
                )
                .foregroundStyle(.black)
            }
            .disabled(image == nil || isExporting)

            // Format Picker
            groupBox {
                Text("Format")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                GlassSegmentedPicker(
                    selection: $config.exportFormat as! Binding<ExportFormat>,
                    options: ExportFormat.allCases
                )
            }

            // Quality Slider (JPEG only)
            if config.exportFormat == .jpeg {
                groupBox {
                    GlassSlider(
                        value: $config.exportQuality,
                        range: 0.1...1.0,
                        label: "Quality",
                        format: "%.0f%%"
                    )
                }
            }

            // Export Preview Thumbnail
            if let image {
                groupBox {
                    Text("Preview")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxHeight: 200)
                }
            }

            // Status Message
            if let msg = exportMessage {
                Text(msg)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 12)
    }

    private func exportImage() {
        guard let image else { return }
        isExporting = true
        Task {
            // Export will be implemented in GlassExportService
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                isExporting = false
                exportMessage = "Export placeholder — GlassExportService pending"
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Views/ExportTab.swift && git commit -m "feat: add ExportTab with format picker, quality slider, and placeholder export"
```

---

### Task 3.4: First Build Verification

- [ ] **Step 1: Build the full app**

```bash
xcodebuild -project liquidglassphotoframe.xcodeproj -scheme liquidglassphotoframe -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | grep -E "(error:|BUILD|warning:.*ContentView)" | head -20
```

Expected: BUILD SUCCEEDED (some warnings OK)

- [ ] **Step 2: Fix any compile errors, re-build until clean**

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "chore: first build — all views wired, compiles successfully"
```

---

## Milestone 4: Services

### Task 4.1: Create ExifReaderService

**Files:**
- Create: `liquidglassphotoframe/Services/ExifReaderService.swift`

- [ ] **Step 1: Write ExifReaderService.swift**

```swift
import UIKit
import ImageIO

struct ExifReaderService {
    static func extractExif(from image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1.0) ?? image.pngData() else {
            return nil
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }

        guard let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] else {
            return nil
        }

        let focalLength = exif[kCGImagePropertyExifFocalLength as String] as? Double
        let fNumber = exif[kCGImagePropertyExifFNumber as String] as? Double
        let exposureTime = exif[kCGImagePropertyExifExposureTime as String] as? Double
        let isoSpeed = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int]

        var parts: [String] = []
        if let fl = focalLength { parts.append("\(Int(fl))mm") }
        if let fn = fNumber { parts.append("f/\(String(format: "%.1f", fn))") }
        if let et = exposureTime {
            parts.append(et >= 1 ? "\(Int(et))s" : "1/\(Int(1/et))s")
        }
        if let iso = isoSpeed?.first { parts.append("ISO\(iso)") }

        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Services/ExifReaderService.swift && git commit -m "feat: add ExifReaderService via CGImageSource"
```

---

### Task 4.2: Create GlassExportService

**Files:**
- Create: `liquidglassphotoframe/Services/GlassExportService.swift`

- [ ] **Step 1: Write GlassExportService.swift**

```swift
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct GlassExportService {

    static func exportFrame(
        image: UIImage,
        config: FrameConfig,
        previewWidth: CGFloat
    ) async -> UIImage? {
        let dynamicScale = computeScale(sourceImage: image, previewWidth: previewWidth)

        guard let cgInput = image.cgImage else { return nil }
        let ciInput = CIImage(cgImage: cgInput).oriented(.up)
        let extent = ciInput.extent
        let radius = Float(config.blurRadius / previewWidth * extent.width * 0.01)

        let context = CIContext(options: [.workingColorSpace: NSNull()])

        // Step 1: Gaussian Blur base
        let gaussianBlur = CIFilter.gaussianBlur()
        gaussianBlur.inputImage = ciInput
        gaussianBlur.radius = radius
        guard let blurred = gaussianBlur.outputImage else { return nil }

        // Step 2: Radial gradient mask for variable blur
        let radialGradient = CIFilter.radialGradient()
        radialGradient.center = CGPoint(x: extent.midX, y: extent.midY)
        radialGradient.radius0 = Float(min(extent.width, extent.height) * 0.25)
        radialGradient.radius1 = Float(max(extent.width, extent.height) * 0.7)
        radialGradient.color0 = CIColor.black   // center sharp
        radialGradient.color1 = CIColor.white   // edges blurred
        guard let mask = radialGradient.outputImage?.cropped(to: extent) else { return nil }

        // Step 3: CIMaskedVariableBlur for progressive blur
        guard let variableBlur = CIFilter(name: "CIMaskedVariableBlur") else { return nil }
        variableBlur.setValue(ciInput, forKey: kCIInputImageKey)
        variableBlur.setValue(mask, forKey: "inputMask")
        variableBlur.setValue(radius * 0.7, forKey: kCIInputRadiusKey)
        guard let variablyBlurred = variableBlur.outputImage?.cropped(to: extent) else { return nil }

        // Step 4: Blend sharp + variable blur via mask
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = blurred
        blendFilter.backgroundImage = variablyBlurred
        blendFilter.maskImage = mask
        guard let blended = blendFilter.outputImage else { return nil }

        // Step 5: Sheen overlay (simulates light refraction)
        let sheenGradient = CIFilter.smoothLinearGradient()
        sheenGradient.color0 = CIColor(red: 1, green: 1, blue: 1, alpha: 0.12)
        sheenGradient.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 0)
        sheenGradient.point0 = CGPoint(x: 0, y: extent.maxY)
        sheenGradient.point1 = CGPoint(x: extent.maxX, y: extent.minY)
        guard let sheen = sheenGradient.outputImage?.cropped(to: extent) else { return nil }

        let withSheen = sheen.composited(over: blended)

        // Step 6: Subtle highlight boost
        let highlight = CIFilter.highlightShadowAdjust()
        highlight.inputImage = withSheen
        highlight.highlightAmount = 0.15
        highlight.shadowAmount = 0.0
        guard let finalImage = highlight.outputImage else { return nil }

        // Render
        guard let cg = context.createCGImage(finalImage, from: extent) else { return nil }
        return UIImage(cgImage: cg, scale: dynamicScale, orientation: .up)
    }

    static func computeScale(sourceImage: UIImage, previewWidth: CGFloat) -> CGFloat {
        let sourcePixels = max(sourceImage.size.width, sourceImage.size.height) * sourceImage.scale
        let rawScale = sourcePixels / max(previewWidth, 1)
        return min(8.0, max(1.0, rawScale))
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Services/GlassExportService.swift && git commit -m "feat: add GlassExportService with 6-layer CI filter chain and dynamic scale"
```

---

### Task 4.3: Create PhotoLibraryService

**Files:**
- Create: `liquidglassphotoframe/Services/PhotoLibraryService.swift`

- [ ] **Step 1: Write PhotoLibraryService.swift**

```swift
import UIKit
import Photos

struct PhotoLibraryService {
    static func saveImage(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            if let data = image.pngData() {
                request.addResource(with: .photo, data: data, options: nil)
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add Services/PhotoLibraryService.swift && git commit -m "feat: add PhotoLibraryService for saving to Photos"
```

---

### Task 4.4: Wire Export Flow in ExportTab

**Files:**
- Modify: `liquidglassphotoframe/Views/ExportTab.swift`

- [ ] **Step 1: Replace placeholder exportImage() method**

Replace the `exportImage()` method in ExportTab.swift:

```swift
private func exportImage() {
    guard let image else { return }
    isExporting = true
    Task {
        let exported = await GlassExportService.exportFrame(
            image: image,
            config: config,
            previewWidth: previewWidth
        )
        await MainActor.run {
            isExporting = false
            if let exported {
                Task {
                    do {
                        try await PhotoLibraryService.saveImage(exported)
                        exportMessage = "Saved to Photos"
                    } catch {
                        exportMessage = "Save failed: \(error.localizedDescription)"
                    }
                }
            } else {
                exportMessage = "Export failed"
            }
        }
    }
}
```

Also update the `@State private var config` line to:
```swift
@State private var config = FrameConfig()
```

- [ ] **Step 2: Commit**

```bash
git add Views/ExportTab.swift && git commit -m "feat: wire export pipeline from ExportTab through GlassExportService to Photos"
```

---

## Milestone 5: Polish & Final Integration

### Task 5.1: Fix ContentView Config Flow

**Files:**
- Modify: `liquidglassphotoframe/ContentView.swift`

- [ ] **Step 1: Ensure config flows correctly**

The config should be `@State` in ContentView and passed as `@Binding` to LayoutTab and StyleParamsTab. ExportTab is read-only. Verify the bindings work end-to-end.

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project liquidglassphotoframe.xcodeproj -scheme liquidglassphotoframe -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | grep -E "(error:|BUILD)" | head -10
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit any fixes**

```bash
git add -A && git commit -m "fix: final binding wiring and build fixes"
```

---

### Task 5.2: Full Build + Simulator Test

- [ ] **Step 1: Clean build**

```bash
xcodebuild -project liquidglassphotoframe.xcodeproj -scheme liquidglassphotoframe -destination 'platform=iOS Simulator,name=iPhone 16 Pro' clean build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 2: Launch simulator and take screenshot**

```bash
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null
open -a Simulator
```

- [ ] **Step 3: Build and run on simulator**

```bash
xcodebuild -project liquidglassphotoframe.xcodeproj -scheme liquidglassphotoframe -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test 2>&1 | tail -5
```

- [ ] **Step 4: Final commit**

```bash
git add -A && git commit -m "chore: final polish, clean build verified"
```

---

## Checklist Summary

| Milestone | Tasks | Status |
|-----------|-------|--------|
| M1: Data Model | 1.1 - 1.3 | Pending |
| M2: Core Views | 2.1 - 2.5 | Pending |
| M3: Tab Views | 3.1 - 3.4 | Pending |
| M4: Services | 4.1 - 4.4 | Pending |
| M5: Polish | 5.1 - 5.2 | Pending |

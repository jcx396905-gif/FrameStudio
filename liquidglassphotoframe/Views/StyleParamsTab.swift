import SwiftUI

struct StyleParamsTab: View {
    @Binding var config: FrameConfig
    let rawPhotoData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L.t("质感参数", "Style"))
            brandSection
            cameraModelSection
            exifSection
            spacingSection
        }
        .padding(.top, 12)
    }

    private var brandSection: some View {
        groupBox {
            Text(L.t("品牌 Logo", "Brand Logo"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(BrandData.all, id: \.self) { brand in
                    Button {
                        withAnimation(.spring(response: 0.3)) { config.selectedBrand = brand }
                    } label: {
                        Text(BrandData.displayNames[brand] ?? brand)
                            .font(.system(size: 8, weight: .medium))
                            .lineLimit(1).minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(config.selectedBrand == brand ? Color(hex: "#D4A853").opacity(0.20) : Color.primary.opacity(0.035)))
                            .foregroundStyle(config.selectedBrand == brand ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(config.selectedBrand == brand ? .regular : .clear, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            GlassSlider(value: $config.logoSizeScale, range: 0.035...0.14, label: L.t("Logo 大小", "Logo Size"), format: "%.0f%%")

            HStack {
                Text(L.t("显示 Logo", "Show Logo")).font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $config.logoVisible).labelsHidden().tint(Color(hex: "#D4A853"))
            }
        }
    }

    private var cameraModelSection: some View {
        groupBox {
            Text(L.t("相机型号", "Camera Model")).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            HStack {
                Text(L.t("显示型号", "Show Model")).font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $config.cameraModelVisible).labelsHidden().tint(Color(hex: "#D4A853"))
            }
            TextField(L.t("相机型号", "Camera Model"), text: $config.cameraModel)
                .font(.system(size: 13)).padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                .foregroundStyle(.primary)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8))
            HStack {
                Text(L.t("斜体", "Italic")).font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $config.cameraModelItalic).labelsHidden().tint(Color(hex: "#D4A853"))
            }
        }
    }

    private var exifSection: some View {
        groupBox {
            Text(L.t("EXIF 参数", "EXIF Params")).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            HStack {
                Text(L.t("显示参数", "Show Params")).font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $config.exifVisible).labelsHidden().tint(Color(hex: "#D4A853"))
            }

            Button {
                if let data = rawPhotoData {
                    if let exif = ExifReaderService.extractExif(from: data) { config.exifText = exif }
                    if let model = ExifReaderService.extractCameraModel(from: data) {
                        config.cameraModel = model; config.cameraModelVisible = true
                    }
                    if let brand = ExifReaderService.extractCameraBrand(from: data) {
                        config.selectedBrand = brand
                        config.logoVisible = true
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "camera.metering.center.weighted").font(.system(size: 11))
                    Text(L.t("识别 EXIF", "Detect EXIF")).font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
            }
            .buttonStyle(.plain).disabled(rawPhotoData == nil)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))

            TextField(L.t("EXIF 文字", "EXIF Text"), text: $config.exifText)
                .font(.system(size: 13)).padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                .foregroundStyle(.primary)

            GlassSlider(value: $config.exifFontScale, range: 0.016...0.034, label: L.t("字号", "Font Size"), format: "%.0f%%")

            HStack {
                Text(L.t("字体", "Font")).font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Picker(L.t("字体", "Font"), selection: $config.exifFontName) {
                    Text(L.t("标准", "Standard")).tag("Standard")
                    Text(L.t("衬线", "Serif")).tag("Serif")
                    Text(L.t("等宽", "Monospace")).tag("Monospace")
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var spacingSection: some View {
        groupBox {
            Text(L.t("间距", "Spacing")).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            GlassSlider(value: $config.logoToPhotoScale, range: 0.012...0.10, label: L.t("Logo 距照片", "Logo to Photo"), format: "%.0f%%")
            GlassSlider(value: $config.textToLogoScale, range: 0...0.05, label: L.t("文字距 Logo", "Text to Logo"), format: "%.0f%%")
            GlassSlider(value: $config.bottomMarginScale, range: 0.025...0.12, label: L.t("底部边距", "Bottom Margin"), format: "%.0f%%")
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary).kerning(2).textCase(.uppercase)
    }

    @ViewBuilder
    private func groupBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.035)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

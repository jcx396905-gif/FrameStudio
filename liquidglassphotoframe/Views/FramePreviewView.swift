import SwiftUI

struct FramePreviewView: View {
    let image: UIImage?
    let config: FrameConfig

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let layout = FrameRenderLayout.make(
                canvasWidth: w,
                imageSize: image?.size ?? CGSize(width: 1, height: 1),
                config: config,
                maxHeight: h
            )

            ZStack {
                backgroundLayer(width: layout.canvasSize.width, height: layout.canvasSize.height)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: layout.photoRect.width, height: layout.photoRect.height)
                        .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius))
                        .shadow(color: .black.opacity(config.shadowDepth),
                                radius: w * 0.03 * config.shadowDepth, y: w * 0.02 * config.shadowDepth)
                        .position(x: layout.photoRect.midX, y: layout.photoRect.midY)
                }

                if image != nil, let logoRect = layout.logoRect {
                    BrandLogoView(brand: config.selectedBrand, height: logoRect.height)
                        .position(x: logoRect.midX, y: logoRect.midY)
                }

                if image != nil {
                    if let modelTextRect = layout.modelTextRect {
                        Text(config.cameraModel)
                            .font(.system(size: w * config.exifFontScale * 0.9, weight: .semibold))
                            .italic(config.cameraModelItalic)
                            .foregroundStyle(.primary)
                            .kerning(1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(width: modelTextRect.width, height: modelTextRect.height)
                            .position(x: modelTextRect.midX, y: modelTextRect.midY)
                    }
                    if let exifTextRect = layout.exifTextRect {
                        Text(config.exifText)
                            .font(exifFont(size: w * config.exifFontScale))
                            .foregroundStyle(.secondary)
                            .kerning(1.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(width: exifTextRect.width, height: exifTextRect.height)
                            .position(x: exifTextRect.midX, y: exifTextRect.midY)
                    }
                }
            }
            .frame(width: layout.canvasSize.width, height: layout.canvasSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .frame(width: w, height: h, alignment: .top)
        }
    }

    @ViewBuilder
    private func backgroundLayer(width: CGFloat, height: CGFloat) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .blur(radius: previewBlurRadius)
                .brightness(backgroundBrightness)
                .saturation(backgroundSaturation)
                .overlay(backgroundOverlay)
                .clipped()
        } else {
            Color(uiColor: .secondarySystemBackground)
        }
    }

    private var previewBlurRadius: CGFloat {
        switch config.backgroundMode {
        case .original:
            return config.blurRadius
        case .none:
            return max(config.blurRadius * 1.15, 34)
        case .custom:
            return max(config.blurRadius * 0.85, 22)
        }
    }

    private var backgroundBrightness: Double {
        switch config.backgroundMode {
        case .original:
            return -0.04
        case .none:
            return -0.13
        case .custom:
            return 0.02
        }
    }

    private var backgroundSaturation: Double {
        switch config.backgroundMode {
        case .original:
            return 1.0
        case .none:
            return 0.72
        case .custom:
            return 1.14
        }
    }

    @ViewBuilder
    private var backgroundOverlay: some View {
        switch config.backgroundMode {
        case .original:
            Color.clear
        case .none:
            ZStack {
                Color.white.opacity(0.055)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.03),
                        Color.black.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .custom:
            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color(hex: "#D4A853").opacity(0.13),
                    Color.black.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func exifFont(size: CGFloat) -> Font {
        switch config.exifFontName {
        case "Serif":
            return .system(size: size, weight: .light, design: .serif)
        case "Monospace":
            return .system(size: size, weight: .light, design: .monospaced)
        default:
            return .system(size: size, weight: .light)
        }
    }
}

struct BrandLogoView: View {
    let brand: String
    let height: CGFloat
    var body: some View {
        Image(brand)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: height, height: height)
    }
}

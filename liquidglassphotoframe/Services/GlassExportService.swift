import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import OSLog

private let exportLog = Logger(subsystem: "x.liquidglassphotoframe", category: "export")

struct GlassExportService {

    static func exportFrame(
        image: UIImage,
        config: FrameConfig,
        previewWidth: CGFloat
    ) async -> UIImage? {
        let canvasW = exportWidth(sourceImage: image, previewWidth: previewWidth)
        let layout = FrameRenderLayout.make(canvasWidth: canvasW, imageSize: image.size, config: config)
        let canvasRect = CGRect(origin: .zero, size: layout.canvasSize)

        guard let backgroundCG = renderBackground(
            image: image,
            targetSize: layout.canvasSize,
            backgroundMode: config.backgroundMode,
            blurRadius: config.blurRadius
        ) else {
            exportLog.error("background render failed — canvas: \(layout.canvasSize.width)x\(layout.canvasSize.height)")
            return nil
        }

        exportLog.info("exporting \(layout.canvasSize.width)x\(layout.canvasSize.height) frame")

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1.0
        fmt.opaque = true

        let renderer = UIGraphicsImageRenderer(size: layout.canvasSize, format: fmt)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.interpolationQuality = .high
            cg.draw(backgroundCG, in: canvasRect)

            let shadowPath = UIBezierPath(roundedRect: layout.photoRect, cornerRadius: layout.cornerRadius).cgPath
            cg.saveGState()
            cg.setShadow(
                offset: CGSize(width: 0, height: canvasW * 0.02 * config.shadowDepth),
                blur: canvasW * 0.03 * config.shadowDepth,
                color: UIColor.black.withAlphaComponent(config.shadowDepth).cgColor
            )
            cg.setFillColor(UIColor.black.cgColor)
            cg.addPath(shadowPath)
            cg.fillPath()
            cg.restoreGState()

            let clipPath = UIBezierPath(roundedRect: layout.photoRect, cornerRadius: layout.cornerRadius)
            cg.saveGState(); clipPath.addClip(); image.draw(in: layout.photoRect); cg.restoreGState()

            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.16).cgColor)
            cg.setLineWidth(max(canvasW * 0.0012, 1))
            clipPath.stroke()

            if let logoRect = layout.logoRect {
                drawLogo(cg: cg, brand: config.selectedBrand, cx: logoRect.midX, top: logoRect.minY, d: logoRect.height)
            }
            if let modelTextRect = layout.modelTextRect {
                drawLabel(cg: cg, text: config.cameraModel, cx: modelTextRect.midX, top: modelTextRect.minY,
                          size: canvasW * config.exifFontScale * 0.9,
                          weight: .semibold,
                          style: config.cameraModelItalic ? .italic : .normal,
                          maxW: modelTextRect.width)
            }
            if let exifTextRect = layout.exifTextRect {
                drawLabel(cg: cg, text: config.exifText, cx: exifTextRect.midX, top: exifTextRect.minY,
                          size: canvasW * config.exifFontScale,
                          weight: .light,
                          style: fontStyle(for: config.exifFontName),
                          maxW: exifTextRect.width)
            }
        }
    }

    private static func renderBackground(
        image: UIImage,
        targetSize: CGSize,
        backgroundMode: BackgroundMode,
        blurRadius: CGFloat
    ) -> CGImage? {
        guard let cgImg = image.cgImage else { return nil }
        let ci = CIImage(cgImage: cgImg).oriented(.up)
        let ext = ci.extent
        let ctx = CIContext()
        let settings = backgroundSettings(mode: backgroundMode, blurRadius: blurRadius)

        let blurred: CIImage
        if settings.blurRadius > 0 {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = ci
            blur.radius = Float(min(ext.width, ext.height) * 0.08 * settings.blurRadius / 100)
            guard let output = blur.outputImage?.cropped(to: ext) else { return nil }
            blurred = output
        } else {
            blurred = ci
        }

        let controls = CIFilter.colorControls()
        controls.inputImage = blurred
        controls.saturation = Float(settings.saturation)
        controls.brightness = Float(settings.brightness)
        guard let final = controls.outputImage?.cropped(to: ext) else { return nil }
        guard let out = ctx.createCGImage(final, from: ext) else { return nil }

        let fill = aspectFill(source: ext.size, target: targetSize)
        let r = UIGraphicsImageRenderer(size: targetSize, format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1.0; f.opaque = true; return f }())
        return r.image { rendererContext in
            let cg = rendererContext.cgContext
            cg.interpolationQuality = .high
            cg.draw(out, in: fill)
            drawBackgroundOverlay(cg: cg, rect: CGRect(origin: .zero, size: targetSize), mode: backgroundMode)
        }.cgImage
    }

    private struct BackgroundSettings {
        let blurRadius: CGFloat
        let brightness: CGFloat
        let saturation: CGFloat
    }

    private static func backgroundSettings(mode: BackgroundMode, blurRadius: CGFloat) -> BackgroundSettings {
        switch mode {
        case .original:
            return BackgroundSettings(blurRadius: blurRadius, brightness: -0.04, saturation: 1.0)
        case .none:
            return BackgroundSettings(blurRadius: max(blurRadius * 1.15, 34), brightness: -0.13, saturation: 0.72)
        case .custom:
            return BackgroundSettings(blurRadius: max(blurRadius * 0.85, 22), brightness: 0.02, saturation: 1.14)
        }
    }

    private static func drawBackgroundOverlay(cg: CGContext, rect: CGRect, mode: BackgroundMode) {
        switch mode {
        case .original:
            return
        case .none:
            cg.setFillColor(UIColor.white.withAlphaComponent(0.055).cgColor)
            cg.fill(rect)
            drawLinearGradient(
                cg: cg,
                rect: rect,
                colors: [
                    UIColor.white.withAlphaComponent(0.18),
                    UIColor.white.withAlphaComponent(0.03),
                    UIColor.black.withAlphaComponent(0.24)
                ]
            )
        case .custom:
            drawLinearGradient(
                cg: cg,
                rect: rect,
                colors: [
                    UIColor.white.withAlphaComponent(0.08),
                    UIColor(red: 0.83, green: 0.66, blue: 0.33, alpha: 0.13),
                    UIColor.black.withAlphaComponent(0.16)
                ]
            )
        }
    }

    private static func drawLinearGradient(cg: CGContext, rect: CGRect, colors: [UIColor]) {
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map(\.cgColor) as CFArray,
            locations: nil
        ) else { return }
        cg.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            options: []
        )
    }

    private static func drawLogo(cg: CGContext, brand: String, cx: CGFloat, top: CGFloat, d: CGFloat) {
        guard let logoImage = UIImage(named: brand) else { return }
        let logoSize = logoImage.size
        let aspect = logoSize.width / max(logoSize.height, 1)
        let rect: CGRect
        if aspect >= 1 {
            let h = d / aspect
            rect = CGRect(x: cx - d/2, y: top + (d - h)/2, width: d, height: h)
        } else {
            let w = d * aspect
            rect = CGRect(x: cx - w/2, y: top, width: w, height: d)
        }
        logoImage.draw(in: rect)
    }

    private static func drawLabel(
        cg: CGContext,
        text: String,
        cx: CGFloat,
        top: CGFloat,
        size: CGFloat,
        weight: UIFont.Weight,
        style: FontStyle,
        maxW: CGFloat
    ) {
        let ps = NSMutableParagraphStyle(); ps.alignment = .center
        let attr: [NSAttributedString.Key: Any] = [
            .font: font(size: size, weight: weight, style: style),
            .foregroundColor: UIColor.white, .paragraphStyle: ps, .kern: 1.2
        ]
        text.draw(in: CGRect(x: cx - maxW/2, y: top, width: maxW, height: size * 1.8), withAttributes: attr)
    }

    private enum FontStyle {
        case normal
        case italic
        case serif
        case monospace
    }

    private static func fontStyle(for name: String) -> FontStyle {
        switch name {
        case "Serif":
            return .serif
        case "Monospace":
            return .monospace
        default:
            return .normal
        }
    }

    private static func font(size: CGFloat, weight: UIFont.Weight, style: FontStyle) -> UIFont {
        switch style {
        case .normal:
            return .systemFont(ofSize: size, weight: weight)
        case .italic:
            return .italicSystemFont(ofSize: size)
        case .serif:
            return UIFont(name: "TimesNewRomanPSMT", size: size) ?? .systemFont(ofSize: size, weight: weight)
        case .monospace:
            return .monospacedSystemFont(ofSize: size, weight: weight)
        }
    }

    private static func aspectFill(source: CGSize, target: CGSize) -> CGRect {
        let s = max(target.width / source.width, target.height / source.height)
        return CGRect(x: (target.width - source.width * s)/2,
                      y: (target.height - source.height * s)/2,
                      width: source.width * s, height: source.height * s)
    }

    private static func exportWidth(sourceImage: UIImage, previewWidth: CGFloat) -> CGFloat {
        let safePreviewWidth = max(previewWidth, 1)
        let sourcePixels = max(sourceImage.size.width, sourceImage.size.height) * sourceImage.scale
        let scale = min(8, max(1, sourcePixels / safePreviewWidth))
        return min(4200, max(1800, safePreviewWidth * scale))
    }
}

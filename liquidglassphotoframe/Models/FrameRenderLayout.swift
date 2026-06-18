import CoreGraphics

struct FrameRenderLayout {
    let canvasSize: CGSize
    let photoRect: CGRect
    let maxPhotoWidth: CGFloat
    let cornerRadius: CGFloat
    let logoRect: CGRect?
    let modelTextRect: CGRect?
    let exifTextRect: CGRect?

    static func make(
        canvasWidth: CGFloat,
        imageSize: CGSize,
        config: FrameConfig,
        maxHeight: CGFloat? = nil
    ) -> FrameRenderLayout {
        let padding = horizontalPadding(canvasWidth: canvasWidth, config: config)
        let maxPhotoWidth = canvasWidth - padding * 2
        let targetPhotoWidth = min(maxPhotoWidth, canvasWidth * config.photoScale)
        let aspect = imageSize.height / max(imageSize.width, 1)
        let naturalPhotoHeight = targetPhotoWidth * aspect
        let photoTop = padding * 0.68
        let logoSize = maxPhotoWidth * config.logoSizeScale
        let logoGap = config.logoVisible ? canvasWidth * config.logoToPhotoScale : 0
        let textGap = (config.cameraModelVisible || config.exifVisible) ? canvasWidth * config.textToLogoScale : 0
        let modelHeight = config.cameraModelVisible ? canvasWidth * config.exifFontScale * 1.18 : 0
        let exifHeight = config.exifVisible ? canvasWidth * config.exifFontScale * 1.38 : 0
        let bottomMargin = canvasWidth * config.bottomMarginScale

        let metadataHeight = logoGap
            + (config.logoVisible ? logoSize : 0)
            + textGap
            + modelHeight
            + exifHeight
            + bottomMargin
        let availablePhotoHeight = maxHeight.map {
            max($0 - photoTop - metadataHeight, canvasWidth * 0.32)
        }
        let photoHeight = min(naturalPhotoHeight, availablePhotoHeight ?? naturalPhotoHeight)
        let photoWidth = naturalPhotoHeight > photoHeight
            ? min(targetPhotoWidth, photoHeight / max(aspect, 0.001))
            : targetPhotoWidth
        let photoRect = CGRect(
            x: (canvasWidth - photoWidth) / 2,
            y: photoTop,
            width: photoWidth,
            height: photoHeight
        )

        var cursorY = photoRect.maxY
        let logoRect: CGRect?
        if config.logoVisible {
            cursorY += logoGap
            logoRect = CGRect(
                x: (canvasWidth - logoSize) / 2,
                y: cursorY,
                width: logoSize,
                height: logoSize
            )
            cursorY += logoSize
        } else {
            logoRect = nil
        }

        if config.cameraModelVisible || config.exifVisible {
            cursorY += textGap
        }

        let modelTextRect: CGRect?
        if config.cameraModelVisible {
            modelTextRect = CGRect(
                x: (canvasWidth - maxPhotoWidth) / 2,
                y: cursorY,
                width: maxPhotoWidth,
                height: modelHeight
            )
            cursorY += modelHeight
        } else {
            modelTextRect = nil
        }

        let exifTextRect: CGRect?
        if config.exifVisible {
            exifTextRect = CGRect(
                x: (canvasWidth - maxPhotoWidth) / 2,
                y: cursorY,
                width: maxPhotoWidth,
                height: exifHeight
            )
            cursorY += exifHeight
        } else {
            exifTextRect = nil
        }

        let canvasHeight = cursorY + bottomMargin
        return FrameRenderLayout(
            canvasSize: CGSize(width: canvasWidth, height: canvasHeight),
            photoRect: photoRect,
            maxPhotoWidth: maxPhotoWidth,
            cornerRadius: canvasWidth * config.cornerRadiusScale,
            logoRect: logoRect,
            modelTextRect: modelTextRect,
            exifTextRect: exifTextRect
        )
    }

    private static func horizontalPadding(canvasWidth: CGFloat, config: FrameConfig) -> CGFloat {
        let base = canvasWidth * 0.045
        let extra = max(0, 0.90 - config.photoScale) * canvasWidth * 0.22
        return min(max(base + extra, canvasWidth * 0.035), canvasWidth * 0.075)
    }
}

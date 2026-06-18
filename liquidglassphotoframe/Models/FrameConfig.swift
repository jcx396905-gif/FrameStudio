//
//  FrameConfig.swift
//  liquidglassphotoframe
//

import Foundation
import Observation
import UIKit

enum BackgroundMode: String, Codable, CaseIterable {
    case original, custom, none
}

extension BackgroundMode: CustomStringConvertible {
    var description: String {
        switch self {
        case .original: return L.t("原背景", "Original")
        case .custom: return L.t("柔光", "Soft")
        case .none: return L.t("无背景", "Glass")
        }
    }
}

enum ExportFormat: String, Codable, CaseIterable {
    case png, heif, jpeg
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

@Observable
final class FrameConfig: Codable {
    var backgroundMode: BackgroundMode = .none
    var blurRadius: CGFloat = 40
    var photoScale: CGFloat = 0.88
    var cornerRadiusScale: CGFloat = 0.016
    var shadowDepth: CGFloat = 0.4
    var selectedBrand: String = "sony"
    var logoSizeScale: CGFloat = 0.055
    var logoVisible: Bool = true
    var cameraModel: String = "A7R V"
    var cameraModelVisible: Bool = true
    var cameraModelItalic: Bool = false
    var exifText: String = "200mm f/4 1/800s ISO400"
    var exifVisible: Bool = true
    var exifFontName: String = "Standard"
    var exifFontScale: CGFloat = 0.022
    var logoToPhotoScale: CGFloat = 0.035
    var textToLogoScale: CGFloat = 0.010
    var bottomMarginScale: CGFloat = 0.045
    var exportFormat: ExportFormat = .png
    var exportQuality: CGFloat = 1.0

    var persistenceSignature: String {
        [
            backgroundMode.rawValue,
            String(Double(blurRadius)),
            String(Double(photoScale)),
            String(Double(cornerRadiusScale)),
            String(Double(shadowDepth)),
            selectedBrand,
            String(Double(logoSizeScale)),
            String(logoVisible),
            cameraModel,
            String(cameraModelVisible),
            String(cameraModelItalic),
            exifText,
            String(exifVisible),
            exifFontName,
            String(Double(exifFontScale)),
            String(Double(logoToPhotoScale)),
            String(Double(textToLogoScale)),
            String(Double(bottomMarginScale)),
            exportFormat.rawValue,
            String(Double(exportQuality))
        ].joined(separator: "|")
    }

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

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        backgroundMode = try c.decodeIfPresent(BackgroundMode.self, forKey: .backgroundMode) ?? backgroundMode
        blurRadius = try c.decodeIfPresent(CGFloat.self, forKey: .blurRadius) ?? blurRadius
        photoScale = try c.decodeIfPresent(CGFloat.self, forKey: .photoScale) ?? photoScale
        cornerRadiusScale = try c.decodeIfPresent(CGFloat.self, forKey: .cornerRadiusScale) ?? cornerRadiusScale
        shadowDepth = try c.decodeIfPresent(CGFloat.self, forKey: .shadowDepth) ?? shadowDepth
        selectedBrand = try c.decodeIfPresent(String.self, forKey: .selectedBrand) ?? selectedBrand
        logoSizeScale = try c.decodeIfPresent(CGFloat.self, forKey: .logoSizeScale) ?? logoSizeScale
        logoVisible = try c.decodeIfPresent(Bool.self, forKey: .logoVisible) ?? logoVisible
        cameraModel = try c.decodeIfPresent(String.self, forKey: .cameraModel) ?? cameraModel
        cameraModelVisible = try c.decodeIfPresent(Bool.self, forKey: .cameraModelVisible) ?? cameraModelVisible
        cameraModelItalic = try c.decodeIfPresent(Bool.self, forKey: .cameraModelItalic) ?? cameraModelItalic
        exifText = try c.decodeIfPresent(String.self, forKey: .exifText) ?? exifText
        exifVisible = try c.decodeIfPresent(Bool.self, forKey: .exifVisible) ?? exifVisible
        exifFontName = try c.decodeIfPresent(String.self, forKey: .exifFontName) ?? exifFontName
        exifFontScale = try c.decodeIfPresent(CGFloat.self, forKey: .exifFontScale) ?? exifFontScale
        logoToPhotoScale = try c.decodeIfPresent(CGFloat.self, forKey: .logoToPhotoScale) ?? logoToPhotoScale
        textToLogoScale = try c.decodeIfPresent(CGFloat.self, forKey: .textToLogoScale) ?? textToLogoScale
        bottomMarginScale = try c.decodeIfPresent(CGFloat.self, forKey: .bottomMarginScale) ?? bottomMarginScale
        exportFormat = try c.decodeIfPresent(ExportFormat.self, forKey: .exportFormat) ?? exportFormat
        exportQuality = try c.decodeIfPresent(CGFloat.self, forKey: .exportQuality) ?? exportQuality
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(backgroundMode, forKey: .backgroundMode)
        try c.encode(blurRadius, forKey: .blurRadius)
        try c.encode(photoScale, forKey: .photoScale)
        try c.encode(cornerRadiusScale, forKey: .cornerRadiusScale)
        try c.encode(shadowDepth, forKey: .shadowDepth)
        try c.encode(selectedBrand, forKey: .selectedBrand)
        try c.encode(logoSizeScale, forKey: .logoSizeScale)
        try c.encode(logoVisible, forKey: .logoVisible)
        try c.encode(cameraModel, forKey: .cameraModel)
        try c.encode(cameraModelVisible, forKey: .cameraModelVisible)
        try c.encode(cameraModelItalic, forKey: .cameraModelItalic)
        try c.encode(exifText, forKey: .exifText)
        try c.encode(exifVisible, forKey: .exifVisible)
        try c.encode(exifFontName, forKey: .exifFontName)
        try c.encode(exifFontScale, forKey: .exifFontScale)
        try c.encode(logoToPhotoScale, forKey: .logoToPhotoScale)
        try c.encode(textToLogoScale, forKey: .textToLogoScale)
        try c.encode(bottomMarginScale, forKey: .bottomMarginScale)
        try c.encode(exportFormat, forKey: .exportFormat)
        try c.encode(exportQuality, forKey: .exportQuality)
    }

    func copy() -> FrameConfig {
        let copy = FrameConfig()
        copy.apply(self)
        return copy
    }

    func resetToDefaults() {
        apply(FrameConfig())
    }

    func normalizeValues() {
        blurRadius = blurRadius.clamped(to: 0...100)
        photoScale = photoScale.clamped(to: 0.72...0.94)
        cornerRadiusScale = cornerRadiusScale.clamped(to: 0...0.04)
        shadowDepth = shadowDepth.clamped(to: 0...1)
        if !BrandData.all.contains(selectedBrand) {
            selectedBrand = "sony"
        }
        logoSizeScale = logoSizeScale.clamped(to: 0.035...0.14)
        if exifFontScale <= 0.017 {
            exifFontScale = 0.022
        } else {
            exifFontScale = exifFontScale.clamped(to: 0.016...0.034)
        }
        if logoToPhotoScale > 0.12 {
            logoToPhotoScale = 0.035
        } else {
            logoToPhotoScale = logoToPhotoScale.clamped(to: 0.012...0.10)
        }
        textToLogoScale = textToLogoScale.clamped(to: 0...0.05)
        bottomMarginScale = bottomMarginScale.clamped(to: 0.025...0.12)
        exportQuality = exportQuality.clamped(to: 0.1...1.0)
        if !["Standard", "Serif", "Monospace"].contains(exifFontName) {
            exifFontName = "Standard"
        }
    }

    func apply(_ other: FrameConfig) {
        backgroundMode = other.backgroundMode
        blurRadius = other.blurRadius
        photoScale = other.photoScale
        cornerRadiusScale = other.cornerRadiusScale
        shadowDepth = other.shadowDepth
        selectedBrand = other.selectedBrand
        logoSizeScale = other.logoSizeScale
        logoVisible = other.logoVisible
        cameraModel = other.cameraModel
        cameraModelVisible = other.cameraModelVisible
        cameraModelItalic = other.cameraModelItalic
        exifText = other.exifText
        exifVisible = other.exifVisible
        exifFontName = other.exifFontName
        exifFontScale = other.exifFontScale
        logoToPhotoScale = other.logoToPhotoScale
        textToLogoScale = other.textToLogoScale
        bottomMarginScale = other.bottomMarginScale
        exportFormat = other.exportFormat
        exportQuality = other.exportQuality
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

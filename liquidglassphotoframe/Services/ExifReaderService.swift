//
//  ExifReaderService.swift
//  liquidglassphotoframe
//

import UIKit
import ImageIO
import UniformTypeIdentifiers

struct ExifReaderService {

    /// Extract EXIF from raw PhotosPicker data (preserves original metadata).
    /// UIImage re-encoding strips EXIF; CGImageSource from raw Data preserves it.
    static func extractExif(from data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }

        // Try EXIF dictionary first
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]

        let focalLength = (exif?[kCGImagePropertyExifFocalLength as String] as? Double)
            ?? (exif?["FocalLength"] as? Double)
        let fNumber = exif?[kCGImagePropertyExifFNumber as String] as? Double
        let exposureTime = exif?[kCGImagePropertyExifExposureTime as String] as? Double
        let isoSpeed = (exif?[kCGImagePropertyExifISOSpeedRatings as String] as? [Int])
            ?? (exif?["ISOSpeedRatings"] as? [Int])

        // Also try focal length in 35mm equivalent
        let focalLen35mm = exif?[kCGImagePropertyExifFocalLenIn35mmFilm as String] as? Int

        var parts: [String] = []

        // Focal length
        if let fl = focalLength {
            parts.append("\(Int(fl.rounded()))mm")
        } else if let fl35 = focalLen35mm {
            parts.append("\(fl35)mm")
        }

        // Aperture
        if let fn = fNumber {
            parts.append("f/\(String(format: "%.1f", fn))")
        }

        // Shutter speed
        if let et = exposureTime {
            if et >= 1 {
                parts.append("\(Int(et))s")
            } else {
                parts.append("1/\(Int(1.0 / et))s")
            }
        }

        // ISO
        if let iso = isoSpeed?.first {
            parts.append("ISO\(iso)")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// Read camera model from EXIF or TIFF tags
    static func extractCameraModel(from data: Data) -> String? {
        guard let properties = imageProperties(from: data) else { return nil }

        // TIFF dictionary (common for camera model)
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let model = tiff[kCGImagePropertyTIFFModel as String] as? String {
            return model
        }

        // EXIF LensModel
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let lens = exif[kCGImagePropertyExifLensModel as String] as? String {
            return lens
        }

        return nil
    }

    static func extractCameraBrand(from data: Data) -> String? {
        guard let properties = imageProperties(from: data) else { return nil }

        var candidates: [String] = []
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            candidates.appendString(tiff[kCGImagePropertyTIFFMake as String])
            candidates.appendString(tiff[kCGImagePropertyTIFFModel as String])
        }

        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            candidates.appendString(exif[kCGImagePropertyExifLensMake as String])
            candidates.appendString(exif[kCGImagePropertyExifLensModel as String])
            candidates.appendString(exif["LensMake"])
            candidates.appendString(exif["LensModel"])
        }

        return BrandData.brandID(matching: candidates)
    }

    private static func imageProperties(from data: Data) -> [String: Any]? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
    }
}

private extension Array where Element == String {
    mutating func appendString(_ value: Any?) {
        if let string = value as? String, !string.isEmpty {
            append(string)
        }
    }
}

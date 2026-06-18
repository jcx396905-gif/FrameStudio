//
//  PhotoLibraryService.swift
//  liquidglassphotoframe
//

import UIKit
import Photos
import ImageIO

struct PhotoLibraryService {
    static func saveImage(_ image: UIImage, format: ExportFormat = .png, quality: CGFloat = 1.0) async throws {
        guard await hasAddPermission() else {
            throw NSError(domain: "PhotoLibraryService", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "没有相册保存权限"])
        }

        let data: Data?
        switch format {
        case .jpeg:
            data = image.jpegData(compressionQuality: quality)
        case .heif:
            data = image.heicData(quality: quality)
        case .png:
            data = image.pngData()
        }
        guard let data else {
            throw NSError(domain: "PhotoLibraryService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "无法生成图片数据"])
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
        }
    }

    private static func hasAddPermission() async -> Bool {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch current {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let requested = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return requested == .authorized || requested == .limited
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

private extension UIImage {
    func heicData(quality: CGFloat) -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData, "public.heic" as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: quality
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}

//
//  BrandData.swift
//  liquidglassphotoframe
//

import Foundation

struct BrandData {
    static let all: [String] = [
        "sony", "nikon", "canon", "fujifilm",
        "hasselblad", "leica", "ricoh", "zeiss",
        "sigma", "panasonic", "tamron", "olympus",
        "dji", "kodak"
    ]

    static let displayNames: [String: String] = [
        "sony": "Sony",
        "nikon": "Nikon",
        "canon": "Canon",
        "fujifilm": "Fujifilm",
        "hasselblad": "Hasselblad",
        "leica": "Leica",
        "ricoh": "Ricoh",
        "zeiss": "Zeiss",
        "sigma": "Sigma",
        "panasonic": "Panasonic",
        "tamron": "Tamron",
        "olympus": "Olympus",
        "dji": "DJI",
        "kodak": "Kodak"
    ]

    static func brandID(matching values: [String]) -> String? {
        let haystack = values
            .map { $0.lowercased() }
            .joined(separator: " ")

        for brand in all {
            guard let aliases = aliases[brand] else { continue }
            if aliases.contains(where: { haystack.contains($0) }) {
                return brand
            }
        }

        return nil
    }

    private static let aliases: [String: [String]] = [
        "sony": ["sony"],
        "nikon": ["nikon"],
        "canon": ["canon"],
        "fujifilm": ["fujifilm", "fuji film", "fuji"],
        "hasselblad": ["hasselblad"],
        "leica": ["leica"],
        "ricoh": ["ricoh"],
        "zeiss": ["zeiss", "carl zeiss"],
        "sigma": ["sigma"],
        "panasonic": ["panasonic", "lumix"],
        "tamron": ["tamron"],
        "olympus": ["olympus", "om digital", "om system"],
        "dji": ["dji"],
        "kodak": ["kodak"]
    ]
}

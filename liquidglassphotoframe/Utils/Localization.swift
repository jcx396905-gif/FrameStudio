import Foundation

enum L {
    static var current: String {
        UserDefaults.standard.string(forKey: "language") ?? "zh"
    }

    static func t(_ zh: String, _ en: String) -> String {
        current == "zh" ? zh : en
    }
}

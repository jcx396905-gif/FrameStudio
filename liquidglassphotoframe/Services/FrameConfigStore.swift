import Foundation
import OSLog

private let configLog = Logger(subsystem: "x.liquidglassphotoframe", category: "config")

enum FrameConfigStore {
    private static let storageKey = "savedFrameConfig"

    static func load() -> FrameConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return FrameConfig()
        }

        do {
            let config = try JSONDecoder().decode(FrameConfig.self, from: data)
            config.normalizeValues()
            return config
        } catch {
            configLog.error("Failed to decode saved config: \(error.localizedDescription)")
            return FrameConfig()
        }
    }

    static func save(_ config: FrameConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            configLog.error("Failed to save config: \(error.localizedDescription)")
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

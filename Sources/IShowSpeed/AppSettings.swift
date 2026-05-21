import Foundation

enum SpeedUnitMode: String, CaseIterable, Sendable {
    case auto
    case kilobytes
    case megabytes

    var menuTitle: String {
        switch self {
        case .auto:
            "Auto"
        case .kilobytes:
            "KB/s"
        case .megabytes:
            "MB/s"
        }
    }
}

enum RefreshInterval: Double, CaseIterable, Sendable {
    case halfSecond = 0.5
    case oneSecond = 1.0
    case twoSeconds = 2.0

    var menuTitle: String {
        switch self {
        case .halfSecond:
            "0.5s"
        case .oneSecond:
            "1s"
        case .twoSeconds:
            "2s"
        }
    }
}

final class AppSettings: @unchecked Sendable {
    private enum Keys {
        static let refreshInterval = "refreshInterval"
        static let unitMode = "unitMode"
        static let launchAtLogin = "launchAtLogin"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var refreshInterval: RefreshInterval {
        get {
            let rawValue = defaults.double(forKey: Keys.refreshInterval)
            return RefreshInterval(rawValue: rawValue) ?? .oneSecond
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.refreshInterval)
        }
    }

    var unitMode: SpeedUnitMode {
        get {
            guard let rawValue = defaults.string(forKey: Keys.unitMode) else {
                return .auto
            }
            return SpeedUnitMode(rawValue: rawValue) ?? .auto
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.unitMode)
        }
    }

    var launchAtLogin: Bool {
        get {
            defaults.bool(forKey: Keys.launchAtLogin)
        }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
        }
    }
}

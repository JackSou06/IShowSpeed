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

enum DisplayMode: String, CaseIterable, Sendable {
    case realtimeSpeed
    case dormDailyUsage

    var menuTitle: String {
        switch self {
        case .realtimeSpeed:
            "Realtime Speed"
        case .dormDailyUsage:
            "Dorm Daily Usage"
        }
    }
}

enum DormAutoRefreshInterval: Double, CaseIterable, Sendable {
    case off = 0
    case fiveMinutes = 300
    case tenMinutes = 600

    var menuTitle: String {
        switch self {
        case .off:
            "Off"
        case .fiveMinutes:
            "5 min"
        case .tenMinutes:
            "10 min"
        }
    }
}

final class AppSettings: @unchecked Sendable {
    private enum Keys {
        static let refreshInterval = "refreshInterval"
        static let unitMode = "unitMode"
        static let launchAtLogin = "launchAtLogin"
        static let displayMode = "displayMode"
        static let dormAutoRefreshInterval = "dormAutoRefreshInterval"
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

    var displayMode: DisplayMode {
        get {
            guard let rawValue = defaults.string(forKey: Keys.displayMode) else {
                return .realtimeSpeed
            }
            return DisplayMode(rawValue: rawValue) ?? .realtimeSpeed
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.displayMode)
        }
    }

    var dormAutoRefreshInterval: DormAutoRefreshInterval {
        get {
            let rawValue = defaults.double(forKey: Keys.dormAutoRefreshInterval)
            return DormAutoRefreshInterval(rawValue: rawValue) ?? .off
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.dormAutoRefreshInterval)
        }
    }
}

import Foundation

struct StatusTitleContent: Equatable, Sendable {
    let text: String
    let isMultiline: Bool
}

struct StatusTitleFormatter: Sendable {
    private let speedFormatter: SpeedFormatter

    init(speedFormatter: SpeedFormatter = SpeedFormatter()) {
        self.speedFormatter = speedFormatter
    }

    func content(
        displayMode: DisplayMode,
        speed: NetworkSpeed,
        unitMode: SpeedUnitMode,
        dormTraffic: DailyTrafficUsage?,
        dormTrafficUnavailable: Bool
    ) -> StatusTitleContent {
        switch displayMode {
        case .realtimeSpeed:
            let download = speedFormatter.string(from: speed.downloadBytesPerSecond, unitMode: unitMode)
            let upload = speedFormatter.string(from: speed.uploadBytesPerSecond, unitMode: unitMode)
            return StatusTitleContent(text: "↓ \(download)\n↑ \(upload)", isMultiline: true)

        case .dormDailyUsage:
            if let dormTraffic {
                return StatusTitleContent(text: dormTraffic.total, isMultiline: false)
            }
            return StatusTitleContent(text: dormTrafficUnavailable ? "N/A" : "--", isMultiline: false)
        }
    }
}

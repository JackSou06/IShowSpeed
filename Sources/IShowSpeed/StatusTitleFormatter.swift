import Foundation

struct StatusTitleContent: Equatable, Sendable {
    let text: String
    let isMultiline: Bool
    let lines: [StatusTitleLine]
}

struct StatusTitleLine: Equatable, Sendable {
    let text: String
    let symbolName: String?
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
            return StatusTitleContent(
                text: "\(download)\n\(upload)",
                isMultiline: true,
                lines: [
                    StatusTitleLine(text: download, symbolName: "arrow.down.circle"),
                    StatusTitleLine(text: upload, symbolName: "arrow.up.circle")
                ]
            )

        case .dormDailyUsage:
            if let dormTraffic {
                return StatusTitleContent(
                    text: dormTraffic.total,
                    isMultiline: false,
                    lines: [StatusTitleLine(text: dormTraffic.total, symbolName: nil)]
                )
            }
            let text = dormTrafficUnavailable ? "N/A" : "--"
            return StatusTitleContent(
                text: text,
                isMultiline: false,
                lines: [StatusTitleLine(text: text, symbolName: nil)]
            )
        }
    }
}

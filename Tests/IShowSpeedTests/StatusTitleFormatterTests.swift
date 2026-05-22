import Foundation
import Testing
@testable import IShowSpeed

@Suite("StatusTitleFormatter")
struct StatusTitleFormatterTests {
    private let formatter = StatusTitleFormatter()

    @Test func formatsRealtimeSpeedAsTwoLines() {
        let content = formatter.content(
            displayMode: .realtimeSpeed,
            speed: NetworkSpeed(downloadBytesPerSecond: 1_536, uploadBytesPerSecond: 2_048),
            unitMode: .auto,
            dormTraffic: nil,
            dormTrafficUnavailable: false
        )

        #expect(content == StatusTitleContent(
            text: "1.5 KB/s\n2.0 KB/s",
            isMultiline: true,
            lines: [
                StatusTitleLine(text: "1.5 KB/s", symbolName: "arrow.down.circle"),
                StatusTitleLine(text: "2.0 KB/s", symbolName: "arrow.up.circle")
            ]
        ))
    }

    @Test func formatsDormDailyUsageAsSingleValueOnly() {
        let usage = DailyTrafficUsage(
            total: "6.66GB",
            download: "5.80GB",
            upload: "879.84MB",
            fetchedAt: Date(timeIntervalSince1970: 0)
        )

        let content = formatter.content(
            displayMode: .dormDailyUsage,
            speed: .zero,
            unitMode: .auto,
            dormTraffic: usage,
            dormTrafficUnavailable: false
        )

        #expect(content == StatusTitleContent(
            text: "6.66GB",
            isMultiline: false,
            lines: [StatusTitleLine(text: "6.66GB", symbolName: nil)]
        ))
    }

    @Test func formatsDormDailyUsagePlaceholderWhenNotLoaded() {
        let content = formatter.content(
            displayMode: .dormDailyUsage,
            speed: .zero,
            unitMode: .auto,
            dormTraffic: nil,
            dormTrafficUnavailable: false
        )

        #expect(content == StatusTitleContent(
            text: "--",
            isMultiline: false,
            lines: [StatusTitleLine(text: "--", symbolName: nil)]
        ))
    }

    @Test func formatsDormDailyUsageUnavailableWhenNoCacheExists() {
        let content = formatter.content(
            displayMode: .dormDailyUsage,
            speed: .zero,
            unitMode: .auto,
            dormTraffic: nil,
            dormTrafficUnavailable: true
        )

        #expect(content == StatusTitleContent(
            text: "N/A",
            isMultiline: false,
            lines: [StatusTitleLine(text: "N/A", symbolName: nil)]
        ))
    }
}

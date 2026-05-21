import Testing
@testable import IShowSpeed

@Suite("SpeedFormatter")
struct SpeedFormatterTests {
    private let formatter = SpeedFormatter()

    @Test func formatsBytesInAutoMode() {
        #expect(formatter.string(from: 512, unitMode: .auto) == "512 B/s")
    }

    @Test func formatsKilobytesInAutoMode() {
        #expect(formatter.string(from: 1_536, unitMode: .auto) == "1.5 KB/s")
    }

    @Test func formatsMegabytesInAutoMode() {
        #expect(formatter.string(from: 1_572_864, unitMode: .auto) == "1.5 MB/s")
    }

    @Test func formatsGigabytesInAutoMode() {
        #expect(formatter.string(from: 1_610_612_736, unitMode: .auto) == "1.5 GB/s")
    }

    @Test func formatsFixedUnits() {
        #expect(formatter.string(from: 1_536, unitMode: .kilobytes) == "1.5 KB/s")
        #expect(formatter.string(from: 1_572_864, unitMode: .megabytes) == "1.5 MB/s")
    }

    @Test func clampsNegativeValuesToZero() {
        #expect(formatter.string(from: -10, unitMode: .auto) == "0.0 B/s")
    }
}

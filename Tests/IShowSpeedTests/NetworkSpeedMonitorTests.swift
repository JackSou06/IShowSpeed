import Foundation
import Testing
@testable import IShowSpeed

private final class StubNetworkStatsProvider: NetworkStatsProviding, @unchecked Sendable {
    var samples: [NetworkStats]

    init(samples: [NetworkStats]) {
        self.samples = samples
    }

    func currentStats() throws -> NetworkStats {
        guard !samples.isEmpty else {
            throw NetworkStatsError.unavailable
        }
        return samples.removeFirst()
    }
}

@MainActor
@Suite("NetworkSpeedMonitor")
struct NetworkSpeedMonitorTests {
    @Test func firstSampleReportsZero() {
        let provider = StubNetworkStatsProvider(samples: [
            NetworkStats(downloadBytes: 1_000, uploadBytes: 500)
        ])
        let monitor = NetworkSpeedMonitor(provider: provider)
        var updates: [NetworkSpeed] = []
        monitor.onSpeedUpdate = { updates.append($0) }

        monitor.sample(now: Date(timeIntervalSince1970: 0))

        #expect(updates == [.zero])
    }

    @Test func computesSpeedFromDeltas() {
        let provider = StubNetworkStatsProvider(samples: [
            NetworkStats(downloadBytes: 1_000, uploadBytes: 500),
            NetworkStats(downloadBytes: 3_000, uploadBytes: 1_500)
        ])
        let monitor = NetworkSpeedMonitor(provider: provider)
        var updates: [NetworkSpeed] = []
        monitor.onSpeedUpdate = { updates.append($0) }

        monitor.sample(now: Date(timeIntervalSince1970: 0))
        monitor.sample(now: Date(timeIntervalSince1970: 2))

        #expect(updates.last == NetworkSpeed(downloadBytesPerSecond: 1_000, uploadBytesPerSecond: 500))
    }

    @Test func counterResetReportsZeroAndRecalibrates() {
        let provider = StubNetworkStatsProvider(samples: [
            NetworkStats(downloadBytes: 5_000, uploadBytes: 5_000),
            NetworkStats(downloadBytes: 100, uploadBytes: 100),
            NetworkStats(downloadBytes: 1_100, uploadBytes: 600)
        ])
        let monitor = NetworkSpeedMonitor(provider: provider)
        var updates: [NetworkSpeed] = []
        monitor.onSpeedUpdate = { updates.append($0) }

        monitor.sample(now: Date(timeIntervalSince1970: 0))
        monitor.sample(now: Date(timeIntervalSince1970: 1))
        monitor.sample(now: Date(timeIntervalSince1970: 2))

        #expect(updates[1] == .zero)
        #expect(updates[2] == NetworkSpeed(downloadBytesPerSecond: 1_000, uploadBytesPerSecond: 500))
    }

    @Test func providerFailureReportsZero() {
        let provider = StubNetworkStatsProvider(samples: [])
        let monitor = NetworkSpeedMonitor(provider: provider)
        var updates: [NetworkSpeed] = []
        monitor.onSpeedUpdate = { updates.append($0) }

        monitor.sample()

        #expect(updates == [.zero])
    }
}

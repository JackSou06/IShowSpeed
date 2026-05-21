import Foundation

struct NetworkSpeed: Equatable, Sendable {
    let downloadBytesPerSecond: Double
    let uploadBytesPerSecond: Double

    static let zero = NetworkSpeed(downloadBytesPerSecond: 0, uploadBytesPerSecond: 0)
}

@MainActor
final class NetworkSpeedMonitor {
    var onSpeedUpdate: ((NetworkSpeed) -> Void)?

    private let provider: NetworkStatsProviding
    private var timer: Timer?
    private var previousSample: (stats: NetworkStats, date: Date)?

    init(provider: NetworkStatsProviding) {
        self.provider = provider
    }

    func start(interval: TimeInterval) {
        stop()
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sample()
            }
        }
    }

    func updateInterval(_ interval: TimeInterval) {
        start(interval: interval)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        previousSample = nil
    }

    func sample(now: Date = Date()) {
        guard let stats = try? provider.currentStats() else {
            previousSample = nil
            onSpeedUpdate?(.zero)
            return
        }

        guard let previousSample else {
            self.previousSample = (stats, now)
            onSpeedUpdate?(.zero)
            return
        }

        let elapsed = now.timeIntervalSince(previousSample.date)
        guard elapsed > 0,
              stats.downloadBytes >= previousSample.stats.downloadBytes,
              stats.uploadBytes >= previousSample.stats.uploadBytes else {
            self.previousSample = (stats, now)
            onSpeedUpdate?(.zero)
            return
        }

        let downloadDelta = stats.downloadBytes - previousSample.stats.downloadBytes
        let uploadDelta = stats.uploadBytes - previousSample.stats.uploadBytes
        let speed = NetworkSpeed(
            downloadBytesPerSecond: Double(downloadDelta) / elapsed,
            uploadBytesPerSecond: Double(uploadDelta) / elapsed
        )

        self.previousSample = (stats, now)
        onSpeedUpdate?(speed)
    }
}

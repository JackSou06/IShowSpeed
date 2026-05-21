import Foundation

struct SpeedFormatter: Sendable {
    func string(from bytesPerSecond: Double, unitMode: SpeedUnitMode) -> String {
        let speed = max(0, bytesPerSecond)

        switch unitMode {
        case .auto:
            return autoString(from: speed)
        case .kilobytes:
            return formatted(speed / 1_024, unit: "KB/s")
        case .megabytes:
            return formatted(speed / 1_048_576, unit: "MB/s")
        }
    }

    private func autoString(from bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1_024 {
            return formatted(bytesPerSecond, unit: "B/s")
        }

        if bytesPerSecond < 1_048_576 {
            return formatted(bytesPerSecond / 1_024, unit: "KB/s")
        }

        if bytesPerSecond < 1_073_741_824 {
            return formatted(bytesPerSecond / 1_048_576, unit: "MB/s")
        }

        return formatted(bytesPerSecond / 1_073_741_824, unit: "GB/s")
    }

    private func formatted(_ value: Double, unit: String) -> String {
        let roundedValue = value >= 100 ? String(format: "%.0f", value) : String(format: "%.1f", value)
        return "\(roundedValue) \(unit)"
    }
}

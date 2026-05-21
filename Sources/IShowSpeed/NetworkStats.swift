import Foundation

struct NetworkStats: Equatable, Sendable {
    let downloadBytes: UInt64
    let uploadBytes: UInt64
}

protocol NetworkStatsProviding: Sendable {
    func currentStats() throws -> NetworkStats
}

enum NetworkStatsError: Error {
    case unavailable
}

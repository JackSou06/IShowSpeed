import Foundation

struct DailyTrafficUsage: Equatable, Sendable {
    let total: String
    let download: String
    let upload: String
    let fetchedAt: Date
}

enum DormTrafficError: Error, Equatable {
    case invalidResponse
    case parseFailed
}

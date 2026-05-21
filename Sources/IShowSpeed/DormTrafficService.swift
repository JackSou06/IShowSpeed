import Foundation

actor DormTrafficService {
    private let fetcher: DormTrafficFetching
    private let cacheDuration: TimeInterval
    private var cachedUsage: DailyTrafficUsage?

    init(fetcher: DormTrafficFetching, cacheDuration: TimeInterval = 300) {
        self.fetcher = fetcher
        self.cacheDuration = cacheDuration
    }

    func usage(forceRefresh: Bool = false, now: Date = Date()) async throws -> DailyTrafficUsage {
        if !forceRefresh,
           let cachedUsage,
           now.timeIntervalSince(cachedUsage.fetchedAt) < cacheDuration {
            return cachedUsage
        }

        let usage = try await fetcher.fetchDailyUsage()
        cachedUsage = usage
        return usage
    }
}

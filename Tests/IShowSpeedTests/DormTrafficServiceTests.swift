import Foundation
import Testing
@testable import IShowSpeed

private final class MockDormTrafficFetcher: DormTrafficFetching, @unchecked Sendable {
    private(set) var requestCount = 0
    var usages: [DailyTrafficUsage]

    init(usages: [DailyTrafficUsage]) {
        self.usages = usages
    }

    func fetchDailyUsage() async throws -> DailyTrafficUsage {
        requestCount += 1
        return usages.removeFirst()
    }
}

@Suite("DormTrafficService")
struct DormTrafficServiceTests {
    @Test func returnsCachedUsageWithinCacheDuration() async throws {
        let first = DailyTrafficUsage(total: "1GB", download: "800MB", upload: "200MB", fetchedAt: Date(timeIntervalSince1970: 0))
        let second = DailyTrafficUsage(total: "2GB", download: "1GB", upload: "1GB", fetchedAt: Date(timeIntervalSince1970: 10))
        let fetcher = MockDormTrafficFetcher(usages: [first, second])
        let service = DormTrafficService(fetcher: fetcher, cacheDuration: 300)

        let firstResult = try await service.usage(now: Date(timeIntervalSince1970: 0))
        let secondResult = try await service.usage(now: Date(timeIntervalSince1970: 100))

        #expect(firstResult == first)
        #expect(secondResult == first)
        #expect(fetcher.requestCount == 1)
    }

    @Test func refreshesAfterCacheExpires() async throws {
        let first = DailyTrafficUsage(total: "1GB", download: "800MB", upload: "200MB", fetchedAt: Date(timeIntervalSince1970: 0))
        let second = DailyTrafficUsage(total: "2GB", download: "1GB", upload: "1GB", fetchedAt: Date(timeIntervalSince1970: 301))
        let fetcher = MockDormTrafficFetcher(usages: [first, second])
        let service = DormTrafficService(fetcher: fetcher, cacheDuration: 300)

        _ = try await service.usage(now: Date(timeIntervalSince1970: 0))
        let refreshed = try await service.usage(now: Date(timeIntervalSince1970: 301))

        #expect(refreshed == second)
        #expect(fetcher.requestCount == 2)
    }

    @Test func forceRefreshBypassesCache() async throws {
        let first = DailyTrafficUsage(total: "1GB", download: "800MB", upload: "200MB", fetchedAt: Date(timeIntervalSince1970: 0))
        let second = DailyTrafficUsage(total: "2GB", download: "1GB", upload: "1GB", fetchedAt: Date(timeIntervalSince1970: 1))
        let fetcher = MockDormTrafficFetcher(usages: [first, second])
        let service = DormTrafficService(fetcher: fetcher, cacheDuration: 300)

        _ = try await service.usage(now: Date(timeIntervalSince1970: 0))
        let refreshed = try await service.usage(forceRefresh: true, now: Date(timeIntervalSince1970: 1))

        #expect(refreshed == second)
        #expect(fetcher.requestCount == 2)
    }
}

import Foundation

protocol DormTrafficFetching: Sendable {
    func fetchDailyUsage() async throws -> DailyTrafficUsage
}

final class DormTrafficClient: DormTrafficFetching, @unchecked Sendable {
    private let url: URL
    private let session: URLSession
    private let parser: DormTrafficParser

    init(
        url: URL = URL(string: "https://dorm-long-1.cc.ntu.edu.tw/login_online_detail.php")!,
        timeout: TimeInterval = 5,
        parser: DormTrafficParser = DormTrafficParser(),
        session: URLSession? = nil
    ) {
        self.url = url
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = timeout
            configuration.timeoutIntervalForResource = timeout
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
        self.parser = parser
    }

    func fetchDailyUsage() async throws -> DailyTrafficUsage {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              let html = String(data: data, encoding: .utf8) else {
            throw DormTrafficError.invalidResponse
        }

        return try parser.parse(html)
    }
}

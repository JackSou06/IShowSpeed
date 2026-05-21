import Foundation
import Testing
@testable import IShowSpeed

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseStatusCode = 200
    nonisolated(unsafe) static var responseBody = Data()
    nonisolated(unsafe) static var requestCount = 0

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requestCount += 1
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.responseStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("DormTrafficClient", .serialized)
struct DormTrafficClientTests {
    @Test func fetchesAndParsesDailyUsage() async throws {
        MockURLProtocol.responseStatusCode = 200
        MockURLProtocol.responseBody = """
        今天流量使用情況: 總流量 <label>6.66GB</label>
        接收流量 <label>5.80GB</label>
        傳送流量 <label>879.84MB</label>
        """.data(using: .utf8)!
        MockURLProtocol.requestCount = 0

        let client = DormTrafficClient(session: makeSession())
        let usage = try await client.fetchDailyUsage()

        #expect(usage.total == "6.66GB")
        #expect(usage.download == "5.80GB")
        #expect(usage.upload == "879.84MB")
        #expect(MockURLProtocol.requestCount == 1)
    }

    @Test func throwsOnHTTPFailure() async {
        MockURLProtocol.responseStatusCode = 500
        MockURLProtocol.responseBody = Data()

        let client = DormTrafficClient(session: makeSession())

        await #expect(throws: DormTrafficError.invalidResponse) {
            _ = try await client.fetchDailyUsage()
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

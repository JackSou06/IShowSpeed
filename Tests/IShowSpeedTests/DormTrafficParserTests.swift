import Foundation
import Testing
@testable import IShowSpeed

@Suite("DormTrafficParser")
struct DormTrafficParserTests {
    private let parser = DormTrafficParser()

    @Test func parsesDailyTrafficBlock() throws {
        let html = """
        <p>
        今天流量使用情況: 總流量 <label>6.66GB</label>
        接收流量 <label>5.80GB</label>
        傳送流量 <label>879.84MB</label>
        </p>
        """
        let fetchedAt = Date(timeIntervalSince1970: 10)

        let usage = try parser.parse(html, fetchedAt: fetchedAt)

        #expect(usage == DailyTrafficUsage(
            total: "6.66GB",
            download: "5.80GB",
            upload: "879.84MB",
            fetchedAt: fetchedAt
        ))
    }

    @Test func parsesTrafficBlockWithExtraWhitespace() throws {
        let html = """
        今天流量使用情況:
            總流量
            <label class="color-blue1 bold midDis"> 12.3 GB </label>
            接收流量 <label> 900.0 MB </label>
            傳送流量 <label> 1.2 GB </label>
        """

        let usage = try parser.parse(html)

        #expect(usage.total == "12.3GB")
        #expect(usage.download == "900.0MB")
        #expect(usage.upload == "1.2GB")
    }

    @Test func throwsWhenDailyTrafficBlockIsMissing() {
        #expect(throws: DormTrafficError.parseFailed) {
            _ = try parser.parse("<html>No traffic here</html>")
        }
    }
}

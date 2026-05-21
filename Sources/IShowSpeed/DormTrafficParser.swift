import Foundation

struct DormTrafficParser: Sendable {
    func parse(_ html: String, fetchedAt: Date = Date()) throws -> DailyTrafficUsage {
        let plainText = html
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        let pattern = #"今天流量使用情況:\s*總流量\s*([0-9.]+\s*[KMGT]?B)\s*接收流量\s*([0-9.]+\s*[KMGT]?B)\s*傳送流量\s*([0-9.]+\s*[KMGT]?B)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(plainText.startIndex..<plainText.endIndex, in: plainText)

        guard let match = regex.firstMatch(in: plainText, range: range), match.numberOfRanges == 4 else {
            throw DormTrafficError.parseFailed
        }

        return DailyTrafficUsage(
            total: normalizedValue(from: plainText, matchRange: match.range(at: 1)),
            download: normalizedValue(from: plainText, matchRange: match.range(at: 2)),
            upload: normalizedValue(from: plainText, matchRange: match.range(at: 3)),
            fetchedAt: fetchedAt
        )
    }

    private func normalizedValue(from text: String, matchRange: NSRange) -> String {
        guard let range = Range(matchRange, in: text) else {
            return ""
        }

        return text[range]
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

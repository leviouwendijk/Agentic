public struct SkillDocument: Sendable, Codable, Hashable {
    public let metadata: [String: String]
    public let body: String

    public init(
        metadata: [String: String],
        body: String
    ) {
        self.metadata = metadata
        self.body = body
    }
}

public enum SkillFrontmatter {
    public static func parse(
        _ text: String
    ) -> SkillDocument {
        let normalized = text.replacingOccurrences(
            of: "\r\n",
            with: "\n"
        )

        let lines = normalized.components(
            separatedBy: "\n"
        )

        guard lines.first?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) == "---" else {
            return .init(
                metadata: [:],
                body: text
            )
        }

        var metadata: [String: String] = [:]
        var closingDelimiterIndex: Int?

        for index in lines.indices.dropFirst() {
            let line = lines[index].trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if line == "---" {
                closingDelimiterIndex = index
                break
            }

            guard !line.isEmpty,
                  !line.hasPrefix("#"),
                  let separatorIndex = line.firstIndex(of: ":")
            else {
                continue
            }

            let key = line[..<separatorIndex].trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let rawValue = line[line.index(after: separatorIndex)...]
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard !key.isEmpty else {
                continue
            }

            metadata[String(key)] = unquoted(
                String(rawValue)
            )
        }

        guard let closingDelimiterIndex else {
            return .init(
                metadata: [:],
                body: text
            )
        }

        let bodyStartIndex = closingDelimiterIndex + 1
        let body = bodyStartIndex < lines.count
            ? lines[bodyStartIndex...].joined(separator: "\n")
            : ""

        return .init(
            metadata: metadata,
            body: body
        )
    }
}

private extension SkillFrontmatter {
    static func unquoted(
        _ value: String
    ) -> String {
        guard value.count >= 2 else {
            return value
        }

        if value.hasPrefix("\""),
           value.hasSuffix("\"") {
            return String(value.dropFirst().dropLast())
        }

        if value.hasPrefix("'"),
           value.hasSuffix("'") {
            return String(value.dropFirst().dropLast())
        }

        return value
    }
}

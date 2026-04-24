public enum AgentArtifactKind: String, Sendable, Codable, Hashable, CaseIterable {
    case text
    case markdown
    case json
    case context_pack
    case diff
    case report
    case note
}

public extension AgentArtifactKind {
    var defaultFileExtension: String {
        switch self {
        case .text:
            return "txt"

        case .markdown:
            return "md"

        case .json:
            return "json"

        case .context_pack:
            return "txt"

        case .diff:
            return "diff"

        case .report:
            return "md"

        case .note:
            return "txt"
        }
    }

    var defaultContentType: String {
        switch self {
        case .text, .context_pack, .note:
            return "text/plain"

        case .markdown, .report:
            return "text/markdown"

        case .json:
            return "application/json"

        case .diff:
            return "text/x-diff"
        }
    }
}

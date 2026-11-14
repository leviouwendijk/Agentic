/// Owner-granted: reads a function call's full response from the session's
/// record, for results the model was shown only in part. The runtime
/// installs it when the session is logged.
public struct ResultArchive: Sendable {
    private let lookup: @Sendable (String) async throws -> FunctionCall.Response?

    public init(
        _ lookup: @escaping @Sendable (String) async throws -> FunctionCall.Response?
    ) {
        self.lookup = lookup
    }

    /// The full response recorded for `call`, if any.
    public func response(
        call: String
    ) async throws -> FunctionCall.Response? {
        try await lookup(call)
    }
}

/// A result's model text as numbered lines for reading in parts. A line
/// longer than `width` characters (compact JSON is one line) is split, so
/// every part stays small. The budget that shortens a result and the tool
/// that reads the rest count lines the same way.
public enum ResultLines {
    public static let width = 1_000

    public static func lines(
        of text: String,
        width: Int = width
    ) -> [Substring] {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .flatMap { line -> [Substring] in
                guard line.count > width else {
                    return [line]
                }
                var parts: [Substring] = []
                var start = line.startIndex
                while start < line.endIndex {
                    let end = line.index(start, offsetBy: width, limitedBy: line.endIndex) ?? line.endIndex
                    parts.append(line[start..<end])
                    start = end
                }
                return parts
            }
    }
}

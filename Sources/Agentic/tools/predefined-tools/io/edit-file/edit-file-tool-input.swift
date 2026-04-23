import Position
import Writers

public struct EditFileLineRange: Sendable, Codable, Hashable {
    public let start: Int
    public let end: Int

    public init(
        start: Int,
        end: Int
    ) {
        self.start = start
        self.end = end
    }

    public func lineRange() throws -> LineRange {
        try LineRange(
            start: start,
            end: end
        )
    }
}

public enum EditFileToolOperationKind: String, Sendable, Codable, Hashable, CaseIterable {
    case replaceEntireFile = "replace_entire_file"
    case append
    case prepend
    case replaceFirst = "replace_first"
    case replaceAll = "replace_all"
    case replaceUnique = "replace_unique"
    case replaceLine = "replace_line"
    case insertLines = "insert_lines"
    case replaceLines = "replace_lines"
    case deleteLines = "delete_lines"
}

public struct EditFileToolOperation: Sendable, Codable, Hashable {
    public let kind: EditFileToolOperationKind
    public let content: String?
    public let target: String?
    public let replacement: String?
    public let line: Int?
    public let lines: [String]?
    public let atLine: Int?
    public let range: EditFileLineRange?
    public let separator: String?

    public init(
        kind: EditFileToolOperationKind,
        content: String? = nil,
        target: String? = nil,
        replacement: String? = nil,
        line: Int? = nil,
        lines: [String]? = nil,
        atLine: Int? = nil,
        range: EditFileLineRange? = nil,
        separator: String? = nil
    ) {
        self.kind = kind
        self.content = content
        self.target = target
        self.replacement = replacement
        self.line = line
        self.lines = lines
        self.atLine = atLine
        self.range = range
        self.separator = separator
    }

    public func standardOperation() throws -> StandardEditOperation {
        switch kind {
        case .replaceEntireFile:
            guard let content else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "content"
                )
            }

            return .replaceEntireFile(
                with: content
            )

        case .append:
            guard let content else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "content"
                )
            }

            return .append(
                content,
                separator: separator
            )

        case .prepend:
            guard let content else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "content"
                )
            }

            return .prepend(
                content,
                separator: separator
            )

        case .replaceFirst:
            guard let target else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "target"
                )
            }

            guard let replacement else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "replacement"
                )
            }

            return .replaceFirst(
                of: target,
                with: replacement
            )

        case .replaceAll:
            guard let target else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "target"
                )
            }

            guard let replacement else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "replacement"
                )
            }

            return .replaceAll(
                of: target,
                with: replacement
            )

        case .replaceUnique:
            guard let target else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "target"
                )
            }

            guard let replacement else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "replacement"
                )
            }

            return .replaceUnique(
                of: target,
                with: replacement
            )

        case .replaceLine:
            guard let line else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "line"
                )
            }

            guard let content else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "content"
                )
            }

            return .replaceLine(
                line,
                with: content
            )

        case .insertLines:
            guard let lines else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "lines"
                )
            }

            guard let atLine else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "atLine"
                )
            }

            return .insertLines(
                lines,
                atLine: atLine
            )

        case .replaceLines:
            guard let lines else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "lines"
                )
            }

            guard let range else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "range"
                )
            }

            return .replaceLines(
                try range.lineRange(),
                with: lines
            )

        case .deleteLines:
            guard let range else {
                throw PredefinedFileToolError.missingField(
                    tool: "edit_file",
                    field: "range"
                )
            }

            return .deleteLines(
                try range.lineRange()
            )
        }
    }
}

public struct EditFileToolInput: Sendable, Codable, Hashable {
    public let path: String
    public let operations: [EditFileToolOperation]

    public init(
        path: String,
        operations: [EditFileToolOperation]
    ) {
        self.path = path
        self.operations = operations
    }
}

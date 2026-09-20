import Agentic
import Workspace
import Foundation
import GuidelinesSearch
import Schema
import Macros

@JSONSchema
public struct FindGuidelinesInput:
    Sendable,
    Codable,
    Hashable
{
    /// Natural-language intent, guideline title, summary text, or exact guideline reference.
    public let query: String

    /// Optional result limit. Defaults to 5 and is clamped to 1...8.
    public let maximumResults: Int?

    public init(
        query: String,
        maximumResults: Int? = nil
    ) {
        self.query = query
        self.maximumResults = maximumResults
    }

    public var resultLimit: Int {
        max(
            1,
            min(
                maximumResults ?? 5,
                8
            )
        )
    }
}

@JSONSchema
public struct FindGuidelinesOutput:
    Sendable,
    Codable,
    Hashable
{
    public let query: String
    public let count: Int
    public let matches: [GuidelineSummary]
}

public struct FindGuidelines: Tool {
    public typealias Input = FindGuidelinesInput
    public typealias Output = FindGuidelinesOutput

    public static let identifier: ToolIdentifier =
        "find_guidelines"

    public static let description =
        "Search guidelines by natural-language intent and return a bounded set of references, titles, chapters, and summaries without full explanations."

    public static let risk: ActionRisk =
        .observe

    public static let definition = ToolDefinition(
        identifier: identifier,
        purpose: description,
        risk: risk
    )

    public init() {}

    public var identifier: ToolIdentifier {
        Self.identifier
    }

    public var description: String {
        Self.description
    }

    public var risk: ActionRisk {
        Self.risk
    }

    public func preflight(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> ToolPreflight {
        let query = try normalizedQuery(
            input.query
        )

        return .init(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary:
                "Search guideline summaries for '\(query)' with at most \(input.resultLimit) result(s).",
            sideEffects:
                Self.definition.risk.defaultSideEffects
        )
    }

    public func call(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> Output {
        let query = try normalizedQuery(
            input.query
        )

        let matches: [GuidelineSummary] =
            GuidelineSearchIndex()
                .searchGuidelines(
                    query,
                    limit: input.resultLimit
                )
                .compactMap { entry -> GuidelineSummary? in
                    guard let guideline = entry.guideline else {
                        return nil
                    }

                    return GuidelineSummary(
                        guideline: guideline,
                        chapter: entry.chapter
                    )
                }

                return .init(
                    query: query,
                    count: matches.count,
                    matches: matches
                )
            }

    private func normalizedQuery(
        _ value: String
    ) throws -> String {
        let query =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !query.isEmpty else {
            throw GuidelineError
                .emptyQuery
        }

        return query
    }
}

import Agentic
import Workspace
import Foundation
import Guidelines
import Schema
import Macros

@JSONSchema
public struct GuidelineIndexInput:
    Sendable,
    Codable,
    Hashable
{
    /// Optional exact guideline area such as design, web_design, ergonomics, structure, or ai.
    public let area: String?

    public init(
        area: String? = nil
    ) {
        self.area = area
    }
}

@JSONSchema
public struct GuidelineIndexEntry:
    Sendable,
    Codable,
    Hashable
{
    public let reference: String
    public let title: String
}

@JSONSchema
public struct GuidelineIndexChapter:
    Sendable,
    Codable,
    Hashable
{
    public let reference: String
    public let area: String
    public let title: String
    public let guidelineCount: Int
    public let guidelines: [GuidelineIndexEntry]
}

@JSONSchema
public struct GuidelineIndexOutput:
    Sendable,
    Codable,
    Hashable
{
    public let area: String?
    public let chapterCount: Int
    public let guidelineCount: Int
    public let chapters: [GuidelineIndexChapter]
}

public extension Standard.Tools {
    struct GuidelineIndex: Tool {
    public typealias Input = GuidelineIndexInput
    public typealias Output = GuidelineIndexOutput

    public static let identifier: ToolIdentifier =
        "guideline_index"

    public static let description =
        "Inspect a cheap body-free index of guideline areas, chapters, references, and titles. Use this for structural orientation before loading summaries or full explanations."

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
        _ = try resolvedArea(
            input.area
        )

        return .init(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary:
                "Inspect the body-free guideline index.",
            sideEffects:
                Self.definition.risk.defaultSideEffects
        )
    }

    public func call(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> Output {
        let area = try resolvedArea(
            input.area
        )

        let chapters = GuidelineManual.chapters
            .filter {
                area == nil
                || $0.area == area
            }
            .map { chapter in
                GuidelineIndexChapter(
                    reference:
                        chapter.reference,
                    area:
                        chapter.area.rawValue,
                    title:
                        chapter.title,
                    guidelineCount:
                        chapter.guidelines.count,
                    guidelines:
                        chapter.guidelines.map {
                            GuidelineIndexEntry(
                                reference:
                                    $0.reference,
                                title:
                                    $0.title
                            )
                        }
                )
            }

        return .init(
            area:
                area?.rawValue,
            chapterCount:
                chapters.count,
            guidelineCount:
                chapters.reduce(0) {
                    $0 + $1.guidelineCount
                },
            chapters:
                chapters
        )
    }

    private func resolvedArea(
        _ rawValue: String?
    ) throws -> GuidelineArea? {
        guard let rawValue else {
            return nil
        }

        let normalized =
            rawValue.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !normalized.isEmpty else {
            return nil
        }

        guard let area =
            GuidelineArea(
                rawValue: normalized
            )
        else {
            throw GuidelineError
                .invalidArea(
                    normalized
                )
        }

        return area
    }
    }
}

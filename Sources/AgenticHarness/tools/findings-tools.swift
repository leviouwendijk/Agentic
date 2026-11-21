import Agentic
import Foundation
import Macros
import Primitives
import Schema

public enum HarnessFindingError: Error, LocalizedError, Sendable {
    case noEvidence
    case unknownFinding(String)

    public var errorDescription: String? {
        switch self {
        case .noEvidence:
            "A finding needs at least one evidence reference: `<session> step <seq>` or a payload digest."
        case .unknownFinding(let file):
            "No finding '\(file)'; harness_tool_list_findings names them."
        }
    }
}

public extension Harness.Tools {
    @Tool("list_findings")
    struct ListFindings: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Only this category.
            public let category: Harness.Finding.Category?

            public init(category: Harness.Finding.Category? = nil) {
                self.category = category
            }
        }

        @JSONSchema
        public struct Entry: HashableProduct {
            public let file: String
            public let category: Harness.Finding.Category
            public let title: String
            public let status: Harness.Finding.Status
            public let evidence: Int

            public init(
                file: String,
                category: Harness.Finding.Category,
                title: String,
                status: Harness.Finding.Status,
                evidence: Int
            ) {
                self.file = file
                self.category = category
                self.title = title
                self.status = status
                self.evidence = evidence
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let entries: [Entry]
            public let problems: [String]

            public init(entries: [Entry], problems: [String]) {
                self.entries = entries
                self.problems = problems
            }
        }

        public static let purpose =
            "List the recorded harness findings, so a new observation extends an existing finding instead of repeating it."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let (findings, problems) = Harness.Improvements.store(in: context).findings()
            return .init(
                entries: findings
                    .filter { input.category == nil || $0.finding.category == input.category }
                    .map {
                        .init(
                            file: $0.file,
                            category: $0.finding.category,
                            title: $0.finding.title,
                            status: $0.finding.status,
                            evidence: $0.finding.evidence.count
                        )
                    },
                problems: problems
            )
        }

        public func render(_ output: Output, input: Input) -> String? {
            guard !output.entries.isEmpty else {
                return "No findings recorded yet." + Self.problems(output.problems)
            }
            return output.entries.map {
                "\($0.file)  [\($0.category.rawValue), \($0.status.rawValue), \($0.evidence) evidence] \($0.title)"
            }.joined(separator: "\n") + Self.problems(output.problems)
        }

        static func problems(_ problems: [String]) -> String {
            problems.isEmpty ? "" : "\nUnreadable: " + problems.joined(separator: "; ")
        }
    }

    /// Records a verified finding, or adds evidence to an existing one.
    @Tool("record_finding")
    struct RecordFinding: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let category: Harness.Finding.Category
            /// The claim, in one line.
            public let title: String
            /// What was observed, with numbers where there are any.
            public let detail: String
            /// `<session> step <seq>` or payload digests; at least one.
            public let evidence: [String]
            /// The estimated effect, recomputed from the record.
            public let effect: String?
            /// The change it suggests.
            public let proposal: String
            /// An existing finding's file: add this evidence to it instead
            /// of recording a new one.
            public let extends: String?

            public init(
                category: Harness.Finding.Category,
                title: String,
                detail: String,
                evidence: [String],
                effect: String? = nil,
                proposal: String,
                extends: String? = nil
            ) {
                self.category = category
                self.title = title
                self.detail = detail
                self.evidence = evidence
                self.effect = effect
                self.proposal = proposal
                self.extends = extends
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let file: String
            public let extended: Bool
            public let evidence: Int

            public init(file: String, extended: Bool, evidence: Int) {
                self.file = file
                self.extended = extended
                self.evidence = evidence
            }
        }

        public static let purpose =
            "Record a verified harness finding with its evidence and proposed change, or add evidence to an existing one with `extends`."
        public static let risk: ActionRisk = .boundedmutate

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let evidence = input.evidence
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !evidence.isEmpty else { throw HarnessFindingError.noEvidence }
            let store = Harness.Improvements.store(in: context)
            let today = Self.day(Date())
            if let file = input.extends {
                guard let existing = try? store.finding(file) else {
                    throw HarnessFindingError.unknownFinding(file)
                }
                let extended = existing.adding(evidence: evidence, on: today)
                try store.replace(file, with: extended)
                return .init(file: file, extended: true, evidence: extended.evidence.count)
            }
            let finding = Harness.Finding(
                category: input.category,
                title: input.title,
                detail: input.detail,
                evidence: evidence,
                effect: input.effect,
                proposal: input.proposal,
                recorded: today
            )
            return .init(file: try store.record(finding), extended: false, evidence: evidence.count)
        }

        static func day(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
    }
}

extension Harness.Finding.Category: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .string(cases: allCases.map(\.rawValue))
    }
}

extension Harness.Finding.Status: JSONSchemaProviding {
    public static var jsonschema: JSONSchema {
        .string(cases: allCases.map(\.rawValue))
    }
}

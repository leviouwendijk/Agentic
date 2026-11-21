import Agentic
import Foundation
import Macros
import Milieu
import Schema

/// Owner-granted: the .env files whose declared names
/// `standard_tool_check_environment_symbol` may report. Hosts choose them; the model never
/// supplies paths.
public struct EnvironmentSymbolSources: Sendable {
    public let declarations: [EnvironmentDeclarationSource]

    public init(_ declarations: [EnvironmentDeclarationSource]) {
        self.declarations = declarations
    }
}

public enum EnvironmentSymbolFailure: Error, Sendable, LocalizedError {
    case noNames
    case tooManyNames

    public var errorDescription: String? {
        switch self {
        case .noNames: return "Pass at least one environment variable name."
        case .tooManyNames: return "Check at most 16 names per call."
        }
    }
}

public extension Standard.Tools {
    /// Checks environment names. Never returns, measures or echoes a value.
    @Tool("check_environment_symbol")
    struct CheckEnvironmentSymbol: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Exact environment variable names, such as `OPENAI_API_KEY`.
            public let names: [String]

            public init(names: [String]) {
                self.names = names
            }
        }

        @JSONSchema
        public enum Status: String, Sendable, Codable, Hashable, CaseIterable {
            case set
            case empty
            case missing
        }

        @JSONSchema
        public struct Declaration: HashableResult {
            /// The source's label, such as `$DEV_ENV`.
            public let source: String
            public let line: Int
            public let is_empty: Bool
            /// Whether the declared value equals this process's value. Nil
            /// when this process lacks the name.
            public let matches_process: Bool?
        }

        @JSONSchema
        public struct Entry: HashableResult {
            public let name: String
            /// In this agent's own process, not in shells it starts.
            public let status: Status
            /// Near names from this process and the declaration sources.
            public let suggestions: [String]
            public let declarations: [Declaration]
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let entries: [Entry]
            /// Labels of the declaration files that were read.
            public let scanned_sources: [String]
            /// Labels of configured declaration files that could not be read
            /// or parsed.
            public let unreadable_sources: [String]
        }

        public static let purpose =
            "Check whether environment variables exist without revealing their values: set, empty or missing in this agent's process, near names when one is misspelled, and which configured .env files declare it, at which line, and whether that declaration matches the process value. Status describes this process only; a variable a shell loads from an .env file shows up under declarations."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            guard !input.names.isEmpty else { throw EnvironmentSymbolFailure.noNames }
            guard input.names.count <= 16 else { throw EnvironmentSymbolFailure.tooManyNames }

            let sources = (try? context.require(EnvironmentSymbolSources.self))?.declarations ?? []
            var files: [EnvironmentDeclarationFile] = []
            var unreadable: [String] = []
            for source in sources {
                do {
                    files.append(try EnvironmentDeclarationFile(source))
                } catch {
                    unreadable.append(source.label)
                }
            }

            let inspector = EnvironmentInspector()
            let declared = files.flatMap(\.names)
            let entries = input.names.map { name -> Entry in
                let status = Status(rawValue: inspector.presence(name).rawValue) ?? .missing
                return .init(
                    name: name,
                    status: status,
                    suggestions: status == .set ? [] : inspector.suggestions(for: name, among: declared),
                    declarations: files.compactMap { file in
                        inspector.declaration(of: name, in: file).map {
                            .init(
                                source: $0.source.label,
                                line: $0.line,
                                is_empty: $0.isEmpty,
                                matches_process: $0.matchesProcess
                            )
                        }
                    }
                )
            }

            return .init(
                entries: entries,
                scanned_sources: files.map(\.source.label),
                unreadable_sources: unreadable
            )
        }
    }
}

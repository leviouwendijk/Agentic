import Agentic
import Macros
import Primitives
import Schema

public extension Harness.Tools {
    /// A one-line note on what got in the way, for the run's later review.
    /// It changes nothing now: the session log keeps the call, and the
    /// retrospective reads it there.
    @Tool("note_friction")
    struct NoteFriction: Tool {
        public enum Kind: String, Sendable, Codable, Hashable, CaseIterable, JSONSchemaProviding {
            case missing_capability
            case unclear_instruction
            case conflicting_instructions
            case context
            case workflow
            case other

            public static var jsonschema: JSONSchema {
                .string(cases: allCases.map(\.rawValue))
            }
        }

        @JSONSchema
        public struct Input: HashableSource {
            public let kind: Kind
            /// One line: what was needed, unclear or in the way.
            public let note: String

            public init(kind: Kind, note: String) {
                self.kind = kind
                self.note = note
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let noted: Bool

            public init(noted: Bool = true) {
                self.noted = noted
            }
        }

        public static let purpose =
            "Note in one line what got in your way (a capability you could not find, an instruction that was unclear or contradicted another) for later review; changes nothing now, so carry on."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in _: CapabilityContext) async throws -> Output {
            .init()
        }

        public func render(_ output: Output, input: Input) -> String? {
            "Noted."
        }
    }
}

import Agentic
import Macros
import Primitives
import Schema

public enum InspectCapabilityError: Error, Sendable {
    case notAvailable
    case invalidKind
}

public extension Standard.Tools {
    @Tool
    struct InspectCapability: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let kind: CapabilityKind
            public let identifier: String
            public init(kind: CapabilityKind, identifier: String) {
                self.kind = kind
                self.identifier = identifier
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let kind: CapabilityKind
            public let identifier: String
            public let namespace: String?
            public let purpose: String
            public let input: JSONValue
            public let output: JSONValue
            public let modelInputSchema: JSONValue?
            public let risk: String?
            /// Among the tool definitions: called by its own name.
            public let wasVisible: Bool
            /// `call_capability` when it is not among the tool definitions:
            /// it is callable all the same, through the dispatcher, and the
            /// definitions stay as the conversation opened, so the
            /// provider's cache holds.
            public let callWith: String?

            public init(
                kind: CapabilityKind,
                identifier: String,
                namespace: String?,
                purpose: String,
                input: JSONValue,
                output: JSONValue,
                modelInputSchema: JSONValue?,
                risk: String?,
                wasVisible: Bool,
                callWith: String? = nil
            ) {
                self.kind = kind
                self.identifier = identifier
                self.namespace = namespace
                self.purpose = purpose
                self.input = input
                self.output = output
                self.modelInputSchema = modelInputSchema
                self.risk = risk
                self.wasVisible = wasVisible
                self.callWith = callWith
            }
        }

        public static let purpose =
            "Return one available capability's full contract, including optional fields and guidance. Reading it changes nothing: every available capability is callable, by its own name when it is among your tools, otherwise through call_capability as `callWith` says."
        public static let risk: ActionRisk = .observe
        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            guard input.kind != .all else { throw InspectCapabilityError.invalidKind }
            let (snapshot, available) = try await CapabilityDiscovery.available(in: context)
            guard let selected = available.first(where: {
                $0.kind == input.kind.rawValue && $0.identifier == input.identifier
            }) else {
                throw InspectCapabilityError.notAvailable
            }
            let wasVisible = CapabilityDiscovery.contains(selected.reference, in: snapshot.visible)
            return Output(
                kind: input.kind,
                identifier: selected.identifier,
                namespace: selected.namespace,
                purpose: selected.purpose,
                input: selected.input,
                output: selected.output,
                modelInputSchema: selected.modelInputSchema,
                risk: selected.risk.map { String(describing: $0) },
                wasVisible: wasVisible,
                // The runtime keeps a conversation's tool definitions as
                // they opened; the rest is called through the dispatcher,
                // when there is one.
                callWith: !wasVisible && snapshot.visible.tools.contains(CallCapability.identifier)
                    ? CallCapability.identifier.rawValue
                    : nil
            )
        }
    }
}

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
            public let wasVisible: Bool
            /// Callable from now on: this is its contract.
            public let revealed: Bool
            /// `call_capability` when it is called through the dispatcher
            /// rather than by its own name: the tool definitions stay as
            /// the session opened, so the provider's cache holds.
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
                revealed: Bool = false,
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
                self.revealed = revealed
                self.callWith = callWith
            }
        }

        public static let purpose =
            "Return one available capability's full contract, including optional fields and guidance; a hidden one becomes callable, through call_capability when `callWith` says so."
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
            var revealed = false
            if !wasVisible, let reveal = try? context.require(CapabilityReveal.self) {
                revealed = await reveal(selected.reference.capabilitySet) != .none
            }
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
                revealed: revealed,
                // The runtime keeps a session's tool definitions as they
                // opened; what is revealed later is called through the
                // dispatcher, when there is one.
                callWith: revealed && snapshot.visible.tools.contains(CallCapability.identifier)
                    ? CallCapability.identifier.rawValue
                    : nil
            )
        }
    }
}

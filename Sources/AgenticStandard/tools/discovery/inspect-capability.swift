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
            /// How to call it when it is not among the tool definitions: its
            /// own name where the model's route takes such calls, else
            /// `call_capability`. The definitions stay as the conversation
            /// opened, so the provider's cache holds.
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
            "Return one available capability's full contract, including optional fields and guidance. Reading it changes nothing. Call a capability among your tools by its own name; one that is not among them is called as `callWith` says."
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
                callWith: Self.callWith(
                    input.kind,
                    identifier: selected.identifier,
                    declared: wasVisible,
                    dispatcher: snapshot.visible.tools.contains(CallCapability.identifier),
                    byName: (try? context.require(UndeclaredCallForm.self))?.byName == true
                )
            )
        }

    /// Nil for a declared capability, called by its name as usual. A
    /// tool outside the definitions is called by its own name where the
    /// route takes such calls; the rest go through the dispatcher, the
    /// only form every gateway takes (programs, inferences and agents have
    /// provider names the model never sees).
    private static func callWith(
        _ kind: CapabilityKind,
        identifier: String,
        declared: Bool,
        dispatcher: Bool,
        byName: Bool
    ) -> String? {
        guard !declared else { return nil }
        if byName, kind == .tool {
            return identifier
        }
        return dispatcher ? CallCapability.identifier.rawValue : nil
    }
    }
}

import Agentic
import Macros
import Primitives
import Schema

public enum InspectCapabilityError: Error, Sendable {
    case notAvailable
}

public extension Capabilities.Tools {
    @Tool("inspect")
    struct Inspect: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            /// Its kind; needed only for a name that does not say it.
            public let kind: CapabilityKind?
            /// The capability, as search names it. A shorter form
            /// (`domain.name`, or a bare name) works when it is unambiguous.
            public let identifier: String
            /// Its domain, only when a bare name is shared by several domains.
            public let domain: String?

            public init(kind: CapabilityKind? = nil, identifier: String, domain: String? = nil) {
                self.kind = kind
                self.identifier = identifier
                self.domain = domain
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
            /// `capabilities_tool_call`. The definitions stay as the conversation
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

        public func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            let (snapshot, available) = try await CapabilityDiscovery.available(in: context)
            let selected = try Self.select(input, among: available, domains: context.catalog.domains)
            let wasVisible = CapabilityDiscovery.contains(selected.reference, in: snapshot.visible)
            return Output(
                kind: selected.reference.capabilityKind,
                identifier: selected.identifier,
                namespace: selected.namespace,
                purpose: selected.purpose,
                input: selected.input,
                output: selected.output,
                modelInputSchema: selected.modelInputSchema,
                risk: selected.risk.map { String(describing: $0) },
                wasVisible: wasVisible,
                callWith: Self.callWith(
                    selected.reference,
                    declared: wasVisible,
                    dispatcher: snapshot.visible.tools.contains(Call.identifier),
                    byName: (try? context.require(UndeclaredCallForm.self))?.byName == true
                )
            )
        }

    /// The available capability the input names: exactly, or through
    /// `CapabilityReference.Raw` (aliases, `domain.name`, a bare name).
    static func select(
        _ input: Input,
        among available: [CapabilityInspection],
        domains: [DomainDefinition]
    ) throws -> CapabilityInspection {
        if input.domain == nil, let exact = available.first(where: {
            $0.identifier == input.identifier && (input.kind == nil || $0.kind == input.kind?.rawValue)
        }) {
            return exact
        }
        let kinds: [CapabilityKind] = input.kind.map { [$0] }
            ?? (try? CapabilityIdentity(input.identifier)).map { [$0.kind] }
            ?? CapabilityKind.allCases
        for kind in kinds {
            do {
                let reference = try CapabilityReference(.init(
                    input.identifier,
                    domain: input.domain,
                    kind: kind,
                    domains: domains,
                    offered: available.map(\.reference)
                ))
                if let match = available.first(where: { $0.reference == reference }) {
                    return match
                }
            } catch CapabilityReferenceError.notFound {
                continue
            }
        }
        throw InspectCapabilityError.notAvailable
    }

    /// Nil for a declared capability, called by its name as usual. One
    /// outside the definitions is called by its provider name where the
    /// route takes such calls, else through the dispatcher, the only form
    /// every gateway takes.
    private static func callWith(
        _ reference: CapabilityReference,
        declared: Bool,
        dispatcher: Bool,
        byName: Bool
    ) -> String? {
        guard !declared else { return nil }
        if byName {
            return reference.providerName
        }
        return dispatcher ? Call.identifier.rawValue : nil
    }
    }
}

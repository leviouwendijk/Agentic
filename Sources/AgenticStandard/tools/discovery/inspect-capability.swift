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
            public let kind: FindCapabilities.Kind
            public let identifier: String
            public init(kind: FindCapabilities.Kind, identifier: String) {
                self.kind = kind
                self.identifier = identifier
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let kind: FindCapabilities.Kind
            public let identifier: String
            public let namespace: String?
            public let purpose: String
            public let input: JSONValue
            public let output: JSONValue
            public let modelInputSchema: JSONValue?
            public let risk: String?
            public let wasVisible: Bool

            public init(
                kind: FindCapabilities.Kind,
                identifier: String,
                namespace: String?,
                purpose: String,
                input: JSONValue,
                output: JSONValue,
                modelInputSchema: JSONValue?,
                risk: String?,
                wasVisible: Bool
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
            }
        }

        public static let purpose =
            "Inspect one available installed capability's authentic typed contracts without exposing or invoking it."
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
            return Output(
                kind: input.kind,
                identifier: selected.identifier,
                namespace: selected.namespace,
                purpose: selected.purpose,
                input: selected.input,
                output: selected.output,
                modelInputSchema: selected.modelInputSchema,
                risk: selected.risk.map { String(describing: $0) },
                wasVisible: CapabilityDiscovery.contains(selected.reference, in: snapshot.visible)
            )
        }
    }
}

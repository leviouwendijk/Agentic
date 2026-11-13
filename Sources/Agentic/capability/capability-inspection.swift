import Primitives

/// A transient read-only description derived from an installed executable binding.
/// This is neither an installation registry nor an invocation authorization token.
public struct CapabilityInspection: Sendable {
    public let reference: CapabilityReference
    public let namespace: String?
    public let purpose: String
    public let input: JSONValue
    public let output: JSONValue
    public let modelInputSchema: JSONValue?
    public let risk: ActionRisk?

    public init(
        reference: CapabilityReference,
        namespace: String? = nil,
        purpose: String,
        input: JSONValue,
        output: JSONValue,
        modelInputSchema: JSONValue? = nil,
        risk: ActionRisk? = nil
    ) {
        self.reference = reference
        self.namespace = namespace
        self.purpose = purpose
        self.input = input
        self.output = output
        self.modelInputSchema = modelInputSchema
        self.risk = risk
    }

    public var kind: String {
        switch reference {
        case .tool: "tool"
        case .program: "program"
        case .inference: "inference"
        case .agent: "agent"
        }
    }

    public var identifier: String {
        switch reference {
        case .tool(let identifier): identifier.rawValue
        case .program(let identifier): identifier.rawValue
        case .inference(let identifier): identifier.rawValue
        case .agent(let identifier): identifier.rawValue
        }
    }
}

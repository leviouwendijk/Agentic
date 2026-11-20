import Agentic
import Macros
import Schema

@DomainMember(LinkerCatalogFixture.self)
public struct LinkerCatalogTopLevelTool: Tool {
    @JSONSchema
    public struct Input: HashableSource {
        public init() {}
    }
    @JSONSchema
    public struct Output: HashableResult {
        public let text: String
        public init(text: String) { self.text = text }
    }
    public static let identifier: ToolIdentifier = "linker_fixture_top_level"
    public static let purpose = "Proves explicit typed Domain membership for a top-level Tool."
    public static let risk: ActionRisk = .observe
    public static let definition = ToolDefinition(
        identifier: identifier,
        purpose: purpose,
        risk: risk
    )
    public init() {}
    public func call(_ input: Input, in context: ToolContext) async throws -> Output {
        _ = input
        _ = context
        return Output(text: "linked")
    }
}

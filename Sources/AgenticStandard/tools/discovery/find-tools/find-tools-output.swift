import Agentic
import Macros
import Schema

@JSONSchema
public struct FoundTool:
    Sendable,
    Codable,
    Hashable
{
    public let identifier: ToolIdentifier
    public let description: String
    public let risk: ActionRisk

    public init(
        identifier: ToolIdentifier,
        description: String,
        risk: ActionRisk
    ) {
        self.identifier = identifier
        self.description = description
        self.risk = risk
    }
}

@JSONSchema
public struct FindToolsOutput:
    Sendable,
    Codable,
    Hashable
{
    public let query: String
    public let tools: [FoundTool]
    public let activated: [ToolIdentifier]

    public init(
        query: String,
        tools: [FoundTool],
        activated: [ToolIdentifier]
    ) {
        self.query = query
        self.tools = tools
        self.activated = activated
    }
}

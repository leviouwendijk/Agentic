import Macros
import Schema

@JSONSchema
public struct AgentSkillMetadata: Sendable, Codable, Hashable {
    @JSONSchema
    public struct ToolReferenceAPI: Sendable, Codable, Hashable {
        public var required: [ToolReference]
        public var optional: [ToolReference]
        
        public init(
            required: [ToolReference] = [],
            optional: [ToolReference] = []
        ) {
            self.required = required
            self.optional = optional
        }
    }

    public var domains: [AgentSkillDomain]
    public var tools: ToolReferenceAPI
    public var tags: [String]
    public var attributes: [String: String]

    public init(
        domains: [AgentSkillDomain] = [],
        tools: ToolReferenceAPI = .init(),
        tags: [String] = [],
        attributes: [String: String] = [:]
    ) {
        self.domains = domains
        self.tools = tools
        self.tags = tags
        self.attributes = attributes
    }

    public static let empty = Self()
}

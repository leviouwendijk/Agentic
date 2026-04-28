import Foundation

public enum ModeApplicationError: Error, Sendable, LocalizedError {
    case missingTool(String)

    public var errorDescription: String? {
        switch self {
        case .missingTool(let identifier):
            return "Mode application requires missing tool '\(identifier)'."
        }
    }
}

public struct ModeRuntimeApplication: Sendable {
    public var selection: ModeSelection
    public var configuration: AgentRunnerConfiguration
    public var routePolicy: AgentModelUsePolicy
    public var toolRegistry: ToolRegistry
    public var skillRegistry: SkillRegistry
    public var loadedSkills: [AgentSkill]
    public var missingSkillIdentifiers: [AgentSkillIdentifier]
    public var metadata: [String: String]

    public init(
        selection: ModeSelection,
        configuration: AgentRunnerConfiguration,
        routePolicy: AgentModelUsePolicy,
        toolRegistry: ToolRegistry,
        skillRegistry: SkillRegistry,
        loadedSkills: [AgentSkill],
        missingSkillIdentifiers: [AgentSkillIdentifier],
        metadata: [String: String] = [:]
    ) {
        self.selection = selection
        self.configuration = configuration
        self.routePolicy = routePolicy
        self.toolRegistry = toolRegistry
        self.skillRegistry = skillRegistry
        self.loadedSkills = loadedSkills
        self.missingSkillIdentifiers = missingSkillIdentifiers
        self.metadata = metadata
    }

    public var modeID: AgenticModeIdentifier {
        selection.modeID
    }

    public var toolDefinitions: [AgentToolDefinition] {
        toolRegistry.definitions
    }
}

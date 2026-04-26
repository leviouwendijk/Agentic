// to resolve fallout from converting AgentTool from static -> instance parameters
// this resolves that

import Primitives

public protocol StaticAgentToolMetadata: Sendable {
    static var identifier: AgentToolIdentifier { get }
    static var description: String { get }
    static var inputSchema: JSONValue? { get }
    static var risk: ActionRisk { get }
}

public extension StaticAgentToolMetadata {
    static var inputSchema: JSONValue? {
        nil
    }
}

public extension AgentTool where Self: StaticAgentToolMetadata {
    var identifier: AgentToolIdentifier {
        Self.identifier
    }

    var description: String {
        Self.description
    }

    var inputSchema: JSONValue? {
        Self.inputSchema
    }

    var risk: ActionRisk {
        Self.risk
    }
}

extension EmitArtifactTool: StaticAgentToolMetadata {}
extension ListArtifactsTool: StaticAgentToolMetadata {}
extension ReadArtifactTool: StaticAgentToolMetadata {}

extension ComposeContextTool: StaticAgentToolMetadata {}
extension EstimateContextSizeTool: StaticAgentToolMetadata {}
extension InspectContextSourcesTool: StaticAgentToolMetadata {}

extension ClarifyWithUserTool: StaticAgentToolMetadata {}

extension EditFileTool: StaticAgentToolMetadata {}
extension ReadFileTool: StaticAgentToolMetadata {}
extension ReadSelectionTool: StaticAgentToolMetadata {}
extension ScanPathsTool: StaticAgentToolMetadata {}
extension WriteFileTool: StaticAgentToolMetadata {}

extension ListPreparedIntentsTool: StaticAgentToolMetadata {}
extension ReadPreparedIntentTool: StaticAgentToolMetadata {}
extension ReviewPreparedIntentTool: StaticAgentToolMetadata {}

extension ListAgentArtifactsTool: StaticAgentToolMetadata {}
extension ListAgentPreparedIntentsTool: StaticAgentToolMetadata {}
extension ListAgentSessionsTool: StaticAgentToolMetadata {}
extension ReadAgentApprovalsTool: StaticAgentToolMetadata {}
extension ReadAgentArtifactTool: StaticAgentToolMetadata {}
extension ReadAgentPreparedIntentTool: StaticAgentToolMetadata {}
extension ReadAgentSessionTool: StaticAgentToolMetadata {}
extension ReadAgentTranscriptTool: StaticAgentToolMetadata {}

extension ListSkillsTool: StaticAgentToolMetadata {}
extension LoadSkillTool: StaticAgentToolMetadata {}

extension CreateAgentTaskTool: StaticAgentToolMetadata {}
extension UpdateAgentTaskTool: StaticAgentToolMetadata {}
extension ListAgentTasksTool: StaticAgentToolMetadata {}
extension GetAgentTaskTool: StaticAgentToolMetadata {}
extension ClaimAgentTaskTool: StaticAgentToolMetadata {}
extension CompleteAgentTaskTool: StaticAgentToolMetadata {}

extension ReadTranscriptEventsTool: StaticAgentToolMetadata {}
extension SearchTranscriptTool: StaticAgentToolMetadata {}
extension SummarizeTranscriptWindowTool: StaticAgentToolMetadata {}

extension ExplainPathAccessTool: StaticAgentToolMetadata {}
extension FindPathsTool: StaticAgentToolMetadata {}
extension InspectWorkspaceTool: StaticAgentToolMetadata {}
extension ListPathGrantsTool: StaticAgentToolMetadata {}
extension ListPathRootsTool: StaticAgentToolMetadata {}
extension RequestPathGrantTool: StaticAgentToolMetadata {}

public extension AgentToolReference {
    static func tool<T>(
        _ type: T.Type,
        owner: String? = nil
    ) -> Self where T: StaticAgentToolMetadata {
        .init(
            identifier: type.identifier,
            owner: owner
        )
    }
}

extension ListFileMutationsTool: StaticAgentToolMetadata {}
extension InspectFileMutationTool: StaticAgentToolMetadata {}

extension EditFileTool {
    public static var inputSchema: JSONValue? {
        EditFileToolInput.schema
    }
}

extension ReadFileTool {
    public static var inputSchema: JSONValue? {
        ReadFileToolInput.schema
    }
}

// to resolve fallout from converting AgentTool from static -> instance parameters
// this resolves that

import Primitives

public protocol StaticAgentTool: Sendable, AgentTool {
    static var identifier: AgentToolIdentifier { get }
    static var description: String { get }
    static var inputSchema: JSONValue? { get }
    static var risk: ActionRisk { get }
}

public extension StaticAgentTool {
    static var inputSchema: JSONValue? {
        nil
    }
}

// public extension AgentTool where Self: StaticAgentToolMetadata {
public extension StaticAgentTool {
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

extension EmitArtifactTool: StaticAgentTool {}
extension ListArtifactsTool: StaticAgentTool {}
extension ReadArtifactTool: StaticAgentTool {}

extension ComposeContextTool: StaticAgentTool {}
extension EstimateContextSizeTool: StaticAgentTool {}
extension InspectContextSourcesTool: StaticAgentTool {}

extension ClarifyWithUserTool: StaticAgentTool {}

extension EditFileTool: StaticAgentTool {}
extension ReadFileTool: StaticAgentTool {}
extension ReadSelectionTool: StaticAgentTool {}
extension ScanPathsTool: StaticAgentTool {}
extension WriteFileTool: StaticAgentTool {}

extension ListPreparedIntentsTool: StaticAgentTool {}
extension ReadPreparedIntentTool: StaticAgentTool {}
extension ReviewPreparedIntentTool: StaticAgentTool {}

extension ListAgentArtifactsTool: StaticAgentTool {}
extension ListAgentPreparedIntentsTool: StaticAgentTool {}
extension ListAgentSessionsTool: StaticAgentTool {}
extension ReadAgentApprovalsTool: StaticAgentTool {}
extension ReadAgentArtifactTool: StaticAgentTool {}
extension ReadAgentPreparedIntentTool: StaticAgentTool {}
extension ReadAgentSessionTool: StaticAgentTool {}
extension ReadAgentTranscriptTool: StaticAgentTool {}

extension ListSkillsTool: StaticAgentTool {}
extension LoadSkillTool: StaticAgentTool {}

extension CreateAgentTaskTool: StaticAgentTool {}
extension UpdateAgentTaskTool: StaticAgentTool {}
extension ListAgentTasksTool: StaticAgentTool {}
extension GetAgentTaskTool: StaticAgentTool {}
extension ClaimAgentTaskTool: StaticAgentTool {}
extension CompleteAgentTaskTool: StaticAgentTool {}

extension ReadTranscriptEventsTool: StaticAgentTool {}
extension SearchTranscriptTool: StaticAgentTool {}
extension SummarizeTranscriptWindowTool: StaticAgentTool {}

extension ExplainPathAccessTool: StaticAgentTool {}
extension FindPathsTool: StaticAgentTool {}
extension InspectWorkspaceTool: StaticAgentTool {}
extension ListPathGrantsTool: StaticAgentTool {}
extension ListPathRootsTool: StaticAgentTool {}
extension RequestPathGrantTool: StaticAgentTool {}

public extension AgentToolReference {
    static func tool<T>(
        _ type: T.Type,
        owner: String? = nil
    ) -> Self where T: StaticAgentTool {
        .init(
            identifier: type.identifier,
            owner: owner
        )
    }
}

extension ListFileMutationsTool: StaticAgentTool {}
extension InspectFileMutationTool: StaticAgentTool {}

// extension EditFileTool {
//     public static var inputSchema: JSONValue? {
//         EditFileToolInput.schema
//     }
// }

// extension ReadFileTool {
//     public static var inputSchema: JSONValue? {
//         ReadFileToolInput.schema
//     }
// }

// extension MutateFilesTool: StaticAgentToolMetadata {
//     public static var inputSchema: JSONValue? {
//         MutateFilesToolInput.schema
//     }
// }

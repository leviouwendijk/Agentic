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
        .object([
            "type": .string("object"),
            "properties": .object([
                "rootID": .object([
                    "type": .string("string"),
                    "description": .string("Workspace root identifier. Usually use 'project'.")
                ]),
                "path": .object([
                    "type": .string("string"),
                    "description": .string("Path to the file relative to the workspace root.")
                ]),
                "operations": .object([
                    "type": .string("array"),
                    "description": .string("Ordered edit operations to apply."),
                    "items": .object([
                        "type": .string("object"),
                        "properties": .object([
                            "kind": .object([
                                "type": .string("string"),
                                "enum": .array([
                                    .string("replace_entire_file"),
                                    .string("append"),
                                    .string("prepend"),
                                    .string("replace_first"),
                                    .string("replace_all"),
                                    .string("replace_unique"),
                                    .string("replace_line"),
                                    .string("insert_lines"),
                                    .string("replace_lines"),
                                    .string("delete_lines")
                                ])
                            ]),
                            "content": .object([
                                "type": .string("string"),
                                "description": .string("Content for replace_entire_file, append, prepend, or replace_line.")
                            ]),
                            "target": .object([
                                "type": .string("string"),
                                "description": .string("Existing text to replace for replace_first, replace_all, or replace_unique.")
                            ]),
                            "replacement": .object([
                                "type": .string("string"),
                                "description": .string("Replacement text for replace_first, replace_all, or replace_unique.")
                            ]),
                            "line": .object([
                                "type": .string("integer"),
                                "description": .string("1-based line number for replace_line.")
                            ]),
                            "lines": .object([
                                "type": .string("array"),
                                "items": .object([
                                    "type": .string("string")
                                ]),
                                "description": .string("Lines for insert_lines or replace_lines.")
                            ]),
                            "atLine": .object([
                                "type": .string("integer"),
                                "description": .string("1-based insertion line for insert_lines.")
                            ]),
                            "range": .object([
                                "type": .string("object"),
                                "properties": .object([
                                    "start": .object([
                                        "type": .string("integer")
                                    ]),
                                    "end": .object([
                                        "type": .string("integer")
                                    ])
                                ]),
                                "required": .array([
                                    .string("start"),
                                    .string("end")
                                ])
                            ]),
                            "separator": .object([
                                "type": .string("string"),
                                "description": .string("Optional separator for append/prepend.")
                            ])
                        ]),
                        "required": .array([
                            .string("kind")
                        ])
                    ])
                ])
            ]),
            "required": .array([
                .string("path"),
                .string("operations")
            ])
        ])
    }
}

extension ReadFileTool {
    public static var inputSchema: JSONValue? {
        .object([
            "type": .string("object"),
            "properties": .object([
                "rootID": .object([
                    "type": .string("string"),
                    "description": .string("Workspace root identifier. Usually use 'project'.")
                ]),
                "path": .object([
                    "type": .string("string"),
                    "description": .string("Path to the file relative to the workspace root.")
                ]),
                "startLine": .object([
                    "type": .string("integer"),
                    "description": .string("Optional 1-based first line to read.")
                ]),
                "endLine": .object([
                    "type": .string("integer"),
                    "description": .string("Optional 1-based final line to read.")
                ]),
                "maxLines": .object([
                    "type": .string("integer"),
                    "description": .string("Optional maximum number of lines to read.")
                ]),
                "includeLineNumbers": .object([
                    "type": .string("boolean"),
                    "description": .string("Whether to include line numbers in returned content.")
                ])
            ]),
            "required": .array([
                .string("path")
            ])
        ])
    }
}

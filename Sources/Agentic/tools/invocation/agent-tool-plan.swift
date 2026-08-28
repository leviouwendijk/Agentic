import Foundation
import Primitives

public enum AgentToolPlanNodeKind:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case call
    case sequence
    case batch
}

public struct AgentToolPlan:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let id: String
    public let root: AgentToolPlanNode
    public let guidelineRelations: [AgentGuidelineRelation]

    public init(
        id: String = UUID().uuidString,
        root: AgentToolPlanNode,
        guidelineRelations: [AgentGuidelineRelation] = []
    ) {
        self.id = id
        self.root = root
        self.guidelineRelations = guidelineRelations
    }

    private enum CodingKeys:
        String,
        CodingKey
    {
        case id
        case root
        case guidelineRelations
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        self.id = try container.decode(
            String.self,
            forKey: .id
        )

        self.root = try container.decode(
            AgentToolPlanNode.self,
            forKey: .root
        )

        self.guidelineRelations =
            try container.decodeIfPresent(
                [AgentGuidelineRelation].self,
                forKey: .guidelineRelations
            )
            ?? []
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            id,
            forKey: .id
        )

        try container.encode(
            root,
            forKey: .root
        )

        try container.encode(
            guidelineRelations,
            forKey: .guidelineRelations
        )
    }

    public func validate() throws {
        var callIDs = Set<String>()

        try root.validate(
            path: "root",
            callIDs: &callIDs
        )
    }
}

public struct AgentToolPlanNode:
    Sendable,
    Codable,
    Hashable
{
    public let kind: AgentToolPlanNodeKind
    public let call: AgentToolCall?
    public let execution: JSONValue?
    public let children: [AgentToolPlanNode]
    public let onSuccess: [AgentToolPlanNode]
    public let onFailure: [AgentToolPlanNode]
    public let onDenied: [AgentToolPlanNode]

    public init(
        kind: AgentToolPlanNodeKind,
        call: AgentToolCall? = nil,
        execution: JSONValue? = nil,
        children: [AgentToolPlanNode] = [],
        onSuccess: [AgentToolPlanNode] = [],
        onFailure: [AgentToolPlanNode] = [],
        onDenied: [AgentToolPlanNode] = []
    ) {
        self.kind = kind
        self.call = call
        self.execution = execution
        self.children = children
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.onDenied = onDenied
    }

    public static func call(
        _ call: AgentToolCall,
        execution: JSONValue? = nil,
        onSuccess: [Self] = [],
        onFailure: [Self] = [],
        onDenied: [Self] = []
    ) -> Self {
        .init(
            kind: .call,
            call: call,
            execution: execution,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onDenied: onDenied
        )
    }

    public static func sequence(
        _ children: [Self]
    ) -> Self {
        .init(
            kind: .sequence,
            children: children
        )
    }

    public static func batch(
        _ children: [Self]
    ) -> Self {
        .init(
            kind: .batch,
            children: children
        )
    }
}

public enum AgentToolPlanError:
    Error,
    Sendable,
    LocalizedError,
    Equatable
{
    case invalidNode(
        path: String,
        reason: String
    )

    case duplicateToolCallID(
        String
    )

    public var errorDescription: String? {
        switch self {
        case .invalidNode(
            let path,
            let reason
        ):
            return "Invalid tool-plan node at '\(path)': \(reason)"

        case .duplicateToolCallID(
            let id
        ):
            return "AgentToolPlan contains duplicate tool call id '\(id)'."
        }
    }
}

private extension AgentToolPlanNode {
    func validate(
        path: String,
        callIDs: inout Set<String>
    ) throws {
        switch kind {
        case .call:
            guard let call else {
                throw AgentToolPlanError.invalidNode(
                    path: path,
                    reason: "call nodes require an AgentToolCall."
                )
            }

            guard children.isEmpty else {
                throw AgentToolPlanError.invalidNode(
                    path: path,
                    reason: "call nodes cannot contain children; use outcome branches."
                )
            }

            guard callIDs.insert(
                call.id
            ).inserted else {
                throw AgentToolPlanError.duplicateToolCallID(
                    call.id
                )
            }

            try validate(
                onSuccess,
                label: "onSuccess",
                path: path,
                callIDs: &callIDs
            )

            try validate(
                onFailure,
                label: "onFailure",
                path: path,
                callIDs: &callIDs
            )

            try validate(
                onDenied,
                label: "onDenied",
                path: path,
                callIDs: &callIDs
            )

        case .sequence,
             .batch:
            guard call == nil,
                  execution == nil
            else {
                throw AgentToolPlanError.invalidNode(
                    path: path,
                    reason: "\(kind.rawValue) nodes cannot contain a direct AgentToolCall or execution directive."
                )
            }

            guard onSuccess.isEmpty,
                  onFailure.isEmpty,
                  onDenied.isEmpty
            else {
                throw AgentToolPlanError.invalidNode(
                    path: path,
                    reason: "\(kind.rawValue) nodes cannot define outcome branches."
                )
            }

            try validate(
                children,
                label: kind.rawValue,
                path: path,
                callIDs: &callIDs
            )
        }
    }

    func validate(
        _ nodes: [AgentToolPlanNode],
        label: String,
        path: String,
        callIDs: inout Set<String>
    ) throws {
        for (
            index,
            node
        ) in nodes.enumerated() {
            try node.validate(
                path: "\(path).\(label)[\(index)]",
                callIDs: &callIDs
            )
        }
    }
}

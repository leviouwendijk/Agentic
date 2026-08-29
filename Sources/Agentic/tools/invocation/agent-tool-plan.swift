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

    /// Check whole-tree invariants that cannot be represented by one node.
    ///
    /// Node structure itself is encoded by AgentToolPlanNode cases.
    public func validate() throws {
        var callIDs = Set<String>()

        try root.validateUniqueCallIDs(
            callIDs: &callIDs
        )
    }
}

/// Structurally valid AgentToolPlan node.
///
/// The enum cases encode the legal node shapes directly:
/// - call nodes own one call, optional execution metadata, and outcome branches;
/// - sequence and batch nodes own children only.
public indirect enum AgentToolPlanNode:
    Sendable,
    Codable,
    Hashable
{
    case call(
        AgentToolCall,
        execution: JSONValue? = nil,
        onSuccess: [Self] = [],
        onFailure: [Self] = [],
        onDenied: [Self] = []
    )

    case sequence(
        [Self]
    )

    case batch(
        [Self]
    )

    public var kind: AgentToolPlanNodeKind {
        switch self {
        case .call:
            .call

        case .sequence:
            .sequence

        case .batch:
            .batch
        }
    }

    public var call: AgentToolCall? {
        guard case .call(
            let call,
            _,
            _,
            _,
            _
        ) = self else {
            return nil
        }

        return call
    }

    public var execution: JSONValue? {
        guard case .call(
            _,
            let execution,
            _,
            _,
            _
        ) = self else {
            return nil
        }

        return execution
    }

    public var children: [Self] {
        switch self {
        case .call:
            []

        case .sequence(let children),
             .batch(let children):
            children
        }
    }

    public var onSuccess: [Self] {
        guard case .call(
            _,
            _,
            let onSuccess,
            _,
            _
        ) = self else {
            return []
        }

        return onSuccess
    }

    public var onFailure: [Self] {
        guard case .call(
            _,
            _,
            _,
            let onFailure,
            _
        ) = self else {
            return []
        }

        return onFailure
    }

    public var onDenied: [Self] {
        guard case .call(
            _,
            _,
            _,
            _,
            let onDenied
        ) = self else {
            return []
        }

        return onDenied
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

public extension AgentToolPlanNode {
    private enum CodingKeys:
        String,
        CodingKey
    {
        case kind
        case call
        case execution
        case children
        case onSuccess
        case onFailure
        case onDenied
    }

    init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        let kind = try container.decode(
            AgentToolPlanNodeKind.self,
            forKey: .kind
        )

        let children = try container.decode(
            [Self].self,
            forKey: .children
        )

        let onSuccess = try container.decode(
            [Self].self,
            forKey: .onSuccess
        )

        let onFailure = try container.decode(
            [Self].self,
            forKey: .onFailure
        )

        let onDenied = try container.decode(
            [Self].self,
            forKey: .onDenied
        )

        switch kind {
        case .call:
            guard children.isEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .children,
                    in: container,
                    debugDescription:
                        "Call nodes cannot contain ordinary children."
                )
            }

            self = .call(
                try container.decode(
                    AgentToolCall.self,
                    forKey: .call
                ),
                execution: try container.decodeIfPresent(
                    JSONValue.self,
                    forKey: .execution
                ),
                onSuccess: onSuccess,
                onFailure: onFailure,
                onDenied: onDenied
            )

        case .sequence,
             .batch:
            guard !container.contains(.call),
                  !container.contains(.execution)
            else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription:
                        "\(kind.rawValue) nodes cannot contain a call or execution directive."
                )
            }

            guard onSuccess.isEmpty,
                  onFailure.isEmpty,
                  onDenied.isEmpty
            else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription:
                        "\(kind.rawValue) nodes cannot define outcome branches."
                )
            }

            self =
                kind == .sequence
                    ? .sequence(children)
                    : .batch(children)
        }
    }

    func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            kind,
            forKey: .kind
        )

        switch self {
        case .call(
            let call,
            let execution,
            let onSuccess,
            let onFailure,
            let onDenied
        ):
            try container.encode(
                call,
                forKey: .call
            )

            try container.encodeIfPresent(
                execution,
                forKey: .execution
            )

            try container.encode(
                [Self](),
                forKey: .children
            )

            try container.encode(
                onSuccess,
                forKey: .onSuccess
            )

            try container.encode(
                onFailure,
                forKey: .onFailure
            )

            try container.encode(
                onDenied,
                forKey: .onDenied
            )

        case .sequence(let children),
             .batch(let children):
            try container.encode(
                children,
                forKey: .children
            )

            try container.encode(
                [Self](),
                forKey: .onSuccess
            )

            try container.encode(
                [Self](),
                forKey: .onFailure
            )

            try container.encode(
                [Self](),
                forKey: .onDenied
            )
        }
    }

    fileprivate func validateUniqueCallIDs(
        callIDs: inout Set<String>
    ) throws {
        switch self {
        case .call(
            let call,
            _,
            let onSuccess,
            let onFailure,
            let onDenied
        ):
            guard callIDs.insert(
                call.id
            ).inserted else {
                throw AgentToolPlanError.duplicateToolCallID(
                    call.id
                )
            }

            try validateUniqueCallIDs(
                onSuccess,
                callIDs: &callIDs
            )

            try validateUniqueCallIDs(
                onFailure,
                callIDs: &callIDs
            )

            try validateUniqueCallIDs(
                onDenied,
                callIDs: &callIDs
            )

        case .sequence(let children),
             .batch(let children):
            try validateUniqueCallIDs(
                children,
                callIDs: &callIDs
            )
        }
    }

    fileprivate func validateUniqueCallIDs(
        _ nodes: [Self],
        callIDs: inout Set<String>
    ) throws {
        for node in nodes {
            try node.validateUniqueCallIDs(
                callIDs: &callIDs
            )
        }
    }
}

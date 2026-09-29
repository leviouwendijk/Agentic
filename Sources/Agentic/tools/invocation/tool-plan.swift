import Foundation
import Primitives

public struct ToolPlan:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let id: String
    public let root: Node
    public let guidelines: [AgentGuidelineRelation]

    public init(
        id: String = UUID().uuidString,
        root: Node,
        guidelines: [AgentGuidelineRelation] = []
    ) throws {
        try root.requireUniqueCallIDs()

        self.id = id
        self.root = root
        self.guidelines = guidelines
    }

    private enum CodingKeys:
        String,
        CodingKey
    {
        case id
        case root
        case guidelines
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        try self.init(
            id: container.decode(
                String.self,
                forKey: .id
            ),
            root: container.decode(
                Node.self,
                forKey: .root
            ),
            guidelines: container.decodeIfPresent(
                [AgentGuidelineRelation].self,
                forKey: .guidelines
            ) ?? []
        )
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
            guidelines,
            forKey: .guidelines
        )
    }
}

public extension ToolPlan {
    indirect enum Node:
        Sendable,
        Codable,
        Hashable
    {
        public enum Kind:
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

        case call(
            ToolCall,
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

        public var kind: Kind {
            switch self {
            case .call:
                .call

            case .sequence:
                .sequence

            case .batch:
                .batch
            }
        }

        public var call: ToolCall? {
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

    enum Error:
        Swift.Error,
        Sendable,
        LocalizedError,
        Equatable
    {
        case duplicateToolCallID(
            String
        )

        public var errorDescription: String? {
            switch self {
            case .duplicateToolCallID(
                let id
            ):
                "ToolPlan contains duplicate tool call id '\(id)'."
            }
        }
    }
}

public extension ToolPlan.Node {
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
            Kind.self,
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
                    ToolCall.self,
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
}

private extension ToolPlan.Node {
    func requireUniqueCallIDs() throws {
        var callIDs = Set<String>()

        try requireUniqueCallIDs(
            callIDs: &callIDs
        )
    }

    func requireUniqueCallIDs(
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
                throw ToolPlan.Error.duplicateToolCallID(
                    call.id
                )
            }

            try requireUniqueCallIDs(
                onSuccess,
                callIDs: &callIDs
            )

            try requireUniqueCallIDs(
                onFailure,
                callIDs: &callIDs
            )

            try requireUniqueCallIDs(
                onDenied,
                callIDs: &callIDs
            )

        case .sequence(let children),
             .batch(let children):
            try requireUniqueCallIDs(
                children,
                callIDs: &callIDs
            )
        }
    }

    func requireUniqueCallIDs(
        _ nodes: [Self],
        callIDs: inout Set<String>
    ) throws {
        for node in nodes {
            try node.requireUniqueCallIDs(
                callIDs: &callIDs
            )
        }
    }
}

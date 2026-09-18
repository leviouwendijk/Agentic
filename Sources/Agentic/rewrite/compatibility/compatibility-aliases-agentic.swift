// temporary, remove when all warnings are gon
import Foundation

// Deprecated Tool compatibility

@available(
    *,
    deprecated,
    renamed: "ToolIdentifier"
)
public typealias AgentToolIdentifier =
    ToolIdentifier

@available(
    *,
    deprecated,
    renamed: "ToolReference"
)
public typealias AgentToolReference =
    ToolReference

@available(
    *,
    deprecated,
    renamed: "ToolDescriptor"
)
public typealias AgentToolDefinition =
    ToolDescriptor

@available(
    *,
    deprecated,
    renamed: "ToolCall"
)
public typealias AgentToolCall =
    ToolCall


// Deprecated ToolPlan compatibility

@available(
    *,
    deprecated,
    renamed: "ToolPlan"
)
public typealias AgentToolPlan =
    ToolPlan

@available(
    *,
    deprecated,
    renamed: "ToolPlan.Node"
)
public typealias AgentToolPlanNode =
    ToolPlan.Node

@available(
    *,
    deprecated,
    renamed: "ToolPlan.Node.Kind"
)
public typealias AgentToolPlanNodeKind =
    ToolPlan.Node.Kind

@available(
    *,
    deprecated,
    renamed: "ToolPlan.Error"
)
public typealias AgentToolPlanError =
    ToolPlan.Error

// MARK: - Deprecated ToolPlan members

public extension ToolPlan {
    @available(
        *,
        deprecated,
        message: "Use guidelines."
    )
    var guidelineRelations: [AgentGuidelineRelation] {
        guidelines
    }

    @available(
        *,
        deprecated,
        message: "Use init(id:root:guidelines:)."
    )
    init(
        id: String = UUID().uuidString,
        root: Node,
        guidelineRelations: [AgentGuidelineRelation]
    ) throws {
        try self.init(
            id: id,
            root: root,
            guidelines: guidelineRelations
        )
    }
}

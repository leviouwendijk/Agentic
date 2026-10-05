import Macros
import Primitives
import Schema

/// Workspace-relative execution target selected for one invocation.
///
/// `subpath` is relative to the session workspace root. For host workspaces such
/// as `swiftlibs/`, use sibling package/repository names (e.g. `Agentic`,
/// `AgenticIO`, `AgenticDomains`) for repository/package-local operations. Omit a
/// target only when the session workspace itself is intentionally the working
/// location.
@JSONSchema
public struct WorkspaceTarget:
    Sendable,
    Codable,
    Hashable
{
    public let subpath: String

    public init(
        subpath: String
    ) {
        self.subpath = subpath
    }
}

/// One interpreted model/provider Tool call against the Tool universe.
///
/// `ToolCall` is the raw model/provider-emitted transport; `ToolInvocation` is the
/// canonical interpreted invocation produced by the registry. It separates the
/// semantic `arguments` from the requested `execution` location so targeting never
/// leaks into the authored Tool input.
@JSONSchema
public struct ToolInvocation:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public let id: String
    public let tool: ToolIdentifier
    public let arguments: JSONValue
    public let execution: Execution?

    public init(
        id: String,
        tool: ToolIdentifier,
        arguments: JSONValue,
        execution: Execution? = nil
    ) {
        self.id = id
        self.tool = tool
        self.arguments = arguments
        self.execution = execution
    }
}

public extension ToolInvocation {
    @JSONSchema
    struct Execution:
        Sendable,
        Codable,
        Hashable
    {
        public let workspace: WorkspaceTarget?

        public init(
            workspace: WorkspaceTarget? = nil
        ) {
            self.workspace = workspace
        }
    }
}

public extension ToolInvocation {
    @JSONSchema
    struct Review:
        Sendable,
        Codable,
        Hashable
    {
        public let invocation: ToolInvocation
        public let preflight: ToolPreflight
        public let requirement: ApprovalRequirement
        public let references: [Reference]

        public init(
            invocation: ToolInvocation,
            preflight: ToolPreflight,
            requirement: ApprovalRequirement,
            references: [Reference] = []
        ) {
            self.invocation = invocation
            self.preflight = preflight
            self.requirement = requirement
            self.references = references
        }
    }

    @JSONSchema
    struct Prepared:
        Sendable,
        Codable,
        Hashable
    {
        public let review: Review
        public let operation: PreparedOperation.Envelope

        public init(
            review: Review,
            operation: PreparedOperation.Envelope
        ) {
            self.review = review
            self.operation = operation
        }
    }

    enum Interruption:
        String,
        Sendable,
        Codable,
        Hashable,
        CaseIterable
    {
        case human_review
    }

    enum Outcome:
        Sendable,
        Codable,
        Hashable
    {
        case executed(ToolExecutionResult)
        case denied
        case skipped
        case interrupted(Interruption)
    }

    struct Result:
        Sendable,
        Codable,
        Hashable
    {
        public let review: Review
        public let outcome: Outcome

        public init(
            review: Review,
            outcome: Outcome
        ) {
            self.review = review
            self.outcome = outcome
        }

        public var execution: ToolExecutionResult? {
            guard case .executed(let execution) = outcome else {
                return nil
            }

            return execution
        }

        public var decision: ApprovalDecision {
            switch outcome {
            case .executed:
                return .approved

            case .denied:
                return .denied

            case .skipped:
                return .skipped

            case .interrupted(.human_review):
                return .needshuman
            }
        }

        public var executed: Bool {
            execution != nil
        }
    }
}

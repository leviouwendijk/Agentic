/// An Agent derived from another: everything not changed in `fork` is the
/// base's. `@Agent` reads the derived statics as it reads any Agent's, so the
/// fork's definition holds the merged values under its own identifier.
///
///     @Agent
///     enum Primary: AgentFork {
///         typealias Base = General.Agents.GeneralPurpose
///         static let fork = AgentDerivation(
///             instructions: .appending("…"),
///             available: .domains(Standard.self, Git.self)
///         )
///     }
public protocol AgentFork: Agent
where
    InstructionSourceType == Instructions,
    Input == Base.Input,
    Output == Base.Output
{
    associatedtype Base: Agent
    associatedtype Input = Base.Input
    associatedtype Output = Base.Output
    static var fork: AgentDerivation { get }
}

public extension AgentFork {
    static var purpose: String {
        fork.purpose ?? Base.purpose
    }

    static var instructions: Instructions {
        fork.instructions.applied(to: Instructions(of: Base.self))
    }

    static var capabilities: AgentCapabilities {
        fork.applied(to: Base.capabilities)
    }

    static var modelSelection: AgentModelSelection {
        fork.modelSelection ?? Base.modelSelection
    }

    static var delegation: AgentDelegationPolicy {
        fork.delegation ?? Base.delegation
    }
}

/// What a fork changes about its base; `nil` and empty values inherit.
public struct AgentDerivation: Sendable {
    public enum InstructionChange: Sendable {
        case inherit
        case appending(Instructions)
        case prepending(Instructions)
        case replacing(Instructions)

        func applied(to base: Instructions) -> Instructions {
            switch self {
            case .inherit:
                base
            case .appending(let added):
                Instructions(base.parts + added.parts, separator: base.separator)
            case .prepending(let added):
                Instructions(added.parts + base.parts, separator: base.separator)
            case .replacing(let replacement):
                replacement
            }
        }
    }

    public let purpose: String?
    public let instructions: InstructionChange
    public let available: AgentCapabilityScope
    public let visible: AgentCapabilityScope
    /// Taken out of both the base's available and visible scopes.
    public let removing: AgentCapabilityScope
    /// Taken out of the visible scope only: still callable from programs (a Loa run),
    /// no longer offered to the model directly.
    public let hiding: AgentCapabilityScope
    public let grants: AgentCapabilityGrants?
    public let modelSelection: AgentModelSelection?
    public let delegation: AgentDelegationPolicy?

    public init(
        purpose: String? = nil,
        instructions: InstructionChange = .inherit,
        available: AgentCapabilityScope = .none,
        visible: AgentCapabilityScope = .none,
        removing: AgentCapabilityScope = .none,
        hiding: AgentCapabilityScope = .none,
        grants: AgentCapabilityGrants? = nil,
        modelSelection: AgentModelSelection? = nil,
        delegation: AgentDelegationPolicy? = nil
    ) {
        self.purpose = purpose
        self.instructions = instructions
        self.available = available
        self.visible = visible
        self.removing = removing
        self.hiding = hiding
        self.grants = grants
        self.modelSelection = modelSelection
        self.delegation = delegation
    }

    func applied(to base: AgentCapabilities) -> AgentCapabilities {
        let merged = base + AgentCapabilities(available: available, visible: visible)
        return AgentCapabilities(
            available: merged.available.removing(removing),
            visible: merged.visible.removing(removing).removing(hiding),
            grants: grants ?? merged.grants
        )
    }
}

public extension Instructions {
    /// An Agent's authored instructions as a composition, whatever their source.
    init<A: Agent>(of agent: A.Type) {
        guard let snapshot = agent.instructions.instructionSnapshot else {
            self.init([])
            return
        }
        self = snapshot.composition ?? Instructions(snapshot.content)
    }
}

public extension AgentCapabilityScope {
    static func domains(_ domains: any Domain.Type...) -> Self {
        .init(domains: domains)
    }

    static func domains(_ domains: [any Domain.Type]) -> Self {
        .init(domains: domains)
    }

    static func tools(_ tools: any Tool.Type...) -> Self {
        .init(tools: .init(members: tools))
    }

    static func programs(_ programs: any Program.Type...) -> Self {
        .init(programs: .init(members: programs))
    }

    static func inferences(_ inferences: any Inference.Type...) -> Self {
        .init(inferences: .init(members: inferences))
    }

    static func agents(_ agents: any Agent.Type...) -> Self {
        .init(agents: .init(members: agents))
    }

    /// Drops `other`'s domains and excludes its members.
    func removing(_ other: Self) -> Self {
        .init(
            tools: tools.removing(other.tools),
            programs: programs.removing(other.programs),
            inferences: inferences.removing(other.inferences),
            agents: agents.removing(other.agents)
        )
    }
}

extension AgentCapabilitySelection {
    func removing(_ other: Self) -> Self {
        guard !other.domains.isEmpty || !other.members.isEmpty else { return self }
        return .init(
            domains: domains.filter { !other.domains.contains($0) },
            members: members.filter { !other.members.contains($0) },
            excluding: excluding + other.members.filter { !excluding.contains($0) }
        )
    }
}

import Agentic

public extension Context.Allocator {
    /// Successfully resolved executable Agent, not an authority grant.
    /// Preferences are soft hints layered over the Agent's authored selection.
    struct Agent: Sendable {
        public let binding: AgentBinding
        public let modelPreferences: AgentModelPreferences

        public init(
            binding: AgentBinding,
            modelPreferences: AgentModelPreferences = .init()
        ) {
            self.binding = binding
            self.modelPreferences = modelPreferences
        }

        public var identifier: AgentIdentifier { binding.definition.identifier }

        /// Return a new value; existing invocation snapshots remain unchanged.
        public func selecting(_ preferences: AgentModelPreferences) -> Self {
            .init(binding: binding, modelPreferences: preferences)
        }

    }

    /// Successfully resolved Program. Installation never implies Agent exposure.
    struct Program: Sendable {
        public let binding: ProgramBinding

        public init(binding: ProgramBinding) {
            self.binding = binding
        }

        public var identifier: ProgramIdentifier { binding.identifier }
    }

    /// Only representable investigator targets are an Agent or a Program.
    enum Investigator: Sendable {
        case agent(Agent)
        case program(Program)
    }

    /// Optional collaborators for allocation decisions, not mandatory stages.
    /// The Allocator itself remains deterministic and is the only authority for
    /// context operations and frame preparation.
    /// A decision Inference is deferred until Core retains its typed binding.
    struct Preset: Sendable {
        public let id: String
        public let orchestrator: Agent?
        public let investigator: Investigator?

        public init(
            id: String,
            orchestrator: Agent? = nil,
            investigator: Investigator? = nil
        ) {
            self.id = id
            self.orchestrator = orchestrator
            self.investigator = investigator
        }
    }

    /// Revisioned immutable value, independently retained by an invocation.
    /// Not Codable: executable bindings cannot be reconstructed by decoding IDs.
    struct Snapshot: Sendable {
        public let revision: Int
        public let preset: Preset

        public var id: String { preset.id }
        public var orchestrator: Agent? { preset.orchestrator }
        public var investigator: Investigator? { preset.investigator }

        init(revision: Int, preset: Preset) {
            self.revision = revision
            self.preset = preset
        }
    }
}

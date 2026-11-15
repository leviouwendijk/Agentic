import Agentic
import Macros
import Schema

public extension Tasks {
    /// Typed input for an Agent that carries out one bounded task. Pair it
    /// with `AgentTaskAttemptReport` as that Agent's output.
    @JSONSchema
    struct Assignment: HashableSource {
        /// The durable task this assignment belongs to, when one exists.
        /// The assignee records its report against it.
        public let task: AgentTaskIdentifier?
        /// The binding description of the work to do.
        public let contract: AgentTaskContract
        /// Why the previous attempt was rejected, as bounded retry evidence.
        public let retryNote: String?

        public init(
            task: AgentTaskIdentifier? = nil,
            contract: AgentTaskContract,
            retryNote: String? = nil
        ) {
            self.task = task
            self.contract = contract
            self.retryNote = retryNote
        }
    }
}

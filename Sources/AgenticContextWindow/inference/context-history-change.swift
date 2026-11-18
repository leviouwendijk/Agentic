import Agentic

public extension ContextWindow.HistorySelection {
    /// Evidence of one transformation, in preparation order. Message and call
    /// identities resolve against canonical history; no source bodies are copied.
    struct Change: Sendable, Codable, Hashable {
        public enum Reason: String, Sendable, Codable, Hashable {
            case aged_result
            case budget_result
            case unseen_result
            case repeated_result
            case turn_budget
            case exchange_budget
            case working_set
            /// Replaced by a pointer recorded in an explicit compaction.
            case compacted
        }

        public let messageID: String
        public let reason: Reason
        public let call: FunctionCall.Reference?
        /// The earlier result referenced by a repeated-result pointer.
        public let sourceCall: FunctionCall.Reference?

        public init(
            messageID: String,
            reason: Reason,
            call: FunctionCall.Reference? = nil,
            sourceCall: FunctionCall.Reference? = nil
        ) {
            self.messageID = messageID
            self.reason = reason
            self.call = call
            self.sourceCall = sourceCall
        }
    }
}

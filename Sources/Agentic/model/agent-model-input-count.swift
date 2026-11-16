public extension AgentModelInvocation {
    /// A provider-reported input count for one routed, adapted request.
    /// This is not cached/uncached billing usage or an output-token allowance.
    /// Modifying the request or changing its route invalidates this evidence.
    struct InputCount: Sendable {
        public enum Error: Swift.Error, Sendable, Equatable {
            case negativeInputTokens(Int)
        }

        public let request: AgentRequest
        public let route: AgentModelRouteResult
        /// Nil means the selected provider does not implement input counting.
        public let inputTokens: Int?

        public init(
            request: AgentRequest,
            route: AgentModelRouteResult,
            inputTokens: Int?
        ) throws {
            if let inputTokens, inputTokens < 0 {
                throw Error.negativeInputTokens(inputTokens)
            }
            self.request = request
            self.route = route
            self.inputTokens = inputTokens
        }
    }
}

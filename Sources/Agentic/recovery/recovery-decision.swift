public extension Recovery {
    struct Decision:
        Sendable,
        Codable,
        Hashable
    {
        public let action: Action
        public let limit: Limit

        public init(
            action: Action,
            limit: Limit
        ) {
            self.action = action
            self.limit = limit
        }

        public init(
            step: Plan.Step
        ) {
            self.init(
                action: step.action,
                limit: step.limit
            )
        }
    }
}

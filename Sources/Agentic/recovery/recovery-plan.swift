public extension Recovery {
    struct Plan:
        Sendable,
        Codable,
        Hashable
    {
        public struct Step:
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
        }

        public let steps: [Step]

        public init(
            steps: [Step]
        ) {
            self.steps = steps
        }
    }
}

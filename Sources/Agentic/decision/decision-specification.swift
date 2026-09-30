public extension Decision {
    struct Specification<Output: Sendable>: Sendable {
        public let state: State
        public let query: Query<Output>

        public init<StateValue>(
            state: StateValue,
            query: Query<Output>
        ) throws
        where StateValue: Encodable & Sendable
        {
            self.state = try State(state)
            self.query = query
        }

        public func resolve(
            _ answers: [String: Answer]
        ) throws -> Output {
            try query.resolve(answers)
        }
    }
}

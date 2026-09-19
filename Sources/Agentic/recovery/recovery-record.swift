public extension Recovery {
    struct Record:
        Sendable,
        Codable,
        Hashable
    {
        public let incident: Incident
        public let plan: Plan?
        public let attempts: [Attempt]
        public let state: State
        public let outcome: Outcome

        public init(
            incident: Incident,
            plan: Plan?,
            attempts: [Attempt],
            state: State,
            outcome: Outcome
        ) {
            self.incident = incident
            self.plan = plan
            self.attempts = attempts
            self.state = state
            self.outcome = outcome
        }

        public init(
            incident: Incident,
            plan: Plan?,
            attempts: [Attempt],
            outcome: Outcome
        ) {
            self.init(
                incident: incident,
                plan: plan,
                attempts: attempts,
                state: incident.state,
                outcome: outcome
            )
        }
    }
}

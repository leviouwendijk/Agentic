public extension Recovery {
    struct Match:
        Sendable,
        Codable,
        Hashable
    {
        public let kind: Kind?
        public let stage: Stage?
        public let scope: Scope.Kind?
        public let effectState: EffectState?
        public let retrySafety: RetrySafety?

        public init(
            kind: Kind? = nil,
            stage: Stage? = nil,
            scope: Scope.Kind? = nil,
            effectState: EffectState? = nil,
            retrySafety: RetrySafety? = nil
        ) {
            self.kind = kind
            self.stage = stage
            self.scope = scope
            self.effectState = effectState
            self.retrySafety = retrySafety
        }

        public func matches(
            _ incident: Incident
        ) -> Bool {
            if let kind,
               kind != incident.kind
            {
                return false
            }

            if let stage,
               stage != incident.stage
            {
                return false
            }

            if let scope,
               scope != incident.scope.kind
            {
                return false
            }

            if let effectState,
               effectState != incident.effectState
            {
                return false
            }

            if let retrySafety,
               retrySafety != incident.retrySafety
            {
                return false
            }

            return true
        }

        var specificity: UInt {
            var value: UInt = 0

            if kind != nil {
                value += 1
            }

            if stage != nil {
                value += 1
            }

            if scope != nil {
                value += 1
            }

            if effectState != nil {
                value += 1
            }

            if retrySafety != nil {
                value += 1
            }

            return value
        }
    }
}

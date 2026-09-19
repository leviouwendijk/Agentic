public extension Recovery {
    struct Policy:
        Sendable,
        Codable,
        Hashable
    {
        public struct Rule:
            Sendable,
            Codable,
            Hashable
        {
            public let match: Match
            public let plan: Plan

            public init(
                match: Match,
                plan: Plan
            ) {
                self.match = match
                self.plan = plan
            }
        }

        public let rules: [Rule]

        public init(
            rules: [Rule] = []
        ) {
            self.rules = rules
        }

        /// Resolves the most specific matching rule.
        ///
        /// Rules with more constrained match dimensions take precedence.
        /// Equal-specificity ties preserve declaration order.
        public func rule(
            for incident: Incident
        ) -> Rule? {
            var selected: Rule?
            var selectedSpecificity: UInt?

            for rule in rules {
                guard rule.match.matches(
                    incident
                ) else {
                    continue
                }

                let specificity = rule.match.specificity

                if let selectedSpecificity,
                   specificity <= selectedSpecificity
                {
                    continue
                }

                selected = rule
                selectedSpecificity = specificity
            }

            return selected
        }

        public func plan(
            for incident: Incident
        ) -> Plan? {
            rule(
                for: incident
            )?.plan
        }
    }
}

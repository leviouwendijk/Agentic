public extension Recovery {
    struct Budget:
        Sendable,
        Codable,
        Hashable
    {
        public struct Usage:
            Sendable,
            Codable,
            Hashable
        {
            public let incidentAttempts: UInt
            public let scopeAttempts: UInt
            public let totalAttempts: UInt

            public init(
                incidentAttempts: UInt,
                scopeAttempts: UInt,
                totalAttempts: UInt
            ) {
                self.incidentAttempts = incidentAttempts
                self.scopeAttempts = scopeAttempts
                self.totalAttempts = totalAttempts
            }
        }

        public struct Permit:
            Sendable,
            Hashable
        {
            public let usage: Usage

            fileprivate init(
                usage: Usage
            ) {
                self.usage = usage
            }
        }

        public let perIncident: UInt?
        public let perScope: UInt?
        public let total: UInt?

        public init(
            perIncident: UInt? = nil,
            perScope: UInt? = nil,
            total: UInt? = nil
        ) {
            self.perIncident = perIncident
            self.perScope = perScope
            self.total = total
        }

        public func nextAttempt(
            after usage: Usage
        ) -> Permit? {
            guard usage.incidentAttempts < UInt.max,
                  usage.scopeAttempts < UInt.max,
                  usage.totalAttempts < UInt.max
            else {
                return nil
            }

            let next = Usage(
                incidentAttempts: usage.incidentAttempts + 1,
                scopeAttempts: usage.scopeAttempts + 1,
                totalAttempts: usage.totalAttempts + 1
            )

            if let perIncident,
               next.incidentAttempts > perIncident
            {
                return nil
            }

            if let perScope,
               next.scopeAttempts > perScope
            {
                return nil
            }

            if let total,
               next.totalAttempts > total
            {
                return nil
            }

            return Permit(
                usage: next
            )
        }

        public static let unlimited = Self()
    }
}

import Errors

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
        /// An error identity (`mail.imap.command_failed`) or a namespace
        /// (`mail.imap`) anywhere in the incident's report.
        public let code: String?
        /// The report's effective disposition.
        public let disposition: ErrorDisposition?

        public init(
            kind: Kind? = nil,
            stage: Stage? = nil,
            scope: Scope.Kind? = nil,
            effectState: EffectState? = nil,
            retrySafety: RetrySafety? = nil,
            code: String? = nil,
            disposition: ErrorDisposition? = nil
        ) {
            self.kind = kind
            self.stage = stage
            self.scope = scope
            self.effectState = effectState
            self.retrySafety = retrySafety
            self.code = code
            self.disposition = disposition
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

            if let code {
                guard let report = incident.report,
                      report.first(where: {
                          guard let identity = $0.diagnostic.identity else {
                              return false
                          }
                          return identity.raw == code
                              || identity.isWithin(code)
                      }) != nil
                else {
                    return false
                }
            }

            if let disposition,
               disposition != incident.report?.effectiveDisposition
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

            if code != nil {
                value += 1
            }

            if disposition != nil {
                value += 1
            }

            return value
        }
    }
}

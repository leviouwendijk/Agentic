import Errors

public extension Recovery {
    struct Incident:
        Sendable,
        Codable,
        Hashable
    {
        public let kind: Kind
        public let stage: Stage
        // rewrite symbol camelcase
        public let effectState: EffectState
        // rewrite symbol camelcase
        public let retrySafety: RetrySafety
        public let scope: Scope
        public let message: String
        public let report: ErrorReport?
        public let metadata: [String: String]

        public var state: State {
            State(
                effect: effectState,
                retry: retrySafety
            )
        }

        public init(
            kind: Kind,
            stage: Stage,
            effectState: EffectState,
            retrySafety: RetrySafety,
            scope: Scope,
            message: String,
            report: ErrorReport? = nil,
            metadata: [String: String] = [:]
        ) {
            self.kind = kind
            self.stage = stage
            self.effectState = effectState
            self.retrySafety = retrySafety
            self.scope = scope
            self.message = message
            self.report = report
            self.metadata = metadata
        }

        public init(
            capturing error: any Error,
            kind: Kind,
            stage: Stage,
            effectState: EffectState,
            retrySafety: RetrySafety,
            scope: Scope,
            message: String? = nil,
            metadata: [String: String] = [:]
        ) {
            let report = error.report

            self.init(
                kind: kind,
                stage: stage,
                effectState: effectState,
                retrySafety: retrySafety,
                scope: scope,
                message: message
                    ?? report.presentation.message,
                report: report,
                metadata: metadata
            )
        }
    }
}

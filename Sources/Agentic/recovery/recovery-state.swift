public extension Recovery {
    struct State:
        Sendable,
        Codable,
        Hashable
    {
        public let effect: EffectState
        public let retry: RetrySafety

        public init(
            effect: EffectState,
            retry: RetrySafety
        ) {
            self.effect = effect
            self.retry = retry
        }

        public init(
            reconciled effect: EffectState
        ) {
            self.effect = effect
            self.retry = switch effect {
            case .none,
                 .not_applied:
                .safe

            case .applied:
                .unsafe

            case .unknown:
                .requires_reconciliation
            }
        }
    }
}

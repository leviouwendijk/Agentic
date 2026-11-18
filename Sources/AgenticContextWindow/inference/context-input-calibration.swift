import Agentic

public extension Context {
    /// The provider's count for a request we estimated: anchors the next
    /// estimate to it. The lexical estimate drifts with content (source in
    /// tool results counts high), while the provider's count is exact, so
    /// the next request is measured as that count plus the estimate of what
    /// changed since, and only the change carries the estimator's error.
    struct InputCalibration: Sendable, Codable, Hashable {
        /// Our estimate of the request the provider counted.
        public let estimatedTokens: Int
        /// The input the provider reported for it, cached or not.
        public let reportedTokens: Int

        public init?(
            estimatedTokens: Int,
            reportedTokens: Int
        ) {
            guard estimatedTokens > 0, reportedTokens > 0 else { return nil }
            self.estimatedTokens = estimatedTokens
            self.reportedTokens = reportedTokens
        }

        /// The input a request estimated at `estimate` will measure. Growth
        /// keeps the estimator's (high) rate; a request smaller than the
        /// anchor (after compaction) is scaled by the measured ratio.
        public func measure(
            _ estimate: Int
        ) -> Int {
            guard estimate < estimatedTokens else {
                return reportedTokens + (estimate - estimatedTokens)
            }
            let ratio = Double(reportedTokens) / Double(estimatedTokens)
            return Int((Double(estimate) * ratio).rounded(.up))
        }
    }

    /// The latest calibration per model, for one conversation: a host keeps
    /// one beside its compaction ledger and hands it to every run, so the
    /// first request of a run is anchored too. Tokenizers differ, so a
    /// calibration only measures requests to the model that reported it.
    actor InputMeter {
        private var latest: [String: InputCalibration] = [:]

        public init() {}

        public func calibration(
            for model: String
        ) -> InputCalibration? {
            latest[model]
        }

        public func record(
            _ calibration: InputCalibration,
            for model: String
        ) {
            latest[model] = calibration
        }
    }
}

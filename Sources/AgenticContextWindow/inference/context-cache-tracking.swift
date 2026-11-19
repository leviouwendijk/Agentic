import Agentic
import Foundation

public extension ContextWindow {
    /// A request that read much less from the provider's prompt cache than
    /// the request before it left there, and why.
    struct CacheMiss: Sendable, Codable, Hashable {
        public enum Cause: String, Sendable, Codable, Hashable {
            /// The prefix differs from the previous request's: the tools,
            /// the generation settings or an earlier message changed.
            case content_changed
            /// The prefix is unchanged, but the previous request started
            /// longer ago than the cache lives.
            case expired
            /// Unchanged and within the lifetime: the provider dropped the
            /// entry, or never wrote it.
            case unexplained
        }

        /// Where the request first differs from the previous one. Providers
        /// render tools, then settings-dependent state, then messages, so
        /// everything after this point was written again.
        public enum Divergence: Sendable, Codable, Hashable {
            case tools
            case settings
            /// The message at `index` changed, or was left out.
            case message(index: Int, id: String)
        }

        public let cause: Cause
        public let divergence: Divergence?
        public let model: String
        /// What the previous request sent, all of which it left cached.
        public let expectedTokens: Int
        public let readTokens: Int
        public let writtenTokens: Int
        /// From the previous request's start to this one's.
        public let idle: TimeInterval
        public let lifetime: TimeInterval

        public init(
            cause: Cause,
            divergence: Divergence?,
            model: String,
            expectedTokens: Int,
            readTokens: Int,
            writtenTokens: Int,
            idle: TimeInterval,
            lifetime: TimeInterval
        ) {
            self.cause = cause
            self.divergence = divergence
            self.model = model
            self.expectedTokens = expectedTokens
            self.readTokens = readTokens
            self.writtenTokens = writtenTokens
            self.idle = idle
            self.lifetime = lifetime
        }

        /// One line, e.g. `read ≈2k of ≈48k cached · 7m12s since the
        /// previous request, past the 5m cache lifetime`.
        public var summary: String {
            let read = "read ≈\(Self.compact(readTokens)) of ≈\(Self.compact(expectedTokens)) cached"
            let written = writtenTokens > 0 ? ", ≈\(Self.compact(writtenTokens)) written again" : ""
            let why: String
            switch cause {
            case .content_changed:
                why = "the prefix changed at " + (divergence.map(Self.describe) ?? "an unknown point")
            case .expired:
                why = "\(Self.duration(idle)) since the previous request, past the \(Self.duration(lifetime)) cache lifetime"
            case .unexplained:
                why = "unchanged prefix \(Self.duration(idle)) after the previous request: the provider did not serve its entry"
            }
            return read + written + " · " + why
        }

        private static func describe(
            _ divergence: Divergence
        ) -> String {
            switch divergence {
            case .tools: "the tools"
            case .settings: "the generation settings"
            case .message(let index, let id): "message \(index) (\(id))"
            }
        }

        private static func compact(
            _ tokens: Int
        ) -> String {
            tokens >= 1_000
                ? String(format: "%.1fk", Double(tokens) / 1_000)
                : String(tokens)
        }

        private static func duration(
            _ seconds: TimeInterval
        ) -> String {
            let total = Int(seconds.rounded())
            let (minutes, rest) = (total / 60, total % 60)
            if minutes == 0 { return "\(rest)s" }
            return rest == 0 ? "\(minutes)m" : "\(minutes)m\(rest)s"
        }
    }

    /// Compares each request with the previous one sent to the same model
    /// (caches are model-scoped) and names a miss: changed content, expiry,
    /// or neither. A host keeps one per conversation, so the comparison
    /// spans runs; fingerprints are per process and never persisted.
    actor CacheMeter {
        struct Sent {
            let tools: Int
            let settings: Int
            let messages: [(id: String, hash: Int)]
            let startedAt: Date
            let contextTokens: Int
        }

        /// The provider's cache lifetime, measured start to start; a read
        /// refreshes it. Anthropic's default entry lives five minutes.
        public let lifetime: TimeInterval
        /// Shortfalls below this many tokens are noise, not misses.
        public let tolerance: Int
        private var previous: [String: Sent] = [:]

        public init(
            lifetime: TimeInterval = 300,
            tolerance: Int = 1_024
        ) {
            self.lifetime = lifetime
            self.tolerance = tolerance
        }

        /// Records the request and returns the miss it made, if any. Nil
        /// for the first request to a model and for providers that report
        /// no cache reads.
        public func observe(
            request: AgentRequest,
            model: String,
            usage: AgentUsage?,
            startedAt: Date
        ) -> CacheMiss? {
            var settings = Hasher()
            settings.combine(request.generationConfiguration)
            settings.combine(request.responseFormat)
            let sent = Sent(
                tools: request.tools.hashValue,
                settings: settings.finalize(),
                messages: request.messages.map { ($0.id, $0.modelFacing.hashValue) },
                startedAt: startedAt,
                contextTokens: usage?.contextTokens ?? 0
            )
            let before = previous[model]
            previous[model] = sent

            guard let before,
                  let read = usage?.cachedInputReadTokens,
                  before.contextTokens - read >= tolerance,
                  Double(read) < Double(before.contextTokens) * 0.9
            else {
                return nil
            }

            let divergence = Self.divergence(from: before, to: sent)
            let idle = startedAt.timeIntervalSince(before.startedAt)
            let cause: CacheMiss.Cause = divergence != nil
                ? .content_changed
                : idle > lifetime ? .expired : .unexplained
            return .init(
                cause: cause,
                divergence: divergence,
                model: model,
                expectedTokens: before.contextTokens,
                readTokens: read,
                writtenTokens: usage?.cachedInputWriteTokens ?? 0,
                idle: idle,
                lifetime: lifetime
            )
        }

        static func divergence(
            from before: Sent,
            to after: Sent
        ) -> CacheMiss.Divergence? {
            if before.tools != after.tools { return .tools }
            if before.settings != after.settings { return .settings }
            for (index, earlier) in before.messages.enumerated() {
                guard index < after.messages.count,
                      after.messages[index].hash == earlier.hash
                else {
                    return .message(index: index, id: earlier.id)
                }
            }
            return nil
        }
    }
}

import Agentic
import Foundation
import Tokens

public extension Context {
    /// An explicit, durable reduction of what later requests carry: an
    /// ordered list of pointers to tool results that stay fully preserved
    /// in the session and readable with the session tools. It replaces
    /// content with a pointer, never with a summary standing in for it.
    ///
    /// Applied deterministically to every later request, so a compaction
    /// costs one prefix-cache miss and the prefix is stable again after it.
    struct Compaction: Sendable, Codable, Hashable, Identifiable {
        public enum Origin: String, Sendable, Codable, Hashable {
            /// `:compact`, or another explicit operator action.
            case operator_command
            /// An opt-in automatic policy, at a turn boundary.
            case automatic
        }

        public struct Pointer: Sendable, Codable, Hashable {
            /// The tool message holding the result.
            public let messageID: String
            public let call: FunctionCall.Reference
            /// Estimated tokens the result occupied in the request.
            public let estimatedTokens: Int
            public let preview: String

            public init(
                messageID: String,
                call: FunctionCall.Reference,
                estimatedTokens: Int,
                preview: String
            ) {
                self.messageID = messageID
                self.call = call
                self.estimatedTokens = estimatedTokens
                self.preview = preview
            }

            /// What the model reads in place of the result: where it is
            /// and how to read it back.
            public var text: String {
                "[Compacted: the result of \(call.name) call \(call.id) (≈\(estimatedTokens) tokens) is preserved. "
                    + "Read it with read_session_history(fromMessageID: \"\(messageID)\", "
                    + "throughMessageID: \"\(messageID)\"). Preview: \(preview)]"
            }
        }

        public let id: String
        public let origin: Origin
        public let createdAt: Date
        public let pointers: [Pointer]

        public init(
            id: String = UUID().uuidString,
            origin: Origin,
            createdAt: Date = Date(),
            pointers: [Pointer]
        ) {
            self.id = id
            self.origin = origin
            self.createdAt = createdAt
            self.pointers = pointers
        }

        /// Roughly what later requests no longer carry.
        public var estimatedTokensSaved: Int {
            pointers.reduce(0) { $0 + $1.estimatedTokens }
        }
    }

    enum Compactor {
        /// Pointers for every tool result above `threshold` tokens outside
        /// the current and previous turns, not already compacted. Nil when
        /// there is nothing to compact. The two newest turns stay whole:
        /// the current work and the answer it most likely refers to.
        public static func plan(
            messages: [Message],
            excluding compacted: [Compaction] = [],
            keepingRecentTurns: Int = 2,
            threshold: Int = 256,
            origin: Compaction.Origin = .operator_command,
            options: TokenEstimationOptions = .agenticContext
        ) -> Compaction? {
            let conversation = messages.filter { $0.role != .system }
            let userStarts = conversation.indices.filter { conversation[$0].role == .user }
            let kept = max(1, keepingRecentTurns)
            guard userStarts.count > kept else { return nil }
            let boundary = userStarts[userStarts.count - kept]
            let already = Set(compacted.flatMap(\.pointers).map(\.call.id))

            var pointers: [Compaction.Pointer] = []
            for message in conversation[..<boundary] where message.role == .tool {
                for case .result(let response) in message.content.blocks
                where !already.contains(response.call.id) {
                    let text = response.modelText
                    let tokens = TokenEstimator.estimate(
                        text, options: options, source: "context.compaction"
                    ).estimatedTokens
                    guard tokens > threshold else { continue }
                    let line = text.split(whereSeparator: \.isNewline).joined(separator: " ")
                    pointers.append(.init(
                        messageID: message.id,
                        call: response.call,
                        estimatedTokens: tokens,
                        preview: line.count > 120 ? String(line.prefix(120)) + "…" : line
                    ))
                }
            }
            return pointers.isEmpty ? nil : .init(origin: origin, pointers: pointers)
        }
    }

    /// How close a prepared request is to its input limit.
    struct Pressure: Sendable, Codable, Hashable {
        public enum Level: String, Sendable, Codable, Hashable {
            case normal
            /// Past the soft limit: advise compaction, do nothing.
            case soft
        }

        public let level: Level
        public let estimatedInputTokens: Int
        public let softLimit: Int
        /// The request's input limit; past it, preparation refuses.
        public let hardLimit: Int

        public init(
            estimatedInputTokens: Int,
            softLimit: Int,
            hardLimit: Int
        ) {
            self.estimatedInputTokens = estimatedInputTokens
            self.softLimit = softLimit
            self.hardLimit = hardLimit
            self.level = estimatedInputTokens > softLimit ? .soft : .normal
        }
    }
}

public extension Context {
    /// One session's compactions, in the order they were made. A host
    /// keeps one per conversation and hands it to every run, so each
    /// request applies the same pointers.
    actor CompactionLedger {
        public private(set) var compactions: [Compaction]

        public init(
            _ compactions: [Compaction] = []
        ) {
            self.compactions = compactions
        }

        public func record(
            _ compaction: Compaction
        ) {
            compactions.append(compaction)
        }
    }
}

import Agentic
import Foundation
import Primitives
import Tokens

public enum ContextInferenceError: Error, Equatable {
    case noCurrentUserMessage
    case foreignSystemMessage(String)
    case foreignUserMessage(String)
    case foreignToolMessage(String)
    case conflictingMessageID(String)
    case unpairedToolResult(String)
    case duplicateToolCall(String)
    case inputBudgetExceeded(estimated: Int, maximum: Int)
    case invalidInputBudget(Int)
    case requiredHistoryExceedsTailBudget(estimated: Int, maximum: Int)
}

public extension Context {
    /// Preparation changes one inference request, never the durable session state.
    enum InferenceDelivery: String, Sendable, Codable, Hashable {
        /// Keep the current dialogue and supplement it with selected evidence.
        case supplement
        /// Preserve system messages and the dialogue from the most recent user
        /// turn, but replace older active history with the selected evidence.
        case working_set
        /// Deterministic complete-turn tail controlled by the allocator.
        case dynamic
    }

    struct HistorySelection: Sendable, Codable, Hashable {
        /// Checkpoint message indices are stable while the source history is
        /// append-only. These are references, not retained text copies.
        public struct Reference: Sendable, Codable, Hashable {
            public let index: Int
            public let messageID: String
        }
        public let retained: [Reference]
        public let omitted: [Reference]
        /// Retained, but with bulky results replaced by a pointer stub.
        public let elided: [Reference]
    }

    struct InferenceMeasurement: Sendable, Codable, Hashable {
        public let selectedAllocations: Int
        public let skippedAllocations: Int
        public let distinctSources: Int
        public let messageCount: Int
        public let toolDefinitionCount: Int
        public let toolCallCount: Int
        public let toolResultCount: Int
        public let serializedRequestBytes: Int
        public let estimatedInputTokens: Int
        public let maximumInputTokens: Int

        public init(
            selectedAllocations: Int,
            skippedAllocations: Int,
            distinctSources: Int,
            messageCount: Int,
            toolDefinitionCount: Int,
            toolCallCount: Int,
            toolResultCount: Int,
            serializedRequestBytes: Int,
            estimatedInputTokens: Int,
            maximumInputTokens: Int
        ) {
            self.selectedAllocations = selectedAllocations
            self.skippedAllocations = skippedAllocations
            self.distinctSources = distinctSources
            self.messageCount = messageCount
            self.toolDefinitionCount = toolDefinitionCount
            self.toolCallCount = toolCallCount
            self.toolResultCount = toolResultCount
            self.serializedRequestBytes = serializedRequestBytes
            self.estimatedInputTokens = estimatedInputTokens
            self.maximumInputTokens = maximumInputTokens
        }
    }

    struct InferencePreparation: Sendable, Codable, Hashable {
        public let request: AgentRequest
        public let frame: Frame
        public let delivery: InferenceDelivery
        public let measurement: InferenceMeasurement
        public let history: HistorySelection

        public init(
            request: AgentRequest,
            frame: Frame,
            delivery: InferenceDelivery,
            measurement: InferenceMeasurement,
            history: HistorySelection
        ) {
            self.request = request
            self.frame = frame
            self.delivery = delivery
            self.measurement = measurement
            self.history = history
        }
    }

    enum InferencePreparer {
        /// Measures the full semantic AgentRequest, including structured tool
        /// definitions and non-text message blocks. This is a lexical estimate
        /// over the JSON representation, NOT a provider-exact token count or
        /// a claim about the adapter's final wire encoding.
        public static func prepare(
            request: AgentRequest,
            frame: Frame,
            delivery: InferenceDelivery,
            maximumInputTokens: Int,
            estimationOptions: TokenEstimationOptions = .agenticContext,
            historyPolicy: HistoryPolicy = .init()
        ) throws -> InferencePreparation {
            guard maximumInputTokens > 0 else {
                throw ContextInferenceError.invalidInputBudget(maximumInputTokens)
            }

            let uniqueOriginal = try uniqueMessages(request.messages)
            let originalSystem = uniqueOriginal.filter { $0.role == .system }
            let systemByID = Dictionary(uniqueKeysWithValues: originalSystem.map { ($0.id, $0) })
            let frameMessages = frame.messages

            let originalByID = Dictionary(uniqueKeysWithValues: uniqueOriginal.map { ($0.id, $0) })
            for message in frameMessages {
                switch message.role {
                case .system:
                    guard systemByID[message.id] == message else {
                        throw ContextInferenceError.foreignSystemMessage(message.id)
                    }
                case .user:
                    guard originalByID[message.id] == message else {
                        throw ContextInferenceError.foreignUserMessage(message.id)
                    }
                case .tool:
                    guard originalByID[message.id] == message else {
                        throw ContextInferenceError.foreignToolMessage(message.id)
                    }
                case .assistant:
                    break
                }
            }

            let assembled: [Message]
            var elided: Set<String> = []
            switch delivery {
            case .supplement:
                assembled = try uniqueMessages(uniqueOriginal + frameMessages)

            case .working_set:
                guard let latestUser = uniqueOriginal.lastIndex(where: { $0.role == .user }) else {
                    throw ContextInferenceError.noCurrentUserMessage
                }
                let tail = Array(uniqueOriginal[latestUser...])
                assembled = try uniqueMessages(originalSystem + frameMessages + tail)

            case .dynamic:
                let selection = try selectHistory(
                    from: uniqueOriginal.filter { $0.role != .system },
                    policy: historyPolicy,
                    options: estimationOptions
                )
                elided = selection.elided
                assembled = try uniqueMessages(originalSystem + frameMessages + selection.messages)
            }

            let counts = try validateToolRelationships(assembled)
            var prepared = request
            prepared.messages = assembled

            let encoded = try JSONEncoder().encode(prepared)
            let estimate = TokenEstimator.estimate(
                String(decoding: encoded, as: UTF8.self),
                options: estimationOptions,
                source: "context.inference_request_json"
            )
            guard estimate.estimatedTokens <= maximumInputTokens else {
                throw ContextInferenceError.inputBudgetExceeded(
                    estimated: estimate.estimatedTokens,
                    maximum: maximumInputTokens
                )
            }

            let measurement = InferenceMeasurement(
                selectedAllocations: frame.items.count,
                skippedAllocations: frame.skippedAllocationIDs.count,
                distinctSources: Set(frame.items.map(\.observed.source)).count,
                messageCount: assembled.count,
                toolDefinitionCount: prepared.tools.count,
                toolCallCount: counts.calls,
                toolResultCount: counts.results,
                serializedRequestBytes: encoded.count,
                estimatedInputTokens: estimate.estimatedTokens,
                maximumInputTokens: maximumInputTokens
            )
            let included = Set(assembled.map(\.id))
            let history = HistorySelection(
                retained: uniqueOriginal.enumerated().compactMap { index, message in
                    included.contains(message.id)
                        ? .init(index: index, messageID: message.id) : nil
                },
                omitted: uniqueOriginal.enumerated().compactMap { index, message in
                    included.contains(message.id)
                        ? nil : .init(index: index, messageID: message.id)
                },
                elided: uniqueOriginal.enumerated().compactMap { index, message in
                    elided.contains(message.id)
                        ? .init(index: index, messageID: message.id) : nil
                }
            )
            return InferencePreparation(
                request: prepared,
                frame: frame,
                delivery: delivery,
                measurement: measurement,
                history: history
            )
        }

        /// Fit the conversation into the history budget, losing as little as
        /// possible. Each step runs only while the budget is still exceeded,
        /// except the first:
        ///
        /// 1. Turns older than `maximumTurns` lose bulky results to a stub
        ///    that names the call (the log keeps the full result).
        /// 2. Results the model has already seen are elided, oldest first.
        /// 3. The oldest whole turns are dropped (never the current one).
        /// 4. Seen exchanges of the current turn are dropped, oldest first.
        /// 5. Results the model has not seen yet are elided.
        ///
        /// Calls are never separated from their results, user messages are
        /// never edited, and the current instruction is never dropped.
        private static func selectHistory(
            from conversation: [Message],
            policy: HistoryPolicy,
            options: TokenEstimationOptions
        ) throws -> (messages: [Message], elided: Set<String>) {
            guard policy.maximumTurns > 0, policy.maximumTokens > 0 else {
                throw ContextInferenceError.invalidInputBudget(policy.maximumTokens)
            }
            let userStarts = conversation.indices.filter { conversation[$0].role == .user }
            guard !userStarts.isEmpty else {
                throw ContextInferenceError.noCurrentUserMessage
            }

            var bounds = userStarts
            if bounds[0] != 0 {
                bounds.insert(0, at: 0)
            }
            var turns = zip(bounds, bounds.dropFirst() + [conversation.count])
                .map { Array(conversation[$0..<$1]) }

            // Results after the last assistant message have not reached the
            // model yet; they are elided only as a last resort.
            let lastAssistant = conversation.lastIndex { $0.role == .assistant } ?? -1
            let unseen = Set(conversation.indices
                .filter { $0 > lastAssistant && conversation[$0].role == .tool }
                .map { conversation[$0].id })

            var tokens = try Dictionary(uniqueKeysWithValues: conversation.map {
                ($0.id, try estimate($0, options: options))
            })
            var elided: Set<String> = []
            func total() -> Int {
                turns.joined().reduce(0) { $0 + (tokens[$1.id] ?? 0) }
            }
            func over() -> Bool {
                total() > policy.maximumTokens
            }
            func elide(turn: Int, includingUnseen: Bool) throws {
                for index in turns[turn].indices where over() || turn < turns.count - policy.maximumTurns {
                    let message = turns[turn][index]
                    guard message.role == .tool,
                          includingUnseen || !unseen.contains(message.id),
                          let stubbed = try stub(message, threshold: policy.elideResultsOver, options: options)
                    else { continue }
                    turns[turn][index] = stubbed
                    tokens[message.id] = try estimate(stubbed, options: options)
                    elided.insert(message.id)
                }
            }

            for turn in turns.indices.dropLast(policy.maximumTurns) {
                try elide(turn: turn, includingUnseen: false)
            }
            // Lossless: a result identical to one still shown in full is
            // sent as a pointer to it. Runs after aging so it never points
            // at a stub.
            var shown: [Data: String] = [:]
            for turn in turns.indices {
                for index in turns[turn].indices {
                    let message = turns[turn][index]
                    guard message.role == .tool,
                          let pointed = try pointer(message, to: &shown, options: options)
                    else { continue }
                    turns[turn][index] = pointed
                    tokens[message.id] = try estimate(pointed, options: options)
                    elided.insert(message.id)
                }
            }
            for turn in turns.indices where over() {
                try elide(turn: turn, includingUnseen: false)
            }
            while over(), turns.count > 1 {
                for message in turns.removeFirst() {
                    elided.remove(message.id)
                }
            }
            while over(), let exchange = firstCompletedExchange(in: turns[0], excluding: unseen) {
                for message in turns[0][exchange] {
                    elided.remove(message.id)
                }
                turns[0].removeSubrange(exchange)
            }
            if over() {
                try elide(turn: 0, includingUnseen: true)
            }
            guard !over() else {
                throw ContextInferenceError.requiredHistoryExceedsTailBudget(
                    estimated: total(), maximum: policy.maximumTokens
                )
            }
            return (Array(turns.joined()), elided)
        }

        /// A tool message whose bulky results are replaced by a stub, or nil
        /// when none of its results exceeds the threshold.
        private static func stub(
            _ message: Message,
            threshold: Int,
            options: TokenEstimationOptions
        ) throws -> Message? {
            var changed = false
            var stubbed = message
            stubbed.content.blocks = try message.content.blocks.map { block in
                guard case .result(let response) = block,
                      !isStub(response) else {
                    return block
                }
                let size = try estimate(response, options: options)
                guard size > threshold else {
                    return block
                }
                changed = true
                return .result(.init(
                    call: response.call,
                    output: .string(
                        "\(stubMarker) (≈\(size) tokens). The full result of call \(response.call.id) "
                            + "is recorded in the session log. Preview: \(preview(response.output))]"
                    ),
                    isError: response.isError
                ))
            }
            return changed ? stubbed : nil
        }

        /// A tool message whose results repeat an earlier full result, with
        /// those results replaced by a pointer; nil when nothing repeats.
        /// Records this message's own full results in `shown`.
        private static func pointer(
            _ message: Message,
            to shown: inout [Data: String],
            options: TokenEstimationOptions
        ) throws -> Message? {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            var changed = false
            var pointed = message
            pointed.content.blocks = try message.content.blocks.map { block in
                guard case .result(let response) = block,
                      !isStub(response) else {
                    return block
                }
                let key = try encoder.encode(
                    FunctionCall.Response(call: .init(id: "", name: ""), output: response.output, isError: response.isError)
                )
                guard let original = shown[key] else {
                    shown[key] = response.call.id
                    return block
                }
                // Pointers only pay off for results larger than themselves.
                guard try estimate(response.output, options: options) > minimumPointedTokens else {
                    return block
                }
                changed = true
                return .result(.init(
                    call: response.call,
                    output: .string("\(pointerMarker) the result of call \(original) above.]"),
                    isError: response.isError
                ))
            }
            return changed ? pointed : nil
        }

        private static let pointerMarker = "[Unchanged: identical to"
        private static let minimumPointedTokens = 32

        private static let stubMarker = "[Output elided from context"

        private static func isStub(_ response: FunctionCall.Response) -> Bool {
            if case .string(let text) = response.output {
                return text.hasPrefix(stubMarker) || text.hasPrefix(pointerMarker)
            }
            return false
        }

        private static func preview(_ output: JSONValue) -> String {
            let text: String
            if case .string(let value) = output {
                text = value
            } else {
                text = (try? JSONEncoder().encode(output))
                    .map { String(decoding: $0, as: UTF8.self) } ?? ""
            }
            let line = text.split(whereSeparator: \.isNewline).joined(separator: " ")
            return line.count > 160 ? String(line.prefix(160)) + "…" : line
        }

        private static func estimate(
            _ value: some Encodable,
            options: TokenEstimationOptions
        ) throws -> Int {
            TokenEstimator.estimate(
                String(decoding: try JSONEncoder().encode(value), as: UTF8.self),
                options: options,
                source: "context.history_json"
            ).estimatedTokens
        }

        /// An assistant call message and the tool messages answering all of
        /// its calls, none of which the model has yet to see.
        private static func firstCompletedExchange(
            in messages: [Message],
            excluding unseen: Set<String>
        ) -> Range<Int>? {
            for start in messages.indices {
                let assistant = messages[start]
                guard assistant.role == .assistant else { continue }
                let calls = Set(assistant.content.blocks.compactMap { block -> String? in
                    if case .call(let call) = block { return call.id }
                    return nil
                })
                guard !calls.isEmpty else { continue }
                var next = start + 1
                var answered: Set<String> = []
                while next < messages.count, messages[next].role == .tool,
                      !unseen.contains(messages[next].id) {
                    let results = Set(messages[next].content.blocks.compactMap { block -> String? in
                        if case .result(let result) = block { return result.call.id }
                        return nil
                    })
                    guard !results.isEmpty, results.isSubset(of: calls) else { break }
                    answered.formUnion(results)
                    next += 1
                }
                if answered == calls { return start..<next }
            }
            return nil
        }

        private static func uniqueMessages(_ messages: [Message]) throws -> [Message] {
            var byID: [String: Message] = [:]
            var result: [Message] = []
            for message in messages {
                if let existing = byID[message.id] {
                    guard existing == message else {
                        throw ContextInferenceError.conflictingMessageID(message.id)
                    }
                    continue
                }
                byID[message.id] = message
                result.append(message)
            }
            return result
        }

        private static func validateToolRelationships(
            _ messages: [Message]
        ) throws -> (calls: Int, results: Int) {
            var calls: Set<String> = []
            var results = 0
            for message in messages {
                for block in message.content.blocks {
                    switch block {
                    case .call(let call):
                        guard calls.insert(call.id).inserted else {
                            throw ContextInferenceError.duplicateToolCall(call.id)
                        }
                    case .result(let result):
                        guard calls.contains(result.call.id) else {
                            throw ContextInferenceError.unpairedToolResult(result.call.id)
                        }
                        results += 1
                    case .text, .resource:
                        break
                    }
                }
            }
            return (calls.count, results)
        }
    }
}

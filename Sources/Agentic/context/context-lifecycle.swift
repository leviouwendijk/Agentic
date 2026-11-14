public extension Context {
    struct Allocation: Sendable, Codable, Hashable {
        public enum Representation: String, Sendable, Codable, Hashable {
            case original
            case excerpt
            case facts
            case summary
            case reference
        }

        public enum State: String, Sendable, Codable, Hashable {
            case active
            case released
            case invalidated
        }

        public let id: String
        public let pointer: Pointer
        public let representation: Representation
        public let priority: Int
        public let required: Bool
        public let dependencies: [Pointer]
        public var state: State

        public init(
            id: String,
            pointer: Pointer,
            representation: Representation = .original,
            priority: Int = 0,
            required: Bool = false,
            dependencies: [Pointer] = [],
            state: State = .active
        ) {
            self.id = id
            self.pointer = pointer
            self.representation = representation
            self.priority = priority
            self.required = required
            self.dependencies = dependencies
            self.state = state
        }
    }

    struct WorkingSet: Sendable, Codable, Hashable {
        public let id: String
        public let parentID: String?
        public var allocations: [Allocation]
        public var preferredInputTokens: Int?

        public init(
            id: String,
            parentID: String? = nil,
            allocations: [Allocation] = [],
            preferredInputTokens: Int? = nil
        ) {
            self.id = id
            self.parentID = parentID
            self.allocations = allocations
            self.preferredInputTokens = preferredInputTokens
        }
    }

    enum Operation: Sendable, Codable, Hashable {
        case allocate(Allocation)
        case release(String)
        case invalidate(String)
        case setPreferredInputTokens(Int)
    }

    struct Transition: Sendable, Codable, Hashable {
        public let sequence: Int
        public let workingSetID: String
        public let operation: Operation

        public init(sequence: Int, workingSetID: String, operation: Operation) {
            self.sequence = sequence
            self.workingSetID = workingSetID
            self.operation = operation
        }
    }

    /// How dynamic mode fits the conversation into its budget. The current
    /// user turn is mandatory; it is never silently truncated.
    struct HistoryPolicy: Sendable, Codable, Hashable {
        /// Recent user turns kept at full fidelity. Older turns stay while
        /// they fit, with bulky results elided to a stub.
        public let maximumTurns: Int
        /// Budget for the whole conversation, excluding system messages.
        public let maximumTokens: Int
        /// Results above this estimate are elided when they leave the
        /// full-fidelity window or when the budget is exceeded.
        public let elideResultsOver: Int
        /// Aged turns are elided in batches of this many. Every elision
        /// rewrites the prompt after it, invalidating a provider's prefix
        /// cache from that point; batching pays that once per batch. Budget
        /// pressure still elides immediately.
        public let elisionBatch: Int

        public init(
            maximumTurns: Int = 4,
            maximumTokens: Int = 4_000,
            elideResultsOver: Int = 256,
            elisionBatch: Int = 1
        ) {
            self.maximumTurns = maximumTurns
            self.maximumTokens = maximumTokens
            self.elideResultsOver = elideResultsOver
            self.elisionBatch = max(1, elisionBatch)
        }
    }

    enum Mode: String, Sendable, Codable, Hashable {
        case accumulating
        case dynamic
    }

    struct Policy: Sendable, Codable, Hashable {
        public let preferredInputTokens: Int
        public let maximumInputTokens: Int
        public let reservedOutputTokens: Int
        public let maximumResolutions: Int
        public let history: HistoryPolicy
        /// How much of each capability schema is advertised.
        public let schemas: SchemaDetail

        public init(
            preferredInputTokens: Int = 12_000,
            maximumInputTokens: Int = 48_000,
            reservedOutputTokens: Int = 4_000,
            maximumResolutions: Int = 32,
            history: HistoryPolicy = .init(),
            schemas: SchemaDetail = .full
        ) {
            self.preferredInputTokens = preferredInputTokens
            self.maximumInputTokens = maximumInputTokens
            self.reservedOutputTokens = reservedOutputTokens
            self.maximumResolutions = maximumResolutions
            self.history = history
            self.schemas = schemas
        }
    }

    enum SchemaDetail: String, Sendable, Codable, Hashable {
        /// Every schema in full.
        case full
        /// Required properties in full, optional ones abbreviated
        /// (`ToolDescriptor.core`); full detail through `inspect_capability`.
        case core
    }

    /// An immutable, provider-neutral account of what was actually selected
    /// for one inference. Message boundaries are retained, not flattened.
    struct Frame: Sendable, Codable, Hashable {
        public struct Item: Sendable, Codable, Hashable {
            public let allocationID: String
            public let observed: Pointer
            public let messages: [Message]
            public let estimatedTokens: Int

            public init(
                allocationID: String,
                observed: Pointer,
                messages: [Message],
                estimatedTokens: Int
            ) {
                self.allocationID = allocationID
                self.observed = observed
                self.messages = messages
                self.estimatedTokens = estimatedTokens
            }
        }

        public let workingSetID: String
        public let items: [Item]
        public let skippedAllocationIDs: [String]
        public let inputBudget: Int
        public let estimatedInputTokens: Int

        public init(
            workingSetID: String,
            items: [Item],
            skippedAllocationIDs: [String],
            inputBudget: Int,
            estimatedInputTokens: Int
        ) {
            self.workingSetID = workingSetID
            self.items = items
            self.skippedAllocationIDs = skippedAllocationIDs
            self.inputBudget = inputBudget
            self.estimatedInputTokens = estimatedInputTokens
        }

        public var messages: [Message] {
            items.flatMap(\.messages)
        }
    }
}

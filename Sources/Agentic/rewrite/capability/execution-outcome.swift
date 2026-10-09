/// Shared lifecycle classification. An executor retains its own typed
/// checkpoint, suspension reason, events, effects, and diagnostics.
/// The Suspension parameter is the executor's concrete resumable state,
/// not a copy of Runtime's Run.Suspension or ProgramCheckpoint types.
public enum Execution {
    public struct Failure: Error, Sendable, Equatable {
        public let kind: String
        public let message: String

        public init(kind: String, message: String) {
            self.kind = kind
            self.message = message
        }
    }

    public enum Outcome<Output: Sendable, Suspension: Sendable>: Sendable {
        case completed(Output)
        case suspended(Suspension)
        case interrupted(Suspension?)
        case failed(Failure)
    }
}

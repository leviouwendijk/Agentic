import Errors

public extension Recovery {
    struct Attempt:
        Sendable,
        Codable,
        Hashable
    {
        public enum Status:
            String,
            Sendable,
            Codable,
            Hashable
        {
            case succeeded
            case failed
        }

        /// One-based attempt number within the selected recovery step.
        public let number: UInt
        public let action: Action
        public let status: Status
        public let state: State?
        public let message: String?
        public let report: ErrorReport?

        public init(
            number: UInt,
            action: Action,
            status: Status,
            state: State? = nil,
            message: String? = nil,
            report: ErrorReport? = nil
        ) {
            self.number = number
            self.action = action
            self.status = status
            self.state = state
            self.message = message
            self.report = report
        }

        public init(
            capturing error: any Error,
            number: UInt,
            action: Action,
            state: State? = nil,
            message: String? = nil
        ) {
            let report = error.report

            self.init(
                number: number,
                action: action,
                status: .failed,
                state: state,
                message: message
                    ?? report.presentation.message,
                report: report
            )
        }
    }
}

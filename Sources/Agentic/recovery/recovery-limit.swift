public extension Recovery {
    struct AttemptPermit:
        Sendable,
        Hashable
    {
        public let number: UInt

        fileprivate init(
            number: UInt
        ) {
            self.number = number
        }
    }

    struct Limit:
        Sendable,
        Codable,
        Hashable
    {
        public let maximumAttempts: UInt

        public init(
            maximumAttempts: UInt
        ) {
            self.maximumAttempts = maximumAttempts
        }

        public func nextAttempt(
            after completedAttempts: UInt
        ) -> AttemptPermit? {
            guard completedAttempts < maximumAttempts else {
                return nil
            }

            return AttemptPermit(
                number: completedAttempts + 1
            )
        }

        public static let once = Self(
            maximumAttempts: 1
        )
    }
}

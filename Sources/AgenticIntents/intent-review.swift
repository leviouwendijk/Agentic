import Agentic
import Foundation
import Macros
import Schema

public extension Intents {
    /// A person's decision on an intent.
    @JSONSchema
    struct Review: Sendable, Codable, Hashable {
        public let decision: Decision
        public let reviewer: String?
        public let note: String?
        public let at: Date

        public init(
            decision: Decision,
            reviewer: String? = nil,
            note: String? = nil,
            at: Date = Date()
        ) {
            self.decision = decision
            self.reviewer = reviewer
            self.note = note
            self.at = at
        }
    }
}

public extension Intents.Review {
    @JSONSchema
    enum Decision: String, Sendable, Codable, Hashable, CaseIterable {
        case approve
        case deny
        case cancel
        case expire
    }
}

public extension Intents.Review.Decision {
    var status: Intents.Intent.Status {
        switch self {
        case .approve:
            return .approved

        case .deny:
            return .denied

        case .cancel:
            return .cancelled

        case .expire:
            return .expired
        }
    }
}

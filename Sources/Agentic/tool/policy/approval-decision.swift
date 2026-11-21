import Macros
import Schema

@JSONSchema
public enum ApprovalDecision: String, Sendable, Codable, Hashable, CaseIterable {
    case approved
    case denied
    case skipped
    /// Wait for a person: the run suspends until one decides.
    case needs_human
    /// Store the call for later review and continue without it. Hosts that
    /// cannot store it treat this as `needs_human`.
    case deferred
}

public extension ApprovalDecision {
    var isApproved: Bool {
        self == .approved
    }

    var isDenied: Bool {
        self == .denied
    }

    var isSkipped: Bool {
        self == .skipped
    }

    var requiresHumanReview: Bool {
        self == .needs_human
    }

    var isDeferred: Bool {
        self == .deferred
    }
}

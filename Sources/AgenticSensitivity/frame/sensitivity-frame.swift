import Foundation
import Frame

/// The `Sensitivity` Frame module: what `import Sensitivity;` makes
/// nameable in `domains/sensitivity.frame`.
///
///     import Sensitivity;
///
///     let vault: Vault = .{
///         .store = .keychain,
///         .expire = .unreferenced,
///     };
///
///     let policy: Policy = .{
///         .never = ["info@example.com"],
///     };
public enum SensitivityFrame {
    public static let module = Frame.Module("Sensitivity", types: [
        .decodable(Vault.self, named: "Vault"),
        .decodable(Policy.self, named: "Policy"),
    ])

    public static let environment = Frame.Environment([module])

    public static let vaultBinding = "vault"
    public static let policyBinding = "policy"

    /// Where handle values are kept.
    public enum Store: String, Sendable, Hashable, Decodable, CaseIterable {
        /// One Keychain item for all sessions, deleted when it empties.
        case keychain
        /// In memory: values end with the process.
        case memory
    }

    /// When a value is forgotten.
    public enum Expire: String, Sendable, Hashable, Decodable, CaseIterable {
        /// Once no recorded session holds its handle any more.
        case unreferenced
        /// When the sessions that saw it close.
        case onSessionClose
        /// `days` after it was first seen.
        case afterDays
    }

    public struct Vault: Sendable, Hashable, Decodable {
        public let store: Store?
        public let expire: Expire?
        /// For `.afterDays`.
        public let days: Int?
    }

    public struct Policy: Sendable, Hashable, Decodable {
        /// Findings scoring this or more become handles; 80 by default.
        public let handleAt: Int?
        /// Findings scoring this or more, below handleAt, become soft
        /// handles any tool may use; 60 by default. Lower ones are flagged.
        public let softAt: Int?
        /// Public values never replaced, such as the business's public
        /// address and phone.
        public let never: [String]?
        /// Groups of tools that share values besides a shared name prefix.
        public let families: [[String]]?
    }
}

extension SensitivityFrame.Vault: FrameDescribable {
    public static var frameSchema: Frame.Schema {
        .object([
            .init("store", .members(of: SensitivityFrame.Store.self, summaries: [
                .keychain: "One Keychain item for all sessions, deleted when it empties. The default.",
                .memory: "In memory: values end with the process, so recorded handles stop resolving.",
            ]), summary: "Where handle values are kept."),
            .init("expire", .members(of: SensitivityFrame.Expire.self, summaries: [
                .unreferenced: "Once no recorded session holds the handle any more. The default.",
                .onSessionClose: "When the sessions that saw the value close.",
                .afterDays: "`days` after the value was first seen.",
            ]), summary: "When a value is forgotten."),
            .init("days", .integer, summary: "For .afterDays."),
        ], summary: "The vault behind handles: where values are kept and how long.")
    }
}

extension SensitivityFrame.Policy: FrameDescribable {
    public static var frameSchema: Frame.Schema {
        .object([
            .init("handleAt", .integer, summary: "Findings scoring this or more become handles. 80 by default."),
            .init("softAt", .integer, summary: "Findings scoring this or more, below handleAt, become soft handles any tool may use. 60 by default."),
            .init("never", .array(.string), summary: "Public values never replaced, such as the business's public address and phone."),
            .init("families", .array(.array(.string)), summary: "Groups of tool names that share values besides a shared name prefix."),
        ], summary: "Which findings become handles, and which tools may use them.")
    }
}

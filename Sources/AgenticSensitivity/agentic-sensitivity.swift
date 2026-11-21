import Agentic
import Foundation
import Primitives
import Sensitivity

/// Sensitive values as handles. With a `Privacy.Guard` installed as the
/// session's `ToolPayloadGuarding`, tool results reach the model and the
/// session record with `⟦kind:id⟧` handles instead of mail addresses,
/// IBANs, keys and the like; tools that may use a handle get its value
/// inside their own call. The values stay in a vault outside the agentic
/// home and expire.
@Domain
public enum Privacy {}

public extension Privacy {
    /// Which tool may resolve which handle.
    ///
    /// - Soft handles (private addresses, identifiers): any tool.
    /// - Values the owner supplied (their messages, their context): any tool.
    /// - Other handles: tools related to one that produced the value (same
    ///   name prefix, as `mail_read` and `mail_send`, or one family), or a
    ///   tool the owner granted it to.
    struct ResolutionPolicy: Sendable {
        /// Tools that share values besides those sharing a name prefix.
        public var families: [Set<String>]

        public init(families: [Set<String>] = Self.standardFamilies) {
            self.families = families
        }

        /// The workspace file tools: what one reads another may write back.
        public static let standardFamilies: [Set<String>] = [
            ["read", "mutate", "search", "create_text", "edit_text"],
        ]

        /// Sources whose values the owner supplied (their messages, their
        /// context): any tool may use them, though the model never sees them.
        public static let ownerSources: Set<String> = ["owner", "context"]

        public func permits(_ handle: Sensitivity.HandleDescription, tool: String) -> Bool {
            if handle.tier == .soft || handle.grants.contains(tool) {
                return true
            }
            if handle.sources.contains(where: { Self.ownerSources.contains(String($0.split(separator: " ").first ?? "")) }) {
                return true
            }
            return handle.sources.contains { source in
                related(String(source.split(separator: " ").first ?? Substring(source)), tool)
            }
        }

        /// Whether `tool` may use what `source` produced: same tool, name prefix or family.
        public func related(_ source: String, _ tool: String) -> Bool {
            source == tool
                || Self.prefix(source) == Self.prefix(tool)
                || families.contains { $0.contains(source) && $0.contains(tool) }
        }

        static func prefix(_ tool: String) -> Substring {
            tool.split(separator: "_").first ?? Substring(tool)
        }
    }

    /// Refused handle use, worded for the model.
    struct GuardFailure: Error, LocalizedError, Sendable, Hashable {
        public let failure: Sensitivity.ShieldFailure

        public var errorDescription: String? {
            failure.description
        }
    }

    /// The `ToolPayloadGuard` over a Sensitivity shield and vault.
    struct Guard: ToolPayloadGuard {
        public let shield: Sensitivity.Shield
        public let policy: ResolutionPolicy

        /// `session` is recorded on every value it sees, for `.onSessionClose`.
        public init(
            vault: Sensitivity.Vault = .init(),
            shieldPolicy: Sensitivity.ShieldPolicy = .standard,
            policy: ResolutionPolicy = .init(),
            session: String? = nil
        ) {
            self.shield = Sensitivity.Shield(vault: vault, policy: shieldPolicy, session: session)
            self.policy = policy
        }

        public var vault: Sensitivity.Vault {
            shield.vault
        }

        public func resolving(_ arguments: JSONValue, for tool: ToolIdentifier) async throws -> JSONValue {
            do {
                return try await shield.resolve(arguments, for: tool.rawValue) { policy.permits($0, tool: tool.rawValue) }
            } catch {
                throw GuardFailure(failure: error)
            }
        }

        public func protecting(_ value: JSONValue, from tool: ToolIdentifier) async -> JSONValue {
            await shield.protect(value, source: tool.rawValue).value
        }

        public func protecting(_ text: String, from tool: ToolIdentifier) async -> String {
            await shield.protect(text, source: tool.rawValue).text
        }
    }

    /// The session's guard, for the privacy tools.
    static func activeGuard(in context: ToolContext) throws -> Guard {
        guard let installed = context.payloadGuard as? Guard else {
            throw GuardUnavailable()
        }
        return installed
    }

    struct GuardUnavailable: Error, LocalizedError, Sendable {
        public var errorDescription: String? {
            "No privacy guard is installed in this session; handles are not in use."
        }
    }
}

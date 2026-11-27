import Agentic
import AgenticConfiguration
import CryptoKit
import Foundation
import IO
import Macros
import Readers
import Schema
import Security
import Sensitivity
import Writers

public extension Privacy {
    /// The key sealed vaults are encrypted with: one Keychain item, made on
    /// first use, on this device only. A teammate needs the same key to
    /// unseal (a team key is open).
    enum SealKey {
        static let service = "agentic.sensitivity.seal"
        static let account = "key"

        static func load() throws -> SymmetricKey {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            if status == errSecSuccess, let data = item as? Data {
                return SymmetricKey(data: data)
            }
            guard status == errSecItemNotFound else { throw SealFailure.keychain(status) }
            let key = SymmetricKey(size: .bits256)
            let add: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: key.withUnsafeBytes { Data($0) },
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            ]
            let added = SecItemAdd(add as CFDictionary, nil)
            guard added == errSecSuccess else { throw SealFailure.keychain(added) }
            return key
        }
    }

    enum SealFailure: Error, LocalizedError {
        case keychain(OSStatus)
        case noSealedVault(String)
        case unreadable(String)

        public var errorDescription: String? {
            switch self {
            case .keychain(let status):
                return "The seal key is not available from the Keychain (\(status))."
            case .noSealedVault(let session):
                return "'\(session)' has no sealed vault; seal it with privacy_tool_seal_session first."
            case .unreadable(let session):
                return "The sealed vault of '\(session)' does not open with this machine's key."
            }
        }
    }

    /// The values a session's handles stand for, encrypted, for the
    /// session to carry: `sessions/<id>/vault.sealed`.
    static func seal(session: String, storage: AgentRuntimeStorageLayout, vault: Sensitivity.Vault) async throws -> Int {
        let ids = References.collect(below: storage.sessiondir(sessionID: session))
        let entries = await vault.export(ids)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let box = try AES.GCM.seal(try encoder.encode(entries), using: try SealKey.load())
        guard let combined = box.combined else { throw SealFailure.unreadable(session) }
        try FileWriter(sealedFile(session, storage)).write(combined.base64EncodedString(), options: .overwriteWithoutBackup)
        return entries.count
    }

    /// Opens a session's sealed vault into `vault`; values of a pinned
    /// session are pinned there too. Returns how many were added.
    static func unseal(session: String, storage: AgentRuntimeStorageLayout, vault: Sensitivity.Vault) async throws -> Int {
        let read = try TextFileReader(sealedFile(session, storage)).read(options: .init(missingFilePolicy: .returnEmpty))
        guard read.existed else { throw SealFailure.noSealedVault(session) }
        guard let combined = Data(base64Encoded: read.text.trimmingCharacters(in: .whitespacesAndNewlines)),
              let box = try? AES.GCM.SealedBox(combined: combined),
              let opened = try? AES.GCM.open(box, using: try SealKey.load())
        else {
            throw SealFailure.unreadable(session)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let added = await vault.insert(try decoder.decode([Sensitivity.Vault.Entry].self, from: opened))
        await vault.pin(only: References.pinned(in: storage))
        return added
    }

    static func sealedFile(_ session: String, _ storage: AgentRuntimeStorageLayout) -> URL {
        storage.sessiondir(sessionID: session).appendingPathComponent("vault.sealed")
    }
}

public extension Privacy.Tools {
    @Tool("seal_session")
    struct SealSession {
        @JSONSchema
        public struct Input: HashableSource {
            /// The session id (its directory name under sessions/).
            public let session: String

            public init(session: String) {
                self.session = session
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let session: String
            /// Values sealed into the session's vault.sealed.
            public let values: Int
        }

        public static let purpose =
            "Seal the values a session's handles stand for into the session itself (encrypted), so a copy of it, such as a pinned record synced off this machine, still resolves its handles."
        public static let risk: ActionRisk = .privileged

        public init() {}

        public func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            let vault = try Privacy.activeGuard(in: context).vault
            let storage = AgentHomeLocator().resolveHome().layout.runtimeStorage
            guard Privacy.validSession(input.session), FileSystem.default.exists(storage.sessiondir(sessionID: input.session)) else {
                throw Privacy.Tools.ScrubSession.ScrubFailure.invalidSession(input.session)
            }
            return .init(session: input.session, values: try await Privacy.seal(session: input.session, storage: storage, vault: vault))
        }
    }

    @Tool("unseal_session")
    struct UnsealSession {
        @JSONSchema
        public struct Input: HashableSource {
            public let session: String

            public init(session: String) {
                self.session = session
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let session: String
            /// Values added to this machine's vault.
            public let added: Int
        }

        public static let purpose =
            "Open a session's sealed vault into this machine's vault, so its handles resolve here. Values never reach the model."
        public static let risk: ActionRisk = .privileged

        public init() {}

        public func call(_ input: Input, in context: CapabilityContext) async throws -> Output {
            let vault = try Privacy.activeGuard(in: context).vault
            let storage = AgentHomeLocator().resolveHome().layout.runtimeStorage
            guard Privacy.validSession(input.session) else {
                throw Privacy.Tools.ScrubSession.ScrubFailure.invalidSession(input.session)
            }
            return .init(session: input.session, added: try await Privacy.unseal(session: input.session, storage: storage, vault: vault))
        }
    }
}

extension Privacy {
    static func validSession(_ session: String) -> Bool {
        !session.isEmpty && !session.contains("/") && !session.contains("..")
    }
}

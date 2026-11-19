import Agentic
import AgenticConfiguration
import Foundation
import IO
import Readers
import Sensitivity

public extension Privacy {
    /// Held in a session's services while it runs. Releasing the last copy
    /// closes the session for an `.onSessionClose` vault.
    final class SessionLease: Sendable {
        public let session: String
        let vault: Sensitivity.Vault
        let releasesOnClose: Bool

        init(session: String, vault: Sensitivity.Vault, releasesOnClose: Bool) {
            self.session = session
            self.vault = vault
            self.releasesOnClose = releasesOnClose
        }

        deinit {
            guard releasesOnClose else { return }
            let vault = vault
            let session = session
            Task { await vault.release(session: session) }
        }
    }

    /// One vault per process for each store, so sessions in one host share
    /// handles and the Keychain item is opened once.
    private static let vaults = VaultRegistry()

    /// The guard and lease for a session, as configured in the home's
    /// `domains/sensitivity.frame`. For `.unreferenced`, values no recorded
    /// session holds any more are dropped in the background.
    static func session(
        _ sessionID: String?,
        home: AgentHome = AgentHomeLocator().resolveHome(),
        configuration: Configuration? = nil
    ) -> (guarding: ToolPayloadGuarding, lease: SessionLease?, problem: String?) {
        let (loaded, problem) = configuration.map { ($0, nil) } ?? Configuration.load(home: home)
        let vault = vaults.vault(for: loaded)
        let installed = Guard(vault: vault, shieldPolicy: loaded.shield, policy: loaded.resolution, session: sessionID)

        if loaded.expiry == .unreferenced {
            let sessions = home.layout.runtimeStorage.sessionsdir
            Task.detached(priority: .utility) {
                let referenced = References.collect(below: sessions)
                await vault.retain(referenced: referenced)
            }
        }
        let lease = sessionID.map { SessionLease(session: $0, vault: vault, releasesOnClose: loaded.expiry == .onSessionClose) }
        return (ToolPayloadGuarding(installed), lease, problem)
    }

    /// Handle ids written in recorded sessions.
    enum References {
        public static func collect(below directory: URL) -> Set<String> {
            var ids: Set<String> = []
            for file in files(below: directory) {
                guard let text = try? TextFileReader(file).read(options: .init(missingFilePolicy: .returnEmpty)).text,
                      text.contains("⟦")
                else {
                    continue
                }
                for occurrence in Sensitivity.Handle.occurrences(in: text) {
                    ids.insert(occurrence.handle.id)
                }
            }
            return ids
        }

        static func files(below directory: URL) -> [URL] {
            guard let entries = try? DirectoryInspector(directory).entries() else { return [] }
            return entries.flatMap { entry -> [URL] in
                switch entry.kind {
                case .directory: return files(below: entry.url)
                case .file: return [entry.url]
                default: return []
                }
            }
        }
    }
}

private final class VaultRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var vaults: [String: Sensitivity.Vault] = [:]

    func vault(for configuration: Privacy.Configuration) -> Sensitivity.Vault {
        let lifetime: Duration?
        if case .after(let days) = configuration.expiry {
            lifetime = .seconds(days * 24 * 60 * 60)
        } else {
            lifetime = nil
        }
        let key = "\(configuration.store.rawValue)/\(String(describing: lifetime))"
        lock.lock()
        defer { lock.unlock() }
        if let existing = vaults[key] {
            return existing
        }
        let vault: Sensitivity.Vault
        switch configuration.store {
        case .keychain:
            vault = Sensitivity.Vault(lifetime: lifetime, store: Sensitivity.KeychainVaultStore(account: "vault"))
        case .memory:
            vault = Sensitivity.Vault(lifetime: lifetime)
        }
        vaults[key] = vault
        return vault
    }
}

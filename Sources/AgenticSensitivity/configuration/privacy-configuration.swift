import Agentic
import AgenticConfiguration
import Foundation
import Frame
import IO
import Readers
import Sensitivity
import Writers

public extension Privacy {
    /// `domains/sensitivity.frame`, with defaults for what it leaves out:
    /// a Keychain vault whose values live while anything in history holds
    /// their handle.
    struct Configuration: Sendable {
        public static let fileName = "sensitivity.frame"

        public enum Expiry: Sendable, Hashable {
            case unreferenced
            case onSessionClose
            case after(days: Int)
        }

        public var store: SensitivityFrame.Store
        public var expiry: Expiry
        /// Where a reference keeps a value, for `.unreferenced`.
        public var references: SensitivityFrame.References
        /// More directories counted as history.
        public var roots: [URL]
        public var shield: Sensitivity.ShieldPolicy
        public var resolution: ResolutionPolicy
        /// How the owner's screens show handles.
        public var display: SensitivityFrame.DisplayMode

        public init(
            store: SensitivityFrame.Store = .keychain,
            expiry: Expiry = .unreferenced,
            references: SensitivityFrame.References = .history,
            roots: [URL] = [],
            shield: Sensitivity.ShieldPolicy = .standard,
            resolution: ResolutionPolicy = .init(),
            display: SensitivityFrame.DisplayMode = .revealed
        ) {
            self.store = store
            self.expiry = expiry
            self.references = references
            self.roots = roots
            self.shield = shield
            self.resolution = resolution
            self.display = display
        }

        public static let standard = Self()

        public enum Failure: Error, LocalizedError, Sendable {
            case daysMissing
            case thresholds(handleAt: Int, softAt: Int)

            public var errorDescription: String? {
                switch self {
                case .daysMissing:
                    return "vault: .expire = .afterDays needs .days, a positive number."
                case .thresholds(let handleAt, let softAt):
                    return "policy: softAt (\(softAt)) must lie below handleAt (\(handleAt)), both within 0...100."
                }
            }
        }

        public init(source: String, filePath: String? = nil) throws {
            try self.init(document: Frame.parse(source, filePath: filePath, environment: SensitivityFrame.environment))
        }

        public init(document: Frame.Document) throws {
            let vault: SensitivityFrame.Vault? = try document.binding(named: SensitivityFrame.vaultBinding).map { _ in
                try document.decode(SensitivityFrame.Vault.self, binding: SensitivityFrame.vaultBinding)
            }
            let policy: SensitivityFrame.Policy? = try document.binding(named: SensitivityFrame.policyBinding).map { _ in
                try document.decode(SensitivityFrame.Policy.self, binding: SensitivityFrame.policyBinding)
            }
            let display: SensitivityFrame.Display? = try document.binding(named: SensitivityFrame.displayBinding).map { _ in
                try document.decode(SensitivityFrame.Display.self, binding: SensitivityFrame.displayBinding)
            }

            let expiry: Expiry
            switch vault?.expire ?? .unreferenced {
            case .unreferenced: expiry = .unreferenced
            case .onSessionClose: expiry = .onSessionClose
            case .afterDays:
                guard let days = vault?.days, days > 0 else { throw Failure.daysMissing }
                expiry = .after(days: days)
            }

            var shield = Sensitivity.ShieldPolicy.standard
            shield.handleAt = policy?.handleAt ?? shield.handleAt
            shield.softAt = policy?.softAt ?? shield.softAt
            guard (0...100).contains(shield.handleAt), (0...100).contains(shield.softAt), shield.softAt < shield.handleAt else {
                throw Failure.thresholds(handleAt: shield.handleAt, softAt: shield.softAt)
            }
            shield.never = Set((policy?.never ?? []).map { $0.lowercased() })

            var resolution = ResolutionPolicy()
            if let families = policy?.families {
                resolution.families = ResolutionPolicy.standardFamilies + families.map(Set.init)
            }

            let roots = (vault?.roots ?? []).map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath, isDirectory: true) }
            self.init(
                store: vault?.store ?? .keychain,
                expiry: expiry,
                references: vault?.references ?? .history,
                roots: roots,
                shield: shield,
                resolution: resolution,
                display: display?.mode ?? .revealed
            )
        }

        /// The directories whose files count as history in `home`.
        public func historyRoots(in home: AgentHome) -> [URL] {
            let base = references == .history ? home.layout.root : home.layout.runtimeStorage.sessionsdir
            return [base] + roots
        }

        /// The home's file; a missing one is written from the template
        /// first, and a file that does not hold gives the defaults and its
        /// problem.
        public static func load(home: AgentHome) -> (configuration: Configuration, problem: String?) {
            let file = home.layout.domainfile(fileName)
            guard let read = try? TextFileReader(file).read(options: .init(missingFilePolicy: .returnEmpty)), read.existed else {
                // Create-only: a file written meanwhile is never replaced.
                _ = try? FileWriter(file).write(SensitivityFrame.template)
                return (.standard, nil)
            }
            do {
                return (try Configuration(source: read.text, filePath: file.path), nil)
            } catch {
                return (.standard, "\(file.path): \((error as? LocalizedError)?.errorDescription ?? String(describing: error))")
            }
        }
    }
}

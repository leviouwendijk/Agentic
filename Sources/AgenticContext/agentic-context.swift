import Errors
import Agentic
import AgenticConfiguration
import Foundation
import IO
import Readers
import Roots
import Writers

/// What the owner tells agents about their world (business, people,
/// clients, projects) as `.frame` files of `Entry` bindings below the
/// home's `context/` directory. Agents see an index of summaries and read
/// bodies when they need them; entries marked `.always` are in every
/// agent's instructions.
@Domain("context")
public enum Context {}

public extension Context {
    /// Where the context files live, the shared roots' context folders, and
    /// where replaced files are kept. Insert one into `ToolServices` to
    /// point the tools elsewhere; without one they use the resolved home's
    /// and the shared roots in `~/.config/roots.frame`.
    struct Store: Sendable {
        public let directory: URL
        public let archiveDirectory: URL
        public let shared: [Library.SharedFolder]

        public init(directory: URL, archiveDirectory: URL, shared: [Library.SharedFolder] = []) {
            self.directory = directory
            self.archiveDirectory = archiveDirectory
            self.shared = shared
        }

        public init(home: AgentHome, roots: RootSet = Roots.load()) {
            self.init(
                directory: home.layout.contextdir,
                archiveDirectory: home.layout.archivedir.appendingPathComponent("context", isDirectory: true),
                shared: Library.SharedFolder.roots(roots)
            )
        }

        public func library() -> Library {
            .load(directory, shared: shared)
        }

        /// Where `file` is on disk: below the directory, or below a shared
        /// root's context (`team/business.frame` for the root `team`).
        /// Refuses anything that leaves them or cannot name entries.
        public func url(_ file: String) throws -> URL {
            try location(file).url
        }

        /// Whether `file` lies in a shared root not declared writable.
        public func isReadOnly(_ file: String) throws -> Bool {
            try location(file).readOnly
        }

        private func location(_ file: String) throws -> (url: URL, readOnly: Bool) {
            guard Context.idPrefix(of: file) != nil else {
                throw StoreFailure.invalidPath(file)
            }
            if let folder = shared.first(where: { file.hasPrefix("\($0.folder)/") }) {
                return (
                    folder.directory.appendingPathComponent(String(file.dropFirst(folder.folder.count + 1))),
                    folder.readOnly
                )
            }
            return (directory.appendingPathComponent(file), false)
        }

        /// The file's text; nil when there is none.
        public func text(_ file: String) throws -> String? {
            let read = try TextFileReader(url(file)).read(options: .init(missingFilePolicy: .returnEmpty))
            return read.existed ? read.text : nil
        }

        /// Archives the current file, if any, then writes `text` in its
        /// place. Returns the archived copy, which stays in this home even
        /// for a file in a shared root.
        public func save(_ text: String, to file: String, now: Date = Date()) throws -> URL? {
            let location = try location(file)
            guard !location.readOnly else {
                throw StoreFailure.readOnly(file)
            }
            let archived = try archive(file, now: now)
            try FileWriter(location.url).write(text, options: .overwriteWithoutBackup)
            return archived
        }

        /// Archives the file, then removes it. Returns the archived copy;
        /// nil when there was no file.
        public func remove(_ file: String, now: Date = Date()) throws -> URL? {
            let location = try location(file)
            guard !location.readOnly else {
                throw StoreFailure.readOnly(file)
            }
            guard let archived = try archive(file, now: now) else {
                return nil
            }
            try FileSystem.default.remove(location.url)
            return archived
        }

        /// A copy of the current file in the archive, named after it and
        /// the time; nil when there is no file.
        private func archive(_ file: String, now: Date) throws -> URL? {
            guard let current = try text(file) else {
                return nil
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let stem = "\(file.dropLast(".frame".count).replacingOccurrences(of: "/", with: "."))-\(formatter.string(from: now))"
            // Saves within one second get -2, -3, ...
            var archive = archiveDirectory.appendingPathComponent("\(stem).frame")
            var count = 1
            while FileSystem.default.exists(archive) {
                count += 1
                archive = archiveDirectory.appendingPathComponent("\(stem)-\(count).frame")
            }
            try FileWriter(archive).write(current)
            return archive
        }
    }

    enum StoreFailure: Error, Sendable, Hashable {
        case invalidPath(String)
        case readOnly(String)
    }

    /// The session's store, or the resolved home's.
    static func store(in context: ToolContext) -> Store {
        (try? context.require(Store.self)) ?? Store(home: AgentHomeLocator().resolveHome())
    }
}

extension Context.StoreFailure:
    SemanticError,
    ErrorNamespaced,
    ErrorDispositionProviding
{
    public static let errorNamespace = "agentic_context.store"

    public var errorCode: String {
        switch self {
        case .invalidPath: return "invalid_path"
        case .readOnly: return "read_only"
        }
    }

    public var errorPresentation: ErrorPresentation {
        switch self {
        case .invalidPath(let file):
            return .init(
                message: "'\(file)' is not a context file path.",
                reason: "A context file is a path below context/ such as business.frame or people/sam.frame; names hold only letters, digits, _ and -."
            )
        case .readOnly(let file):
            return .init(
                message: "'\(file)' is in a shared root not declared writable (~/.config/roots.frame).",
                recoverySuggestion: "Change it where that context is kept."
            )
        }
    }

    public var errorDiagnosticFields: [ErrorDiagnosticField] {
        switch self {
        case .invalidPath(let file), .readOnly(let file):
            return [.init(key: "context.file", value: file)]
        }
    }

    public var errorDisposition: ErrorDisposition? {
        switch self {
        case .invalidPath: return .invalid_input
        case .readOnly: return .requires_access
        }
    }
}

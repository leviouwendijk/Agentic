import Agentic
import AgenticConfiguration
import Foundation
import IO
import Readers
import Writers

/// What the owner tells agents about their world (business, people,
/// clients, projects) as `.frame` files of `Entry` bindings below the
/// home's `context/` directory. Agents see an index of summaries and read
/// bodies when they need them; entries marked `.always` are in every
/// agent's instructions.
@Domain
public enum Context {}

public extension Context {
    /// Where the context files live, and where replaced files are kept.
    /// Insert one into `ToolServices` to point the tools elsewhere; without
    /// one they use the resolved home's.
    struct Store: Sendable {
        public let directory: URL
        public let archiveDirectory: URL

        public init(directory: URL, archiveDirectory: URL) {
            self.directory = directory
            self.archiveDirectory = archiveDirectory
        }

        public init(home: AgentHome) {
            self.init(
                directory: home.layout.contextdir,
                archiveDirectory: home.layout.archivedir.appendingPathComponent("context", isDirectory: true)
            )
        }

        public func library() -> Library {
            .load(directory)
        }

        /// `file` below the directory; refuses anything that leaves it or
        /// cannot name entries.
        public func url(_ file: String) throws -> URL {
            guard Context.idPrefix(of: file) != nil else {
                throw StoreFailure.invalidPath(file)
            }
            return directory.appendingPathComponent(file)
        }

        /// The file's text; nil when there is none.
        public func text(_ file: String) throws -> String? {
            let read = try TextFileReader(url(file)).read(options: .init(missingFilePolicy: .returnEmpty))
            return read.existed ? read.text : nil
        }

        /// Archives the current file, if any, then writes `text` in its
        /// place. Returns the archived copy.
        public func save(_ text: String, to file: String, now: Date = Date()) throws -> URL? {
            let target = try url(file)
            var archived: URL?
            if let current = try self.text(file) {
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
                archived = archive
            }
            try FileWriter(target).write(text, options: .overwriteWithoutBackup)
            return archived
        }
    }

    enum StoreFailure: Error, LocalizedError, Sendable, Hashable {
        case invalidPath(String)

        public var errorDescription: String? {
            switch self {
            case .invalidPath(let file):
                return "'\(file)': a context file is a path below context/ such as business.frame or people/sam.frame; names hold only letters, digits, _ and -."
            }
        }
    }

    /// The session's store, or the resolved home's.
    static func store(in context: ToolContext) -> Store {
        (try? context.require(Store.self)) ?? Store(home: AgentHomeLocator().resolveHome())
    }
}

import Agentic
import AgenticConfiguration
import Foundation
import IO
import Macros
import Primitives
import Readers
import Schema
import Sensitivity
import Writers

public extension Privacy.Tools {
    @JSONSchema
    struct KindCount: HashableResult {
        public let kind: String
        public let count: Int
    }

    /// Rewrites a recorded session with handles in place of sensitive
    /// values. The values go to the vault, never into this tool's output or
    /// its own record: the report is counts and file names only, so
    /// scrubbing leaves nothing to scrub.
    @Tool("privacy_scrub_session")
    struct ScrubSession {
        @JSONSchema
        public struct Input: HashableSource {
            /// The session id (its directory name under sessions/).
            public let session: String
            /// Report what would change without writing; true by default.
            public let dry_run: Bool?

            public init(session: String, dry_run: Bool? = nil) {
                self.session = session
                self.dry_run = dry_run
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let session: String
            public let dry_run: Bool
            public let files_scanned: Int
            public let files_changed: [String]
            /// Values replaced by handles, per kind.
            public let replaced: [KindCount]
            /// Uncertain findings left in place.
            public let flagged: Int
        }

        public static let purpose =
            "Scrub a recorded session: every log line and payload rewritten with handles in place of sensitive values. Dry run by default; writing replaces the originals, which are not kept."
        public static let risk: ActionRisk = .privileged

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let shield = try Privacy.activeGuard(in: context).shield
            guard !input.session.isEmpty, !input.session.contains("/"), !input.session.contains("..") else {
                throw ScrubFailure.invalidSession(input.session)
            }
            let directory = AgentHomeLocator().resolveHome().layout.runtimeStorage.sessiondir(sessionID: input.session)
            guard FileSystem.default.exists(directory) else {
                throw ScrubFailure.invalidSession(input.session)
            }
            let dryRun = input.dry_run ?? true
            var counts: [Sensitivity.Kind: Int] = [:]
            var flagged = 0
            var changed: [String] = []
            let files = try Self.files(below: directory)
            for file in files {
                let original = try TextFileReader(file).read(options: .init(missingFilePolicy: .returnEmpty)).text
                let (scrubbed, protection) = await Self.scrub(original, file: file, shield: shield)
                for item in protection.items {
                    if item.handle == nil { flagged += 1 } else { counts[item.kind, default: 0] += 1 }
                }
                guard scrubbed != original else { continue }
                changed.append(String(file.path.dropFirst(directory.path.count + 1)))
                if !dryRun {
                    try FileWriter(file).write(scrubbed, options: .overwriteWithoutBackup)
                }
            }
            return .init(
                session: input.session,
                dry_run: dryRun,
                files_scanned: files.count,
                files_changed: changed,
                replaced: counts.sorted { $0.key.rawValue < $1.key.rawValue }.map { .init(kind: $0.key.rawValue, count: $0.value) },
                flagged: flagged
            )
        }

        enum ScrubFailure: Error, LocalizedError {
            case invalidSession(String)

            var errorDescription: String? {
                switch self {
                case .invalidSession(let session):
                    return "'\(session)' is not a recorded session; list them with list_agent_sessions."
                }
            }
        }

        static func files(below directory: URL) throws -> [URL] {
            var found: [URL] = []
            for entry in try DirectoryInspector(directory).entries().sorted(by: { $0.url.path < $1.url.path }) {
                switch entry.kind {
                case .directory:
                    found += try files(below: entry.url)
                case .file:
                    found.append(entry.url)
                default:
                    continue
                }
            }
            return found
        }

        /// JSON Lines line by line, JSON as JSON (paths reported), the rest
        /// as text.
        static func scrub(_ text: String, file: URL, shield: Sensitivity.Shield) async -> (String, Sensitivity.Protection) {
            let source = "session \(file.lastPathComponent)"
            let decoder = JSONDecoder()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            switch file.pathExtension {
            case "jsonl":
                var protection = Sensitivity.Protection()
                var lines: [String] = []
                for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
                    if let value = try? decoder.decode(JSONValue.self, from: Data(line.utf8)),
                       case (let protected, let found) = await shield.protect(value, source: source),
                       !found.items.isEmpty,
                       let encoded = try? encoder.encode(protected) {
                        protection.items += found.items
                        lines.append(String(decoding: encoded, as: UTF8.self))
                    } else {
                        let (protected, found) = await shield.protect(String(line), source: source)
                        protection.items += found.items
                        lines.append(protected)
                    }
                }
                return (lines.joined(separator: "\n"), protection)
            case "json":
                if let value = try? decoder.decode(JSONValue.self, from: Data(text.utf8)) {
                    let (protected, protection) = await shield.protect(value, source: source)
                    guard !protection.items.isEmpty, let encoded = try? encoder.encode(protected) else {
                        return (text, protection)
                    }
                    return (String(decoding: encoded, as: UTF8.self), protection)
                }
                return await shield.protect(text, source: source)
            default:
                return await shield.protect(text, source: source)
            }
        }
    }
}

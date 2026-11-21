import Agentic
import AgenticConfiguration
import CryptoKit
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
    @Tool("scrub_session")
    struct ScrubSession {
        @JSONSchema
        public struct Input: HashableSource {
            /// The session id (its directory name under sessions/).
            public let session: String
            /// Report what would change without writing; true by default.
            public let dry_run: Bool?
            /// Required for a pinned session (a deletion request, a
            /// retention limit): the scrub is then deliberate, forgets the
            /// values and leaves a tombstone.
            public let reason: String?

            public init(session: String, dry_run: Bool? = nil, reason: String? = nil) {
                self.session = session
                self.dry_run = dry_run
                self.reason = reason
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
            /// A pinned session scrubbed deliberately: values forgotten, a
            /// tombstone written.
            public let deliberate: Bool
        }

        public static let purpose =
            "Scrub a recorded session: every log line and payload rewritten with handles in place of sensitive values. Dry run by default; writing replaces the originals, which are not kept. A pinned session (the faithful record of published content) needs a reason, such as a deletion request: its values are then forgotten and a tombstone records what was removed."
        public static let risk: ActionRisk = .privileged

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let shield = try Privacy.activeGuard(in: context).shield
            guard !input.session.isEmpty, !input.session.contains("/"), !input.session.contains("..") else {
                throw ScrubFailure.invalidSession(input.session)
            }
            let storage = AgentHomeLocator().resolveHome().layout.runtimeStorage
            let directory = storage.sessiondir(sessionID: input.session)
            guard FileSystem.default.exists(directory) else {
                throw ScrubFailure.invalidSession(input.session)
            }
            let pin = storage.pin(sessionID: input.session)
            let reason = input.reason?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let pin, reason?.isEmpty ?? true {
                throw ScrubFailure.pinned(input.session, pin.reason)
            }
            let deliberate = pin != nil
            let dryRun = input.dry_run ?? true
            var digests: [(file: String, previous: String)] = []
            var handled: Set<String> = []
            var counts: [Sensitivity.Kind: Int] = [:]
            var flagged = 0
            var changed: [String] = []
            let files = try Self.files(below: directory).filter { !Self.ownFiles.contains($0.lastPathComponent) }
            for file in files {
                let original = try TextFileReader(file).read(options: .init(missingFilePolicy: .returnEmpty)).text
                let (scrubbed, protection) = await Self.scrub(original, file: file, shield: shield)
                for item in protection.items {
                    if item.handle == nil { flagged += 1 } else { counts[item.kind, default: 0] += 1 }
                }
                // Every handle in the scrubbed file: values that came from it.
                for occurrence in Sensitivity.Handle.occurrences(in: scrubbed) {
                    handled.insert(occurrence.handle.id)
                }
                guard scrubbed != original else { continue }
                let relative = String(file.path.dropFirst(directory.path.count + 1))
                changed.append(relative)
                digests.append((relative, Self.digest(original)))
                if !dryRun {
                    try FileWriter(file).write(scrubbed, options: .overwriteWithoutBackup)
                }
            }
            if deliberate, !dryRun, let reason {
                // A deletion leaves no way back to the values.
                await shield.vault.forget(handled)
                try Self.tombstone(
                    in: directory,
                    reason: reason,
                    counts: counts,
                    digests: digests
                )
            }
            return .init(
                session: input.session,
                dry_run: dryRun,
                files_scanned: files.count,
                files_changed: changed,
                replaced: counts.sorted { $0.key.rawValue < $1.key.rawValue }.map { .init(kind: $0.key.rawValue, count: $0.value) },
                flagged: flagged,
                deliberate: deliberate
            )
        }

        enum ScrubFailure: Error, LocalizedError {
            case invalidSession(String)
            case pinned(String, String)

            var errorDescription: String? {
                switch self {
                case .invalidSession(let session):
                    return "'\(session)' is not a recorded session; list them with sessions_tool_list."
                case .pinned(let session, let why):
                    return "'\(session)' is pinned (\(why)) and kept as the faithful record. Scrub it only deliberately: give a reason, such as a deletion request."
                }
            }
        }

        /// Files the scrub keeps as they are: the pin, tombstones, a sealed
        /// vault.
        static let ownFiles: Set<String> = ["pin.json", "tombstones.jsonl", "vault.sealed"]

        static func digest(_ text: String) -> String {
            "sha256:" + SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
        }

        /// Appends what a deliberate scrub removed: when, why, kinds and
        /// counts, and each changed file's previous digest. Never values.
        static func tombstone(
            in directory: URL,
            reason: String,
            counts: [Sensitivity.Kind: Int],
            digests: [(file: String, previous: String)]
        ) throws {
            struct Tombstone: Encodable {
                let scrubbed: String
                let reason: String
                let removed: [String: Int]
                let files: [[String: String]]
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            let line = String(decoding: try encoder.encode(Tombstone(
                scrubbed: ISO8601DateFormatter().string(from: Date()),
                reason: reason,
                removed: Dictionary(uniqueKeysWithValues: counts.map { ($0.key.rawValue, $0.value) }),
                files: digests.map { ["file": $0.file, "previous": $0.previous] }
            )), as: UTF8.self)
            let file = directory.appendingPathComponent("tombstones.jsonl")
            let existing = try TextFileReader(file).read(options: .init(missingFilePolicy: .returnEmpty)).text
            try FileWriter(file).write(existing + line + "\n", options: .overwriteWithoutBackup)
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

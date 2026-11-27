import Agentic
import AgenticConfiguration
import Foundation
import Frame
import IO
import Readers
import Writers

public extension Harness {
    /// One finding from a run retrospective: a claim about how the harness
    /// served a run, the evidence it rests on, and the change it suggests.
    /// Kept as `let finding: Finding` in `improvements/<date>-<slug>.frame`.
    struct Finding: Sendable, Hashable, Codable {
        public enum Category: String, Sendable, Hashable, Codable, CaseIterable {
            /// What requests carried: elision, re-reads, cache misses, bloat.
            case context
            /// Tools revealed and unused, searches that found nothing,
            /// declared tools never used, missing tools.
            case capabilities
            /// Contradictions, ignored guidance, restated requests.
            case instructions
            /// Loops, retries, approval stalls, costly delegation.
            case workflow
            /// Model choice against outcome and cost.
            case routing
        }

        public enum Status: String, Sendable, Hashable, Codable, CaseIterable {
            case open
            case accepted
            case rejected
            case applied
        }

        public let category: Category
        /// The claim, in one line.
        public let title: String
        /// What was observed, with numbers where there are any.
        public let detail: String
        /// Where it shows: `<session> step <seq>` or a payload digest.
        /// Every finding has at least one.
        public let evidence: [String]
        /// The estimated effect, recomputed from the record where it is
        /// about tokens or cost: `≈4.2k input tokens per session`.
        public let effect: String?
        /// The change it suggests.
        public let proposal: String
        public let status: Status
        /// `YYYY-MM-DD`: when it was first recorded.
        public let recorded: String
        /// `YYYY-MM-DD`: when evidence was last added.
        public let updated: String?

        public init(
            category: Category,
            title: String,
            detail: String,
            evidence: [String],
            effect: String? = nil,
            proposal: String,
            status: Status = .open,
            recorded: String,
            updated: String? = nil
        ) {
            self.category = category
            self.title = title
            self.detail = detail
            self.evidence = evidence
            self.effect = effect
            self.proposal = proposal
            self.status = status
            self.recorded = recorded
            self.updated = updated
        }

        /// This finding with more evidence; the claim and proposal stay.
        public func adding(
            evidence more: [String],
            on day: String
        ) -> Self {
            .init(
                category: category,
                title: title,
                detail: detail,
                evidence: evidence + more.filter { !evidence.contains($0) },
                effect: effect,
                proposal: proposal,
                status: status,
                recorded: recorded,
                updated: day
            )
        }
    }

    /// The `Improvements` Frame module: what finding files import.
    enum ImprovementsFrame {
        public static let module = Frame.Module("Improvements", types: [
            .decodable(Finding.self, named: "Finding"),
        ])
        public static let binding = "finding"
        public static let type = "Finding"
    }

    /// Where findings live: the home's `improvements/` directory.
    struct Improvements: Sendable {
        public let directory: URL

        public init(directory: URL) {
            self.directory = directory
        }

        public init(home: AgentHome) {
            self.init(directory: home.layout.improvementsdir)
        }

        /// The session's store, or the resolved home's.
        public static func store(in context: CapabilityContext) -> Self {
            (try? context.require(Self.self)) ?? .init(home: AgentHomeLocator().resolveHome())
        }

        /// Every finding by file name, oldest file first, and the files
        /// that could not be read.
        public func findings() -> (findings: [(file: String, finding: Finding)], problems: [String]) {
            guard FileSystem.default.exists(directory),
                  let entries = try? DirectoryInspector(directory).entries()
            else { return ([], []) }
            var findings: [(file: String, finding: Finding)] = []
            var problems: [String] = []
            for entry in entries where entry.kind == .file && entry.url.pathExtension == "frame" {
                let file = entry.url.lastPathComponent
                do {
                    findings.append((file, try finding(file)))
                } catch {
                    problems.append("\(file): \(error.localizedDescription)")
                }
            }
            return (findings.sorted { $0.file < $1.file }, problems)
        }

        public func finding(_ file: String) throws -> Finding {
            let read = try TextFileReader(directory.appendingPathComponent(file)).read()
            let document = try Frame.parse(read.text, filePath: file)
            return try document.decode(Finding.self, binding: ImprovementsFrame.binding)
        }

        /// Writes a new finding; returns its file name.
        @discardableResult
        public func record(_ finding: Finding) throws -> String {
            let stem = "\(finding.recorded)-\(Self.slug(finding.title))"
            var file = "\(stem).frame"
            var count = 1
            while FileSystem.default.exists(directory.appendingPathComponent(file)) {
                count += 1
                file = "\(stem)-\(count).frame"
            }
            try FileWriter(directory.appendingPathComponent(file)).write(try Self.source(finding))
            return file
        }

        /// Replaces an existing finding, such as one with added evidence.
        public func replace(_ file: String, with finding: Finding) throws {
            try FileWriter(directory.appendingPathComponent(file))
                .write(try Self.source(finding), options: .overwriteWithoutBackup)
        }

        public static func source(_ finding: Finding) throws -> String {
            try Frame.document(
                imports: [ImprovementsFrame.module.name],
                bindings: [(name: ImprovementsFrame.binding, type: ImprovementsFrame.type, value: finding)]
            ).source
        }

        static func slug(_ title: String) -> String {
            let words = title.lowercased()
                .split { !($0.isLetter || $0.isNumber) }
                .prefix(6)
            return words.isEmpty ? "finding" : words.joined(separator: "-")
        }
    }
}

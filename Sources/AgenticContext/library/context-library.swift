import Foundation
import Frame
import IO
import Readers
import Roots

public extension Context {
    /// Every entry below a `context/` directory, read from its files on
    /// each load: identifiers come from where entries are, so there is no
    /// index to keep in step. Each shared root (Frame's `Roots`, declared in
    /// `~/.config/roots.frame`) brings in its `.agentic/context/` as if it
    /// were a folder named after the root.
    struct Library: Sendable {
        public struct Item: Sendable, Hashable {
            /// `business.services`, `people.sam.role`.
            public let id: String
            /// The file below the context directory, such as
            /// `people/sam.frame`; in a shared root, through its folder:
            /// `team/business.frame`.
            public let file: String
            public let entry: ContextFrame.Entry
        }

        /// A shared root's context directory and the folder it appears as.
        public struct SharedFolder: Sendable, Hashable {
            /// The root's name: `team`, so `team/business.frame` and
            /// `team.business.overview`.
            public let folder: String
            public let directory: URL
            /// The root is not declared writable: nothing is saved there.
            public let readOnly: Bool

            public init(folder: String, directory: URL, readOnly: Bool) {
                self.folder = folder
                self.directory = directory.standardizedFileURL
                self.readOnly = readOnly
            }

            /// The `.agentic/context` of every shared root in `roots`
            /// that has one.
            public static func roots(_ roots: RootSet = Roots.load()) -> [SharedFolder] {
                roots.shared
                    .map { SharedFolder(folder: $0.name, directory: $0.url(.agenticContext), readOnly: !$0.writable) }
                    .filter { FileSystem.default.exists($0.directory) }
            }
        }

        public let directory: URL
        public let items: [Item]
        public let shared: [SharedFolder]
        /// `file:line:column: message`; a file with problems contributes no
        /// entries.
        public let problems: [String]

        public func item(_ id: String) -> Item? {
            items.first { $0.id == id }
        }

        /// The shared folder `file` lies below, if any.
        public func shared(containing file: String) -> SharedFolder? {
            shared.first { file.hasPrefix("\($0.folder)/") }
        }

        /// Entries every agent receives.
        public var always: [Item] {
            items.filter { $0.entry.load == .always }
        }

        /// Every identifier prefix above the entries (folders and files),
        /// with how many entries lie below it, in order.
        public var groups: [(prefix: String, entries: Int)] {
            var counts: [String: Int] = [:]
            for item in items {
                let parts = item.id.split(separator: ".").dropLast()
                for end in parts.indices {
                    counts[parts[...end].joined(separator: "."), default: 0] += 1
                }
            }
            return counts.keys.sorted().map { ($0, counts[$0] ?? 0) }
        }

        public init(directory: URL, items: [Item], shared: [SharedFolder] = [], problems: [String]) {
            self.directory = directory
            self.items = items
            self.shared = shared
            self.problems = problems
        }

        /// Reads every `.frame` file below `directory` and below each
        /// shared folder; hidden files and folders are skipped. A missing
        /// directory is an empty library.
        public static func load(_ directory: URL, shared: [SharedFolder] = []) -> Library {
            var items: [Item] = []
            var problems: [String] = []
            let files = frameFiles(in: directory, problems: &problems)
            for file in files {
                guard let text = read(directory.appendingPathComponent(file), file: file, problems: &problems) else {
                    continue
                }
                let result = Context.read(text, file: file)
                problems += result.problems
                items += result.items
            }
            var folders: [SharedFolder] = []
            for folder in shared {
                if files.contains(where: { $0.hasPrefix("\(folder.folder)/") || $0 == "\(folder.folder).frame" }) {
                    problems.append("\(folder.folder)/: the shared root '\(folder.folder)' and a local file or folder of that name; rename the local one.")
                    continue
                }
                folders.append(folder)
                items += sharedItems(folder, problems: &problems)
            }
            problems += unresolvedRelations(in: items)
            return .init(directory: directory, items: items, shared: folders, problems: problems)
        }

        /// This library with `file` holding `text` instead, as it would be
        /// after saving it.
        public func replacing(_ file: String, with text: String) -> (library: Library, problems: [String]) {
            let result = Context.read(text, file: file)
            var problems = result.problems
            if shared(containing: file) == nil, shared.contains(where: { "\($0.folder).frame" == file }) {
                problems.append("\(file): has the name of a shared root; pick another.")
            }
            let merged = items.filter { $0.file != file } + result.items
            // Its own broken relations, and those of other files it breaks.
            let before = Set(Self.unresolvedRelations(in: items))
            problems += Self.unresolvedRelations(in: merged).filter {
                $0.hasPrefix("\(file):") || !before.contains($0)
            }
            return (
                .init(
                    directory: directory,
                    items: merged,
                    shared: shared,
                    problems: self.problems.filter { !$0.hasPrefix("\(file):") }
                ),
                problems
            )
        }

        private static func read(_ url: URL, file: String, problems: inout [String]) -> String? {
            do {
                return try TextFileReader(url).read().text
            } catch {
                problems.append("\(file): \(error.localizedDescription)")
                return nil
            }
        }

        /// The entries of a shared folder, under its name.
        private static func sharedItems(_ folder: SharedFolder, problems: inout [String]) -> [Item] {
            var items: [Item] = []
            for inner in frameFiles(in: folder.directory, problems: &problems) {
                let file = "\(folder.folder)/\(inner)"
                guard let text = read(folder.directory.appendingPathComponent(inner), file: file, problems: &problems) else {
                    continue
                }
                let result = Context.read(text, file: file)
                items += result.items
                problems += result.problems
            }
            return items
        }

        private static func frameFiles(in directory: URL, below prefix: String = "", problems: inout [String]) -> [String] {
            guard FileSystem.default.exists(directory) else { return [] }
            let entries: [FileMetadataSnapshot]
            do {
                entries = try DirectoryInspector(directory).entries()
            } catch {
                problems.append("\(prefix.isEmpty ? "." : prefix): \(error.localizedDescription)")
                return []
            }
            var files: [String] = []
            for entry in entries {
                let name = entry.url.lastPathComponent
                guard !name.hasPrefix(".") else { continue }
                let path = prefix.isEmpty ? name : "\(prefix)/\(name)"
                switch entry.kind {
                case .directory:
                    files += frameFiles(in: entry.url, below: path, problems: &problems)
                case .file where name.hasSuffix(".frame"):
                    files.append(path)
                default:
                    continue
                }
            }
            return files
        }

        private static func unresolvedRelations(in items: [Item]) -> [String] {
            let ids = Set(items.map(\.id))
            return items.flatMap { item in
                (item.entry.related ?? []).filter { !ids.contains($0) }.map {
                    "\(item.file): '\(item.id)' relates to '\($0)', which no file defines."
                }
            }
        }
    }

    /// The identifier prefix of a file: `people/sam.frame` is `people.sam`.
    /// Nil when a path component cannot be part of an identifier.
    static func idPrefix(of file: String) -> String? {
        guard file.hasSuffix(".frame") else { return nil }
        let components = String(file.dropLast(".frame".count)).split(separator: "/").map(String.init)
        guard !components.isEmpty, components.allSatisfy(isIdentifierComponent) else { return nil }
        return components.joined(separator: ".")
    }

    static func isIdentifierComponent(_ name: String) -> Bool {
        !name.isEmpty && name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }

    /// What one file holds: its entries, or why it does not hold.
    static func read(_ text: String, file: String) -> (items: [Library.Item], problems: [String]) {
        guard let prefix = idPrefix(of: file) else {
            return ([], ["\(file): file and folder names may hold only letters, digits, _ and -, and the file must end in .frame."])
        }
        let document: Frame.Document
        do {
            document = try Frame.parse(text, filePath: file)
        } catch {
            return ([], ["\(file): \(error)"])
        }
        let problems = Frame.problems(in: document, environment: ContextFrame.environment)
            .map { "\(file):\($0.located(in: text).description)" }
        guard problems.isEmpty else { return ([], problems) }

        var items: [Library.Item] = []
        var found: [String] = []
        var shared: [String] = []
        let defaults = document.bindings(ofType: ContextFrame.defaultsType)
        if defaults.count > 1 {
            found.append("\(file): at most one `Defaults` binding, not \(defaults.count).")
        }
        if let binding = defaults.first {
            do {
                shared = try document.decode(ContextFrame.Defaults.self, binding: binding.name).tags ?? []
            } catch {
                found.append("\(file): '\(binding.name)': \(error)")
            }
        }
        for binding in document.bindings(ofType: ContextFrame.entryType) {
            do {
                var entry = try document.decode(ContextFrame.Entry.self, binding: binding.name)
                if !shared.isEmpty {
                    entry = entry.tagged(shared)
                }
                if let updated = entry.updated, !isDate(updated) {
                    found.append("\(file): '\(binding.name)': updated must be YYYY-MM-DD, not '\(updated)'.")
                    continue
                }
                items.append(.init(id: "\(prefix).\(binding.name)", file: file, entry: entry))
            } catch {
                found.append("\(file): '\(binding.name)': \(error)")
            }
        }
        if found.isEmpty, items.isEmpty {
            found.append("\(file): no `let name: Entry` bindings.")
        }
        return found.isEmpty ? (items, []) : ([], found)
    }

    private static func isDate(_ text: String) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return text.count == 10 && formatter.date(from: text) != nil
    }
}

public extension Context.Library {
    /// Entries passing every filter given; a nil filter passes all.
    /// - `tags`: carries any of them.
    /// - `under`: identifier at or below this group.
    /// - `within`: one of these identifiers, such as a previous result.
    /// - `updatedFrom`/`updatedTo`: `updated` within these `YYYY-MM-DD`
    ///   days, inclusive; an entry without a date fails a date filter.
    /// - `load`: entries loaded this way.
    func selecting(
        tags: [String]? = nil,
        under: String? = nil,
        within: [String]? = nil,
        updatedFrom: String? = nil,
        updatedTo: String? = nil,
        load: ContextFrame.Load? = nil
    ) -> [Item] {
        let tags = Set(tags ?? [])
        let under = under.map { $0.hasSuffix(".") ? String($0.dropLast()) : $0 }
        let within = within.map(Set.init)
        return items.filter { item in
            (tags.isEmpty || !tags.isDisjoint(with: item.entry.tags ?? []))
                && (under.map { item.id == $0 || item.id.hasPrefix("\($0).") } ?? true)
                && (within?.contains(item.id) ?? true)
                && (updatedFrom.map { from in item.entry.updated.map { $0 >= from } ?? false } ?? true)
                && (updatedTo.map { to in item.entry.updated.map { $0 <= to } ?? false } ?? true)
                && (load.map { (item.entry.load ?? .onRequest) == $0 } ?? true)
        }
    }
}

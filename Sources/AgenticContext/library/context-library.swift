import Foundation
import Frame
import IO
import Readers

public extension Context {
    /// Every entry below a `context/` directory, read from its files on
    /// each load: identifiers come from where entries are, so there is no
    /// index to keep in step. A mount file brings in another directory,
    /// such as a team's shared context, as if it were a folder.
    struct Library: Sendable {
        public struct Item: Sendable, Hashable {
            /// `business.services`, `people.sam.role`.
            public let id: String
            /// The file below the context directory, such as
            /// `people/sam.frame`; below a mount, through its folder:
            /// `team/business.frame`.
            public let file: String
            public let entry: ContextFrame.Entry
        }

        /// A mount file and the directory it brings in.
        public struct MountPoint: Sendable, Hashable {
            /// The mount file below the context directory: `team.frame`.
            public let file: String
            /// Where its entries appear: `team`, so `team/business.frame`
            /// and `team.business.overview`.
            public let folder: String
            public let directory: URL
            public let readOnly: Bool
        }

        public let directory: URL
        public let items: [Item]
        public let mounts: [MountPoint]
        /// `file:line:column: message`; a file with problems contributes no
        /// entries.
        public let problems: [String]

        public func item(_ id: String) -> Item? {
            items.first { $0.id == id }
        }

        /// The mount `file` lies below, if any.
        public func mount(containing file: String) -> MountPoint? {
            mounts.first { file.hasPrefix("\($0.folder)/") }
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

        public init(directory: URL, items: [Item], mounts: [MountPoint] = [], problems: [String]) {
            self.directory = directory
            self.items = items
            self.mounts = mounts
            self.problems = problems
        }

        /// Reads every `.frame` file below `directory`, following mount
        /// files; hidden files and folders are skipped. A missing
        /// directory is an empty library.
        public static func load(_ directory: URL) -> Library {
            var items: [Item] = []
            var mounts: [MountPoint] = []
            var problems: [String] = []
            let files = frameFiles(in: directory, problems: &problems)
            for file in files {
                guard let text = read(directory.appendingPathComponent(file), file: file, problems: &problems) else {
                    continue
                }
                let result = Context.read(text, file: file)
                problems += result.problems
                guard let mount = result.mount else {
                    items += result.items
                    continue
                }
                let folder = String(file.dropLast(".frame".count))
                if files.contains(where: { $0.hasPrefix("\(folder)/") }) {
                    problems.append("\(file): mounts at \(folder)/, which is also a folder here; rename one.")
                    continue
                }
                guard let point = mountPoint(mount, file: file, in: directory, problems: &problems) else {
                    continue
                }
                mounts.append(point)
                items += mounted(point, problems: &problems)
            }
            problems += unresolvedRelations(in: items)
            return .init(directory: directory, items: items, mounts: mounts, problems: problems)
        }

        /// This library with `file` holding `text` instead, as it would be
        /// after saving it.
        public func replacing(_ file: String, with text: String) -> (library: Library, problems: [String]) {
            let result = Context.read(text, file: file)
            var problems = result.problems
            let folder = String(file.dropLast(".frame".count))
            let replaced = mounts.first { $0.file == file }
            var others = items.filter { $0.file != file }
            if let replaced {
                others.removeAll { $0.file.hasPrefix("\(replaced.folder)/") }
            }
            var added = result.items
            var nextMounts = mounts.filter { $0.file != file }
            if let declared = result.mount {
                if self.mount(containing: file) != nil {
                    problems.append("\(file): a mount inside a mount is not followed.")
                } else if items.contains(where: { $0.file.hasPrefix("\(folder)/") && self.mount(containing: $0.file) == nil }) {
                    problems.append("\(file): mounts at \(folder)/, which is also a folder here; rename one.")
                } else if let point = Self.mountPoint(declared, file: file, in: directory, problems: &problems) {
                    nextMounts.append(point)
                    added = Self.mounted(point, problems: &problems)
                }
            }
            let merged = others + added
            // Its own broken relations, and those of other files it breaks.
            let before = Set(Self.unresolvedRelations(in: items))
            problems += Self.unresolvedRelations(in: merged).filter {
                $0.hasPrefix("\(file):") || !before.contains($0)
            }
            return (
                .init(
                    directory: directory,
                    items: merged,
                    mounts: nextMounts,
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

        /// Where `mount`, declared in `file`, points; nil with a problem
        /// when it cannot be followed.
        private static func mountPoint(
            _ mount: ContextFrame.Mount,
            file: String,
            in directory: URL,
            problems: inout [String]
        ) -> MountPoint? {
            let expanded = (mount.path as NSString).expandingTildeInPath
            let target = (expanded.hasPrefix("/")
                ? URL(fileURLWithPath: expanded, isDirectory: true)
                : directory.appendingPathComponent(file).deletingLastPathComponent()
                    .appendingPathComponent(expanded, isDirectory: true)
            ).standardizedFileURL
            guard (try? FileInspector(target).inspect(followingSymlinks: true))?.kind == .directory else {
                problems.append("\(file): mounts '\(mount.path)', which is not a directory (\(target.path)).")
                return nil
            }
            let root = directory.standardizedFileURL.path
            if target.path == root || target.path.hasPrefix(root + "/") {
                problems.append("\(file): mounts '\(mount.path)', which is inside this context directory.")
                return nil
            }
            return .init(
                file: file,
                folder: String(file.dropLast(".frame".count)),
                directory: target,
                readOnly: mount.readOnly ?? false
            )
        }

        /// The entries of a mounted directory, under its folder; mounts
        /// inside it are not followed.
        private static func mounted(_ point: MountPoint, problems: inout [String]) -> [Item] {
            var items: [Item] = []
            for inner in frameFiles(in: point.directory, problems: &problems) {
                let file = "\(point.folder)/\(inner)"
                guard let text = read(point.directory.appendingPathComponent(inner), file: file, problems: &problems) else {
                    continue
                }
                let result = Context.read(text, file: file)
                if result.mount != nil {
                    problems.append("\(file): a mount inside a mount is not followed.")
                    continue
                }
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

    /// What one file holds: its entries, or a mount; or why it does not
    /// hold.
    static func read(_ text: String, file: String) -> (items: [Library.Item], problems: [String], mount: ContextFrame.Mount?) {
        guard let prefix = idPrefix(of: file) else {
            return ([], ["\(file): file and folder names may hold only letters, digits, _ and -, and the file must end in .frame."], nil)
        }
        let document: Frame.Document
        do {
            document = try Frame.parse(text, filePath: file)
        } catch {
            return ([], ["\(file): \(error)"], nil)
        }
        let problems = Frame.problems(in: document, environment: ContextFrame.environment)
            .map { "\(file):\($0.located(in: text).description)" }
        guard problems.isEmpty else { return ([], problems, nil) }

        let mounts = document.bindings(ofType: ContextFrame.mountType)
        if let binding = mounts.first {
            let others = document.bindings.filter { $0.type?.components.last == ContextFrame.entryType
                || $0.type?.components.last == ContextFrame.defaultsType }
            guard mounts.count == 1, others.isEmpty else {
                return ([], ["\(file): a mount file holds one `Mount` and nothing else."], nil)
            }
            do {
                return ([], [], try document.decode(ContextFrame.Mount.self, binding: binding.name))
            } catch {
                return ([], ["\(file): '\(binding.name)': \(error)"], nil)
            }
        }

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
        return found.isEmpty ? (items, [], nil) : ([], found, nil)
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

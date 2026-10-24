import Difference
import Foundation
import Macros
import Schema

/// File-level operation identities derived from one prepared mutation plan.
/// This is an affected-path projection, NOT a before/after filesystem snapshot.
@JSONSchema
public struct FileMutationDifference: Sendable, Codable, Hashable {
    @JSONSchema
    public struct Entry: Sendable, Codable, Hashable {
        public let index: Int
        public let id: UUID
        /// Authorized display path of the target (destination for copy/move).
        public let path: String
        /// Authorized source display path for copy/move, otherwise nil.
        public let sourcePath: String?
        public let operation: String
        public let resource: String
        public let delta: String
        public let insertions: Int
        public let deletions: Int
        public let changeCount: Int

        public init(
            index: Int, id: UUID, path: String, sourcePath: String?,
            operation: String, resource: String, delta: String,
            insertions: Int, deletions: Int, changeCount: Int
        ) {
            self.index = index
            self.id = id
            self.path = path
            self.sourcePath = sourcePath
            self.operation = operation
            self.resource = resource
            self.delta = delta
            self.insertions = insertions
            self.deletions = deletions
            self.changeCount = changeCount
        }
    }

    /// Stable original plan order. Grouped view is presentation-only.
    public let entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries
    }

    public var isEmpty: Bool { entries.isEmpty }

    /// Native Difference tree layout computed solely from these entries.
    /// Repeated mutations to the same path stay distinct, keyed by entry UUID.
    public var tree_layout: TreeDifferenceLayout {
        var root = Node(name: "", directory_path: "", entry: nil)
        for entry in entries {
            let parts = entry.path.split(separator: "/").map(String.init)
            if parts.isEmpty {
                root.children.append(Node(
                    name: entry.path,
                    directory_path: nil,
                    entry: entry
                ))
            } else {
                root.insert(entry, parts: ArraySlice(parts))
            }
        }
        var lines: [TreeDifferenceLayout.Line] = []
        func visit(_ nodes: [Node], ancestors: [Bool]) {
            for (index, node) in nodes.enumerated() {
                let last = index == nodes.count - 1
                let entry = node.entry
                let marker: TreeChangeKind
                if let entry {
                    switch entry.operation {
                    case "create_text", "copy": marker = .added
                    case "delete": marker = .removed
                    case "move": marker = .moved
                    default:
                        marker = entry.resource == "unchanged"
                            ? .unchanged : .modified
                    }
                } else {
                    marker = .unchanged
                }
                let label: String
                if let entry {
                    let source = entry.sourcePath.map { " from \($0)" } ?? ""
                    label = "\(node.name) [\(entry.index): \(entry.operation)\(source)]"
                } else {
                    label = node.name + "/"
                }
                lines.append(.init(
                    depth: ancestors.count,
                    is_last_child: last,
                    ancestor_last: ancestors,
                    change: marker,
                    label: label,
                    id: entry.map { "mutation:\($0.id.uuidString)" }
                        ?? "directory:\(node.directory_path ?? node.name)"
                ))
                visit(node.children, ancestors: ancestors + [last])
            }
        }
        visit(root.children, ancestors: [])
        return .init(lines: lines)
    }

    private struct Node {
        let name: String
        let directory_path: String?
        let entry: Entry?
        var children: [Node] = []

        mutating func insert(_ entry: Entry, parts: ArraySlice<String>) {
            guard let head = parts.first else { return }
            if parts.count == 1 {
                children.append(.init(
                    name: head, directory_path: nil, entry: entry
                ))
                return
            }
            let path = directory_path.map {
                $0.isEmpty ? head : "\($0)/\(head)"
            } ?? head
            if let index = children.firstIndex(where: {
                $0.directory_path == path
            }) {
                children[index].insert(entry, parts: parts.dropFirst())
            } else {
                var directory = Node(
                    name: head, directory_path: path, entry: nil
                )
                directory.insert(entry, parts: parts.dropFirst())
                children.append(directory)
            }
        }
    }
}

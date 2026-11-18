import Foundation
import Frame

/// The `Context` Frame module: what `import Context;` makes nameable in the
/// home's `context/` files.
///
/// Every `let name: Entry` is one entry, identified by its file's path below
/// `context/` and its binding name: `let services` in `business.frame` is
/// `business.services`, `let role` in `people/sam.frame` is
/// `people.sam.role`. Folders only sort; tags select across them.
public enum ContextFrame {
    public static let module = Frame.Module("Context", types: [
        .decodable(Entry.self, named: "Entry"),
    ])

    public static let environment = Frame.Environment([module])

    /// The type entries are bound as.
    public static let entryType = "Entry"

    /// One thing agents may know about the owner's world.
    public struct Entry: Sendable, Hashable, Decodable {
        public let title: String
        /// What the index shows; enough to decide whether to read the body.
        public let summary: String
        public let body: String
        public let tags: [String]?
        public let load: Load?
        /// `YYYY-MM-DD`: when it was last known to hold.
        public let updated: String?
        /// Other entries by identifier.
        public let related: [String]?

        public init(
            title: String,
            summary: String,
            body: String,
            tags: [String]? = nil,
            load: Load? = nil,
            updated: String? = nil,
            related: [String]? = nil
        ) {
            self.title = title
            self.summary = summary
            self.body = body
            self.tags = tags
            self.load = load
            self.updated = updated
            self.related = related
        }
    }

    /// When an entry's body reaches an agent.
    public enum Load: String, Sendable, Hashable, Codable, CaseIterable {
        /// Listed in the index; the body is read when needed. The default.
        case onRequest
        /// In every agent's instructions; for short, always-relevant facts.
        case always
    }
}

extension ContextFrame.Entry: FrameDescribable {
    public static var frameSchema: Frame.Schema {
        .object([
            .init("title", .string, required: true),
            .init("summary", .string, required: true,
                  summary: "One line: what the index shows, enough to decide whether to read the body."),
            .init("body", .string, required: true,
                  summary: "The content itself; a block string (\"\"\" … \"\"\") for prose."),
            .init("tags", .array(.string),
                  summary: "Selects across folders, such as \"business\" or \"pricing\"; domains ask for entries by tag."),
            .init("load", .members(of: ContextFrame.Load.self, summaries: [
                .onRequest: "Listed in the index; the body is read when needed. The default.",
                .always: "In every agent's instructions. For short, always-relevant facts only.",
            ]), summary: "When the body reaches an agent."),
            .init("updated", .string,
                  summary: "YYYY-MM-DD: when it was last known to hold."),
            .init("related", .array(.string),
                  summary: "Other entries by identifier, such as \"people.sam.role\"; each must exist."),
        ], summary: "One thing agents may know about the owner's world.")
    }
}

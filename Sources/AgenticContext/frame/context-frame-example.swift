import Foundation

public extension ContextFrame {
    /// A complete `context/business.frame` for a made-up business:
    /// `agentic example context` prints it. The tests read it, so it stays
    /// valid.
    static let example = #"""
        import Context;

        // Entries are identified by this file's path and their binding name:
        // in context/business.frame, `let overview` is business.overview.
        // Agents see the title and summary, and read the body when needed.

        let overview: Entry = .{
            .title = "What the business does",
            .summary = "A two-person practice for home visits and workshops; who it serves and where.",
            .tags = ["business"],
            .updated = "2026-01-15",
            .body = """
                Northbank Studio is a two-person practice offering home visits
                and small-group workshops in and around the city centre.
                Most clients find us through referrals.
                """,
        };

        let services: Entry = .{
            .title = "Services and prices",
            .summary = "What we offer, how long each takes, and what it costs.",
            .tags = ["business", "pricing"],
            .related = ["business.overview"],
            .body = """
                - Intake visit, 90 minutes: 120 euros.
                - Follow-up visit, 60 minutes: 85 euros.
                - Workshop, 2 hours, up to 8 people: 40 euros per person.
                Travel beyond 25 km is charged at 0.35 euros per km.
                """,
        };

        // Short facts every agent should have: in every agent's instructions.
        let voice: Entry = .{
            .title = "How we write to clients",
            .summary = "Informal but precise; first names; no exclamation marks.",
            .tags = ["business", "writing"],
            .load = .always,
            .body = """
                Write to clients by first name, informally but precisely.
                Keep replies short; no exclamation marks. Sign off with
                "Alex & Sam".
                """,
        };
        """#
}

public extension Context.Library {
    /// The `.always` entries as instructions; nil when there are none.
    var instructions: String? {
        let always = self.always
        guard !always.isEmpty else { return nil }
        let entries = always.map { item in
            "## \(item.entry.title) (\(item.id))\n\n\(item.entry.body.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        return """
            # About the owner's world

            Context the owner keeps for every agent. More is listed by context_index and read with context_read.

            \(entries.joined(separator: "\n\n"))
            """
    }
}

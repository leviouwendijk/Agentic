import Agentic
import AgenticSessions
import Foundation
import Testing

enum SessionSearchTestSuite {
    static let testSuite = TestSuite(
        "session-search",
        title: "search_sessions tests"
    ) {
        Test("search finds lines across sessions, newest first") {
            let context = ToolContext(services: try ToolServices().inserting(
                SearchCatalog() as any Sessions.CatalogReading
            ))
            let tool = Sessions.Tools.Search()

            let literal = try await tool.call(.init(query: "compaction"), in: context)
            try Expect.equal(
                literal.hits.map { "\($0.sessionID):\($0.eventID):\($0.line)" },
                ["new:u2:2", "old:u1:1"],
                "literal text matches case-insensitively, newest session first"
            )
            try Expect.equal(literal.hits.first?.text, "Compaction should keep pointers", "a hit is its line")

            let tools = try await tool.call(.init(query: "needle"), in: context)
            try Expect.equal(tools.hits.map(\.source), ["tool_result"], "tool results are searched")
            let messagesOnly = try await tool.call(.init(query: "needle", includeTools: false), in: context)
            try Expect.equal(messagesOnly.hits.count, 0, "unless left out")

            let pattern = try await tool.call(.init(pattern: "^plan \\d+$", sessionID: "old"), in: context)
            try Expect.equal(pattern.hits.map(\.text), ["plan 42"], "patterns match per line, within one session")

            let rendered = try Expect.notNil(tool.render(literal, input: .init(query: "compaction")), "renders")
            try Expect.true(
                rendered.contains("session new  \"New work\"\n  #0 user u2:2: Compaction should keep pointers"),
                "hits group by session and name their event"
            )

            do {
                _ = try await tool.call(.init(pattern: "plan("), in: context)
                try Expect.true(false, "an invalid pattern is refused")
            } catch let error as Sessions.SearchError {
                try Expect.equal(error, .pattern("plan("), "with the pattern named")
            }
        }
    }
}

private struct SearchCatalog: Sessions.CatalogReading {
    func summary(_ id: String, _ title: String, updated: TimeInterval) -> Sessions.Summary {
        .init(
            metadata: .init(sessionID: id, updatedAt: Date(timeIntervalSince1970: updated), title: title),
            hasCheckpoint: false, hasTranscript: true, hasApprovals: false, artifactCount: 0
        )
    }

    func sessions(statuses _: [Sessions.Status], includeArchived _: Bool) async throws -> [Sessions.Summary] {
        [summary("old", "Old work", updated: 1), summary("new", "New work", updated: 2)]
    }

    func branches(parentSessionID _: String) async throws -> [Sessions.Summary] { [] }

    func session(id: String) async throws -> Sessions.Summary {
        summary(id, id == "old" ? "Old work" : "New work", updated: id == "old" ? 1 : 2)
    }

    func inspection(sessionID _: String) async throws -> Sessions.Inspection {
        throw CancellationError()
    }

    func transcript(sessionID: String) async throws -> [TranscriptEvent] {
        if sessionID == "old" {
            let call = FunctionCall(id: "c1", name: "read_file", input: .object([:]))
            return [
                .message(.init(id: "u1", role: .user, content: .init(text: "compaction later\nplan 42"))),
                .call(call),
                .result(.init(call: call.reference, output: .string("the needle is here"))),
            ]
        }
        return [
            .message(.init(id: "u2", role: .user, content: .init(text: "First line\nCompaction should keep pointers"))),
        ]
    }

    func approvals(sessionID _: String) async throws -> [Sessions.ApprovalEvent] { [] }

    func artifacts(sessionID _: String, kinds _: [AgentArtifactKind], latestFirst _: Bool) async throws -> [AgentArtifact] { [] }

    func artifact(sessionID _: String, id _: String) async throws -> AgentArtifactRecord {
        throw CancellationError()
    }
}

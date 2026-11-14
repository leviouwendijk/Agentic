import Agentic
import AgenticTasks
import Foundation
import Testing

/// The task tools resolve their manager and session scope from trusted
/// services, so the domain installs them without host-specific construction.
func runTaskLifecycleSmoke() async throws {
    let tasksdir = FileManager.default.temporaryDirectory
        .appendingPathComponent("agentic-task-lifecycle-\(UUID().uuidString)")
    defer {
        try? FileManager.default.removeItem(at: tasksdir)
    }

    let manager = AgentTaskManager(
        store: FileAgentTaskStore(tasksdir: tasksdir)
    )
    let context = ToolContext(
        services: try ToolServices()
            .inserting(manager)
            .inserting(AgentTaskScope(sessionID: "session.a"))
    )

    let contract = AgentTaskContract(
        objective: "Rename the field without changing its JSON key.",
        writeScope: ["Sources/Model/record.swift"],
        constraints: [
            .init(statement: "JSON key stays `user_id`.", provenance: .user_instruction),
        ],
        acceptance: ["Decoding an existing fixture still succeeds."]
    )

    let upstream = try await Tasks.Tools.CreateTask().call(
        .init(subject: "Change the declaration", contract: contract),
        in: context
    ).task
    let downstream = try await Tasks.Tools.CreateTask().call(
        .init(subject: "Update call sites", blockedBy: [upstream.id]),
        in: context
    ).task

    try Expect.equal(upstream.sessionID, "session.a", "task_create stamps the host session")
    try Expect.equal(upstream.contract, contract, "the typed contract persists")
    try Expect.true(downstream.isBlocked, "dependents start blocked")

    let submitted = try await Tasks.Tools.RecordAttempt().call(
        .init(
            id: upstream.id,
            owner: "worker",
            report: .init(
                summary: "Renamed the stored property.",
                changedFiles: ["Sources/Model/record.swift"],
                mutationState: .applied,
                contractConflicts: ["A second decoder also reads the key."]
            )
        ),
        in: context
    ).task
    try Expect.equal(submitted.status, .awaiting_acceptance, "a report never completes the task")
    try Expect.true(
        try await manager.get(downstream.id).isBlocked,
        "a submitted attempt does not unblock dependents"
    )

    let rejected = try await Tasks.Tools.RejectTask().call(
        .init(id: upstream.id, note: "Cover the second decoder."),
        in: context
    ).task
    try Expect.equal(rejected.status, .pending, "rejection returns the task for retry")
    try Expect.equal(rejected.latestAttempt?.outcome, .rejected, "the attempt keeps its outcome")
    try Expect.equal(
        rejected.latestAttempt?.decisionNote,
        "Cover the second decoder.",
        "the rejection note travels with the attempt"
    )

    _ = try await Tasks.Tools.RecordAttempt().call(
        .init(id: upstream.id, report: .init(summary: "Covered both decoders.", mutationState: .applied)),
        in: context
    )
    let accepted = try await Tasks.Tools.AcceptTask().call(
        .init(id: upstream.id),
        in: context
    ).task
    try Expect.equal(accepted.status, .completed, "acceptance completes the task")
    try Expect.equal(accepted.attempts.count, 2, "both attempts are retained")
    try Expect.true(
        try await manager.get(downstream.id).isReady,
        "acceptance unblocks dependents"
    )

    var rejectedAgain = false
    do {
        _ = try await manager.accept(id: upstream.id)
    } catch AgentTaskError.noSubmittedAttempt {
        rejectedAgain = true
    }
    try Expect.true(rejectedAgain, "an accepted task has nothing left to accept")

    _ = try await manager.create(subject: "Elsewhere", sessionID: "session.b")
    let scoped = try await Tasks.Tools.ListTasks().call(.init(), in: context)
    let everything = try await Tasks.Tools.ListTasks().call(.init(allSessions: true), in: context)
    try Expect.equal(scoped.count, 2, "task_list defaults to the current session")
    try Expect.equal(everything.count, 3, "allSessions widens the listing")

    let legacy = try JSONDecoder().decode(
        AgentTask.self,
        from: Data(
            #"{"id":"legacy","subject":"Old","description":"","status":"pending","blockedBy":[],"createdAt":0,"updatedAt":0,"metadata":{}}"#.utf8
        )
    )
    try Expect.true(
        legacy.contract == nil && legacy.attempts.isEmpty,
        "task files written before contracts still decode"
    )

    let sparse = try JSONDecoder().decode(
        Tasks.Assignment.self,
        from: Data(#"{"contract":{"objective":"Inspect only."}}"#.utf8)
    )
    try Expect.true(
        sparse.task == nil && sparse.contract.writeScope.isEmpty,
        "a model-written assignment may omit empty lists"
    )
}

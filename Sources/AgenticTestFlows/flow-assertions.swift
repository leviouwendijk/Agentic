import Agentic
import TestFlows

func assertCompleted(
    result: AgentRunResult,
    checkpoint: AgentHistoryCheckpoint,
    expectedText: String,
    expectedEvents: [AgentRunEvent.Kind]
) throws {
    try Expect.equal(
        result.response?.message.content.text,
        expectedText,
        "result.response.text"
    )

    try Expect.equal(
        checkpoint.phase,
        .completed,
        "checkpoint.phase"
    )

    try Expect.equal(
        checkpoint.partialResponse?.message.content.text,
        nil,
        "checkpoint.partialResponse.text"
    )

    try assertHasEvents(
        result.events,
        expectedEvents
    )
}

func assertHasEvents(
    _ events: [AgentRunEvent],
    _ expected: [AgentRunEvent.Kind]
) throws {
    try Expect.containsOrdered(
        events.map(\.kind),
        expected,
        "events"
    )
}

func flowDiagnostics(
    response: String? = nil,
    partial: String? = nil,
    checkpoint: AgentHistoryCheckpoint,
    events: [AgentRunEvent]
) -> [TestFlowDiagnostic] {
    var diagnostics: [TestFlowDiagnostic] = []

    if let response {
        diagnostics.append(
            .field(
                "response",
                response
            )
        )
    }

    if let partial {
        diagnostics.append(
            .field(
                "partial",
                partial
            )
        )
    }

    diagnostics.append(
        .field(
            "phase",
            checkpoint.phase.rawValue
        )
    )
    diagnostics.append(
        .field(
            "events",
            eventNames(events)
        )
    )

    return diagnostics
}

func eventNames(
    _ events: [AgentRunEvent]
) -> String {
    events.map(\.kind.rawValue).joined(
        separator: ","
    )
}

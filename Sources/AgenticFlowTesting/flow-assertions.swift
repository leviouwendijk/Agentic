import Agentic

func assertCompleted(
    result: AgentRunResult,
    checkpoint: AgentHistoryCheckpoint,
    expectedText: String,
    expectedEvents: [AgentRunEvent.Kind]
) throws {
    try assertEqual(
        result.response?.message.content.text,
        expectedText,
        "result.response.text"
    )

    try assertEqual(
        checkpoint.phase,
        .completed,
        "checkpoint.phase"
    )

    try assertEqual(
        checkpoint.partialResponse?.message.content.text,
        nil,
        "checkpoint.partialResponse.text"
    )

    try assertHasEvents(
        result.events,
        expectedEvents
    )
}

func assertEqual<T: Equatable>(
    _ actual: T,
    _ expected: T,
    _ label: String
) throws {
    guard actual == expected else {
        throw FlowTestError.assertionFailed(
            "\(label): expected '\(expected)', got '\(actual)'"
        )
    }
}

func assertHasEvents(
    _ events: [AgentRunEvent],
    _ expected: [AgentRunEvent.Kind]
) throws {
    let actualKinds = events.map(\.kind)
    var searchStart = actualKinds.startIndex

    for expectedKind in expected {
        guard let index = actualKinds[searchStart...].firstIndex(of: expectedKind) else {
            throw FlowTestError.assertionFailed(
                "missing event '\(expectedKind.rawValue)' in ordered events '\(eventNames(events))'"
            )
        }

        searchStart = actualKinds.index(
            after: index
        )
    }
}

func eventNames(
    _ events: [AgentRunEvent]
) -> String {
    events.map(\.kind.rawValue).joined(
        separator: ","
    )
}

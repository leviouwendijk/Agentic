import Agentic

struct MockStreamBatch: Sendable {
    var events: [AgentStreamEvent]
    var error: FlowTestError?
    var nanosecondsBetweenEvents: UInt64

    init(
        events: [AgentStreamEvent],
        error: FlowTestError? = nil,
        nanosecondsBetweenEvents: UInt64 = 0
    ) {
        self.events = events
        self.error = error
        self.nanosecondsBetweenEvents = nanosecondsBetweenEvents
    }
}

import Agentic
import Foundation

struct FlowHarness {
    let name: String
    let sessionID: String
    let historyStore: FileHistoryStore
    let runner: AgentRunner

    init(
        name: String,
        delivery: AgentModelResponseDelivery,
        maximumIterations: Int,
        adapter: MockModelAdapter,
        toolRegistry: ToolRegistry = .init()
    ) async throws {
        self.name = name
        self.sessionID = "flowtest-\(name)"
        self.historyStore = FileHistoryStore(
            sessionsdir: Self.historyDirectory()
        )

        try await historyStore.deleteCheckpoint(
            sessionID: sessionID
        )

        self.runner = AgentRunner(
            adapter: adapter,
            configuration: .init(
                maximumIterations: maximumIterations,
                historyPersistenceMode: .checkpointmutation,
                responseDelivery: delivery,
                streamCheckpointPolicy: .init(
                    eventInterval: 1,
                    characterInterval: 1,
                    minimumSecondsBetweenCheckpoints: 0
                )
            ),
            toolRegistry: toolRegistry,
            historyStore: historyStore
        )
    }

    func checkpoint() async throws -> AgentHistoryCheckpoint {
        guard let checkpoint = try await historyStore.loadCheckpoint(
            sessionID: sessionID
        ) else {
            throw FlowTestError.unexpectedResult(
                "missing checkpoint for session '\(sessionID)'"
            )
        }

        return checkpoint
    }

    private static func historyDirectory() -> URL {
        FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "agentic-flowtest-history",
                isDirectory: true
            )
    }
}

import Agentic
import AgenticStandard
import Testing

extension ProgramsFlowTesting {
    static func runProgramUserInputContext()
        async throws
        -> [TestDiagnostic]
    {
        let request = try UserInputRequest(
            prompt: "Provide a fixture value."
        )
        let expected = try UserInputResponse(
            answer: .text(
                "fixture"
            ),
            for: request
        )
        let userInput = RecordingProgramUserInput(
            response: expected
        )
        let context = ProgramContext(
            userInput: userInput
        )
        let observed = try await context.ask(
            request
        )
        let recordedRequests = await userInput.recordedRequests()

        try Expect.equal(
            recordedRequests.count,
            1,
            "Program user-input double records the delegated request"
        )

        try Expect.equal(
            observed,
            expected,
            "Program context delegates native user input through its semantic interaction port"
        )

        var unavailable = false

        do {
            _ = try await ProgramContext().ask(
                request
            )
        } catch ProgramContextError.userInputUnavailable {
            unavailable = true
        }

        try Expect.equal(
            unavailable,
            true,
            "Program context fails explicitly when native user input is unavailable"
        )

        return [
            .field(
                "answer",
                String(
                    describing: observed.answer
                )
            ),
            .field(
                "recorded_requests",
                String(recordedRequests.count)
            ),
            .field(
                "unavailable",
                String(unavailable)
            ),
        ]
    }
}

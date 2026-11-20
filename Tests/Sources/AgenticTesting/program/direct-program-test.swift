import Agentic

public enum DirectProgramTest {
    public static func run<ProgramType: Program>(
        _ program: ProgramType,
        input: ProgramType.Input,
        context: ProgramContext = .init()
    ) async throws -> ProgramTestResult<ProgramType> {
        let output = try await program.run(
            input,
            in: context
        )

        return ProgramTestResult(
            definition: ProgramType.definition,
            input: input,
            output: output,
            metadata: context.metadata
        )
    }
}

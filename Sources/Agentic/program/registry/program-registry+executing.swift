
extension ProgramRegistry: ProgramExecuting {
    public func execute<ProgramType: Program>(
        _ program: ProgramType.Type,
        input: ProgramType.Input,
        in context: ProgramContext
    ) async throws -> ProgramType.Output {
        try await run(
            program,
            input: input,
            in: context
        )
    }
}

public protocol Program: Capability
where DefinitionType == ProgramDefinition
{

    func run(
        _ input: Input,
        in context: ProgramContext
    ) async throws -> Output
}

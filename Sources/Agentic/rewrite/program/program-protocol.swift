public protocol Program: SemanticContract {
    static var definition: ProgramDefinition { get }

    func run(
        _ input: Input,
        in context: ProgramContext
    ) async throws -> Output
}

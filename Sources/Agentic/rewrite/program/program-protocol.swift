public protocol Program: Producer {
    static var definition: ProgramDefinition { get }

    func run(
        _ input: Input,
        in context: ProgramContext
    ) async throws -> Output
}

import Agentic

public struct ProgramTestResult<ProgramType: Program>: Sendable {
    public let definition: ProgramDefinition
    public let input: ProgramType.Input
    public let output: ProgramType.Output
    public let metadata: [String: String]

    public init(
        definition: ProgramDefinition,
        input: ProgramType.Input,
        output: ProgramType.Output,
        metadata: [String: String]
    ) {
        self.definition = definition
        self.input = input
        self.output = output
        self.metadata = metadata
    }
}

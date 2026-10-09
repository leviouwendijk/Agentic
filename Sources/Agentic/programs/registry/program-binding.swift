import Primitives

/// Registry-facing executable representation of one typed Program.
///
/// Registration captures the concrete Program/Input/Output types once. Dynamic
/// registry storage thereafter operates on JSONValue only at this explicit
/// lowering boundary while authored Programs remain typed.
public struct ProgramBinding: CapabilityBinding {
    public var reference: CapabilityReference {
        .program(definition.identifier)
    }
    public let definition: ProgramDefinition
    public let capabilityContract: CapabilityContract

    private let runHandler:
        @Sendable (
            JSONValue,
            ProgramContext
        ) async throws -> JSONValue

    public init<ProgramType: Program>(
        _ program: ProgramType
    ) {
        self.definition = ProgramType.definition
        self.capabilityContract = ProgramType.contract
        self.runHandler = { input, context in
            let decoded = try input.decode(
                ProgramType.Input.self
            )
            let output = try await program.run(
                decoded,
                in: context
            )

            return try JSONValue.encoding(
                output
            )
        }
    }

    public var identifier: ProgramIdentifier {
        definition.identifier
    }

    public func run(
        input: JSONValue,
        in context: ProgramContext
    ) async throws -> JSONValue {
        try await runHandler(
            input,
            context
        )
    }
}

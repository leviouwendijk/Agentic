public enum ProgramContextError:
    Error,
    Sendable,
    Equatable
{
    case inferenceUnavailable
    case toolInvocationUnavailable
    case programInvocationUnavailable
    case userInputUnavailable
    case artifactStorageUnavailable
}

public protocol ProgramInferenceExecuting: Sendable {
    func infer<
        ProgramType: Program,
        InferenceType: Inference
    >(
        _ site: InferenceSite<
            ProgramType,
            InferenceType
        >,
        input: InferenceType.Input
    ) async throws -> InferenceType.Output
}

public protocol ProgramToolExecuting: Sendable {
    func execute<Input, Output>(
        _ identifier: ToolIdentifier,
        input: Input,
        as output: Output.Type
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable

    /// The tools a program may invoke, described as the model's tool definitions
    /// describe them, with their domains. A program that composes tools at run time
    /// (a Loa run) reads its catalog here.
    func toolCatalog() async -> ProgramToolCatalog
}

public extension ProgramToolExecuting {
    func toolCatalog() async -> ProgramToolCatalog {
        .init()
    }
}

/// The tools a program may invoke and the domains they belong to.
public struct ProgramToolCatalog: Sendable {
    public let tools: [ToolDescriptor]
    public let domains: [DomainDefinition]

    public init(
        tools: [ToolDescriptor] = [],
        domains: [DomainDefinition] = []
    ) {
        self.tools = tools
        self.domains = domains
    }
}

public protocol ProgramExecuting: Sendable {
    func execute<ProgramType: Program>(
        _ program: ProgramType.Type,
        input: ProgramType.Input,
        in context: ProgramContext
    ) async throws -> ProgramType.Output
}

public protocol UserInputProviding: Sendable {
    func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse
}

public struct ProgramContext: Sendable {
    private let inference: (any ProgramInferenceExecuting)?
    private let tools: (any ProgramToolExecuting)?
    private let programs: (any ProgramExecuting)?
    private let userInput: (any UserInputProviding)?
    private let artifactStore: (any AgentArtifactStore)?

    public let metadata: [String: String]

    public init(
        inference: (any ProgramInferenceExecuting)? = nil,
        tools: (any ProgramToolExecuting)? = nil,
        programs: (any ProgramExecuting)? = nil,
        userInput: (any UserInputProviding)? = nil,
        artifacts: (any AgentArtifactStore)? = nil,
        metadata: [String: String] = [:]
    ) {
        self.inference = inference
        self.tools = tools
        self.programs = programs
        self.userInput = userInput
        self.artifactStore = artifacts
        self.metadata = metadata
    }

    public func infer<
        ProgramType: Program,
        InferenceType: Inference
    >(
        _ site: InferenceSite<
            ProgramType,
            InferenceType
        >,
        input: InferenceType.Input
    ) async throws -> InferenceType.Output {
        guard let inference else {
            throw ProgramContextError.inferenceUnavailable
        }

        return try await inference.infer(
            site,
            input: input
        )
    }

    public func invoke<Input, Output>(
        _ identifier: ToolIdentifier,
        input: Input,
        as output: Output.Type
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable
    {
        guard let tools else {
            throw ProgramContextError.toolInvocationUnavailable
        }

        return try await tools.execute(
            identifier,
            input: input,
            as: output
        )
    }

    /// The tools this program may invoke; empty when the context runs no tools.
    public func toolCatalog() async -> ProgramToolCatalog {
        await tools?.toolCatalog() ?? .init()
    }

    public func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse {
        guard let userInput else {
            throw ProgramContextError.userInputUnavailable
        }

        return try await userInput.ask(
            request
        )
    }

    public func run<ProgramType: Program>(
        _ program: ProgramType.Type,
        input: ProgramType.Input
    ) async throws -> ProgramType.Output {
        guard let programs else {
            throw ProgramContextError.programInvocationUnavailable
        }

        return try await programs.execute(
            program,
            input: input,
            in: self
        )
    }

    public func requireArtifactStore() throws -> any AgentArtifactStore {
        guard let artifactStore else {
            throw ProgramContextError.artifactStorageUnavailable
        }

        return artifactStore
    }
}

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

public protocol InferenceInvoking: Sendable {
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

public protocol ProgramToolInvoking: Sendable {
    func invoke<Input, Output>(
        _ identifier: ToolIdentifier,
        input: Input,
        as output: Output.Type
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable
}

public protocol ProgramInvoking: Sendable {
    func invoke<ProgramType: Program>(
        _ program: ProgramType.Type,
        input: ProgramType.Input,
        in context: ProgramContext
    ) async throws -> ProgramType.Output
}

public protocol ProgramUserInputInvoking: Sendable {
    func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse
}

public struct ProgramContext: Sendable {
    private let inferenceInvoker: (any InferenceInvoking)?
    private let toolInvoker: (any ProgramToolInvoking)?
    private let programInvoker: (any ProgramInvoking)?
    private let userInputInvoker: (any ProgramUserInputInvoking)?
    private let artifactStore: (any AgentArtifactStore)?

    public let metadata: [String: String]

    public init(
        inference: (any InferenceInvoking)? = nil,
        tools: (any ProgramToolInvoking)? = nil,
        programs: (any ProgramInvoking)? = nil,
        userInput: (any ProgramUserInputInvoking)? = nil,
        artifacts: (any AgentArtifactStore)? = nil,
        metadata: [String: String] = [:]
    ) {
        self.inferenceInvoker = inference
        self.toolInvoker = tools
        self.programInvoker = programs
        self.userInputInvoker = userInput
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
        guard let inferenceInvoker else {
            throw ProgramContextError.inferenceUnavailable
        }

        return try await inferenceInvoker.infer(
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
        guard let toolInvoker else {
            throw ProgramContextError.toolInvocationUnavailable
        }

        return try await toolInvoker.invoke(
            identifier,
            input: input,
            as: output
        )
    }

    public func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse {
        guard let userInputInvoker else {
            throw ProgramContextError.userInputUnavailable
        }

        return try await userInputInvoker.ask(
            request
        )
    }

    public func run<ProgramType: Program>(
        _ program: ProgramType.Type,
        input: ProgramType.Input
    ) async throws -> ProgramType.Output {
        guard let programInvoker else {
            throw ProgramContextError.programInvocationUnavailable
        }

        return try await programInvoker.invoke(
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

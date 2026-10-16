import Agentic

/// Connects the authored preparation Program to the opt-in harness seam.
/// ProgramContext supplies the inference invoker, if one is installed.
public struct ContextProgramPreparation: Context.PreparationSelecting {
    public let program: ContextPreparationProgram
    public let context: ProgramContext

    public init(program: ContextPreparationProgram, context: ProgramContext) {
        self.program = program
        self.context = context
    }

    public func allocations(for request: AgentRequest) async throws -> [Context.Allocation] {
        guard let message = request.messages.last(where: { $0.role == .user }) else {
            throw ContextInferenceError.noCurrentUserMessage
        }
        let query = String(message.content.text.prefix(2_000))
        let ids = try await program.run(query, in: context)
        return try await program.allocations(ids: ids, query: query)
    }
}

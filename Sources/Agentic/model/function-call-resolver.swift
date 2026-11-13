public protocol FunctionCallResolver:
    Sendable
{
    func resolve(
        _ call: FunctionCall
    ) async throws -> FunctionCall.Response
}

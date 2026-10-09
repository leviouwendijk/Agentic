/// Canonical authored Tool contract.
///
/// `preflight` and `call` receive an immutable `ToolContext` describing the
/// invocation environment (optional workspace, the application semantic
/// Catalog, and the live Agent capability state). Tools remain application-
/// level and reusable; agent/session state is reached only through the
/// supplied context at invocation time.
public protocol Tool:
    Capability,
    ToolRecovery,
    ToolProjection
where DefinitionType == ToolDefinition
{

    func preflight(
        _ input: Input,
        in context: ToolContext
    ) async throws -> ToolPreflight

    func call(
        _ input: Input,
        in context: ToolContext
    ) async throws -> Output
}

public extension Tool {
    func preflight(
        _ input: Input,
        in _: ToolContext
    ) async throws -> ToolPreflight {
        _ = input

        return ToolPreflight(
            tool: Self.definition.identifier,
            risk: Self.definition.risk,
            summary: Self.definition.purpose,
            sideEffects: Self.definition.risk.defaultSideEffects
        )
    }
}

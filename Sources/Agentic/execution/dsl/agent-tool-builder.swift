/// Builds typed executable bindings directly; registration never retains
/// a second closure-backed representation of tools.
///
/// Opaque AgentToolProvider instances remain available through explicit
/// ToolRegistry.register(from:) / Agentic.tool.registry(toolProviders:).
@resultBuilder
public enum AgentToolBuilder {
    public static func buildBlock(
        _ components: [ToolBinding]...
    ) -> [ToolBinding] {
        components.flatMap { $0 }
    }

    public static func buildExpression<T: Tool>(
        _ tool: T
    ) -> [ToolBinding] {
        [ToolBinding(tool)]
    }

    public static func buildExpression(
        _ binding: ToolBinding
    ) -> [ToolBinding] {
        [binding]
    }

    public static func buildExpression(
        _ bindings: [ToolBinding]
    ) -> [ToolBinding] {
        bindings
    }

    public static func buildOptional(
        _ component: [ToolBinding]?
    ) -> [ToolBinding] {
        component ?? []
    }

    public static func buildEither(
        first component: [ToolBinding]
    ) -> [ToolBinding] {
        component
    }

    public static func buildEither(
        second component: [ToolBinding]
    ) -> [ToolBinding] {
        component
    }

    public static func buildArray(
        _ components: [[ToolBinding]]
    ) -> [ToolBinding] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(
        _ component: [ToolBinding]
    ) -> [ToolBinding] {
        component
    }
}

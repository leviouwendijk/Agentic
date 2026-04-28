public struct AgentAdvisorToolSet: AgentToolSet {
    public var provider: any AgentAdvisorModelProviding
    public var configuration: AgentAdvisorToolConfiguration

    public init(
        provider: any AgentAdvisorModelProviding,
        configuration: AgentAdvisorToolConfiguration = .init()
    ) {
        self.provider = provider
        self.configuration = configuration
    }

    public init(
        broker: AgentModelBroker,
        configuration: AgentAdvisorToolConfiguration = .init()
    ) {
        self.init(
            provider: broker,
            configuration: configuration
        )
    }

    public func register(
        into registry: inout ToolRegistry
    ) throws {
        try registry.register {
            AgentAdvisorTool(
                provider: provider,
                configuration: configuration
            )
        }
    }
}

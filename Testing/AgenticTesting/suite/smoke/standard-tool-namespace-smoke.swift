import AgenticStandard

func runStandardToolNamespaceSmoke() throws {
    ContractProof.tool(
        Standard.Tools.AgentAdvisor.self
    )

    try ContractProof.identifier(
        Standard.Tools.AgentAdvisor.definition.identifier.rawValue,
        expected: "advisor_ask"
    )
}

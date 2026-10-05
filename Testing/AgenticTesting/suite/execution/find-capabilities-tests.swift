import Agentic
import AgenticStandard
import Testing

extension ExecutionTesting {
    static func runFindCapabilities()
        async throws
        -> [TestDiagnostic]
    {
        let namespace = Namespace(
            rawValue: "fixture"
        )
        let hiddenTool = ToolDefinition(
            identifier: "fixture.hidden_tool",
            purpose: "Hidden Tool capability"
        )
        let unavailableTool = ToolDefinition(
            identifier: "fixture.hidden_unavailable_tool",
            purpose: "Hidden unavailable Tool capability"
        )
        let hiddenProgram = ProgramDefinition(
            identifier: "fixture.hidden_program",
            purpose: "Hidden Program capability"
        )
        let hiddenInference = InferenceDefinition(
            identifier: "fixture.hidden_inference",
            purpose: "Hidden Inference capability"
        )
        let hiddenAgent = AgentDefinition(
            identifier: "fixture.hidden_agent",
            purpose: "Hidden Agent capability"
        )
        let catalog = Catalog(
            domains: [
                DomainDefinition(
                    namespace: namespace
                ),
            ],
            entries: [
                .init(
                    namespace: namespace,
                    declaration: .tool(
                        hiddenTool
                    )
                ),
                .init(
                    namespace: namespace,
                    declaration: .tool(
                        unavailableTool
                    )
                ),
                .init(
                    namespace: namespace,
                    declaration: .program(
                        hiddenProgram
                    )
                ),
                .init(
                    namespace: namespace,
                    declaration: .inference(
                        hiddenInference
                    )
                ),
                .init(
                    namespace: namespace,
                    declaration: .agent(
                        hiddenAgent
                    )
                ),
            ]
        )
        let available = AgentCapabilitySet(
            tools: [
                hiddenTool.identifier,
            ],
            programs: [
                hiddenProgram.identifier,
            ],
            inferences: [
                hiddenInference.identifier,
            ],
            agents: [
                hiddenAgent.identifier,
            ]
        )
        let state = AgentCapabilityState(
            installed: available.union(
                .init(
                    tools: [
                        unavailableTool.identifier,
                    ]
                )
            ),
            available: available,
            visible: AgentCapabilitySet.none
        )
        let tool =
            Standard.Tools.FindCapabilities()
        let context = ToolContext(
            catalog: catalog,
            capabilities: state
        )

        let programOnly = try await tool.call(
            .init(
                kind: .program,
                domain: namespace.rawValue
            ),
            in: context
        )

        try Expect.equal(
            programOnly.entries.map(\.identifier),
            [
                hiddenProgram.identifier.rawValue,
            ],
            "kind/domain browsing returns only available matching capabilities"
        )

        let discovered = try await tool.call(
            .init(
                query: "hidden",
                maximumResults: 8
            ),
            in: context
        )
        let snapshot = await state.snapshot()

        try Expect.equal(
            discovered.entries.map(\.identifier).contains(
                unavailableTool.identifier.rawValue
            ),
            false,
            "discovery never returns installed-but-unavailable capabilities"
        )
        try Expect.equal(
            Set(
                discovered.entries.map(\.kind)
            ),
            Set(
                [
                    .tool,
                    .program,
                    .inference,
                    .agent,
                ]
            ),
            "one discovery Tool searches every first-class Agent capability kind"
        )
        try Expect.equal(
            snapshot.available,
            available,
            "discovery does not mutate Agent authority"
        )
        try Expect.equal(
            snapshot.visible,
            available,
            "matching available capabilities become visible"
        )

        return [
            .field(
                "returned",
                String(
                    discovered.returnedCount
                )
            ),
            .field(
                "visible_tools",
                String(
                    snapshot.visible.tools.count
                )
            ),
            .field(
                "visible_programs",
                String(
                    snapshot.visible.programs.count
                )
            ),
            .field(
                "visible_inferences",
                String(
                    snapshot.visible.inferences.count
                )
            ),
            .field(
                "visible_agents",
                String(
                    snapshot.visible.agents.count
                )
            ),
        ]
    }
}

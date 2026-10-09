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
        let hiddenAdapter = InferenceAdapterDefinition(
            identifier: "fixture.hidden_adapter"
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
                .init(
                    namespace: namespace,
                    declaration: .adapter(
                        hiddenAdapter
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
            capabilities: state,
            inspections: [
                .init(reference: .tool(hiddenTool.identifier), namespace: namespace.rawValue,
                      purpose: hiddenTool.purpose, input: .string("tool-input"), output: .null),
                .init(reference: .tool(unavailableTool.identifier), namespace: namespace.rawValue,
                      purpose: unavailableTool.purpose, input: .null, output: .null),
                .init(reference: .program(hiddenProgram.identifier), namespace: namespace.rawValue,
                      purpose: hiddenProgram.purpose, input: .string("program-input"), output: .string("program-output")),
                .init(reference: .inference(hiddenInference.identifier), namespace: namespace.rawValue,
                      purpose: hiddenInference.purpose, input: .null, output: .null),
                .init(reference: .agent(hiddenAgent.identifier), namespace: namespace.rawValue,
                      purpose: hiddenAgent.purpose, input: .null, output: .null)
            ]
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
            discovered.entries.map(\.identifier).contains(
                hiddenAdapter.identifier.rawValue
            ),
            false,
            "inference adapters cannot be discovered as Agent capabilities"
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
            .none,
            "find_capabilities must not modify direct model visibility"
        )

        let listed = try await Standard.Tools.ListCapabilities().call(
            .init(kind: .tool, maximumResults: 1), in: context
        )
        try Expect.equal(listed.total, 1,
            "list enumerates only available installed Tool bindings")
        let inspected = try await Standard.Tools.InspectCapability().call(
            .init(kind: .program, identifier: hiddenProgram.identifier.rawValue),
            in: context
        )
        try Expect.equal(inspected.input, .string("program-input"),
            "inspection returns the exact binding-provided input contract")
        try Expect.equal(inspected.output, .string("program-output"),
            "inspection returns the exact binding-provided output contract")
        try Expect.equal((await state.snapshot()).visible, .none,
            "list/find/inspect leave visibility unchanged")

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

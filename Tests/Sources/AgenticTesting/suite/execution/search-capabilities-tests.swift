import Agentic
import AgenticStandard
import Testing

extension ExecutionTesting {
    static func runSearchCapabilities()
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
            Standard.Tools.SearchCapabilities()
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
                kinds: [.program],
                domains: [namespace.rawValue]
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

        // Kinds are any of; fields combine. Nothing is among the tools here,
        // so `visible` matches none and `hidden` every one.
        let programsAndAgents = try await tool.call(
            .init(kinds: [.program, .agent], maximumResults: 8), in: context
        )
        try Expect.equal(
            Set(programsAndAgents.entries.map(\.kind)), [.program, .agent],
            "several kinds match any of them"
        )
        let visibleOnly = try await tool.call(.init(visibility: .visible, maximumResults: 8), in: context)
        try Expect.equal(visibleOnly.totalMatches, 0, "none is among the tools")
        let hiddenTools = try await tool.call(
            .init(kinds: [.tool], visibility: .hidden, maximumResults: 8), in: context
        )
        try Expect.equal(
            hiddenTools.entries.map(\.identifier), [hiddenTool.identifier.rawValue],
            "kind and visibility combine"
        )
        let privileged = try await tool.call(.init(risks: [.privileged], maximumResults: 8), in: context)
        try Expect.equal(privileged.totalMatches, 0, "a risk filter matches only declared levels")

        // Names a provider is sent: a tool keeps its identifier; other kinds
        // read as theirs behind their kind; a long one ends in a hash.
        try Expect.equal(CapabilityReference.tool(hiddenTool.identifier).providerName, "fixture.hidden_tool", "a tool keeps its name")
        try Expect.equal(
            CapabilityReference.program(hiddenProgram.identifier).providerName,
            "program_fixture_hidden_program",
            "a program's name reads as its identifier"
        )
        let long = CapabilityReference.agent(AgentIdentifier(rawValue: String(repeating: "worker.", count: 12)))
        try Expect.true(
            long.providerName.count == CapabilityReference.providerNameLimit && long.providerName.hasPrefix("agent_worker_"),
            "a long name is cut and hashed: \(long.providerName)"
        )
        try Expect.equal(long.hashedProviderName, long.providerName, "a cut name is already the hashed form")
        let program = CapabilityReference.program(hiddenProgram.identifier)
        try Expect.true(
            program.hashedProviderName.hasPrefix("program_fixture_hidden_program_")
                && program.hashedProviderName.count == "program_fixture_hidden_program_".count + 8,
            "the collision fallback ends in the hash: \(program.hashedProviderName)"
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
            "search_capabilities must not modify direct model visibility"
        )

        let listed = try await Standard.Tools.ListCapabilities().call(
            .init(kinds: [.tool], maximumResults: 1), in: context
        )
        try Expect.equal(listed.total, 1,
            "list enumerates only available installed Tool bindings")
        let page = try await Standard.Tools.ListCapabilities().call(
            .init(maximumResults: 2), in: context
        )
        try Expect.equal(
            Standard.Tools.ListCapabilities().render(page, input: .init(maximumResults: 2)),
            """
            1–2 of 4:
            fixture
              fixture.hidden_agent [agent] — Hidden Agent capability
              fixture.hidden_inference [inference] — Hidden Inference capability
            list_capabilities {"offset": 2} continues.
            """,
            "list renders one line per entry under its namespace and names the next page"
        )
        let inspected = try await Standard.Tools.InspectCapability().call(
            .init(kind: .program, identifier: hiddenProgram.identifier.rawValue),
            in: context
        )
        try Expect.equal(inspected.input, .string("program-input"),
            "inspection returns the exact binding-provided input contract")
        try Expect.equal(inspected.output, .string("program-output"),
            "inspection returns the exact binding-provided output contract")
        try Expect.equal((await state.snapshot()).visible, .none,
            "list/search/inspect leave visibility unchanged")

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

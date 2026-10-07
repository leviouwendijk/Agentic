import Agentic
import AgenticLinkerCatalogFixture
import Testing

private struct TypedCapabilityProgramFixture: Program {
    typealias Input = String
    typealias Output = String

    static let definition = ProgramDefinition(
        identifier: .init(
            rawValue: "fixture.typed_program"
        ),
        purpose: "Prove typed Program capability selection authoring."
    )

    func run(
        _ input: Input,
        in _: ProgramContext
    ) async throws -> Output {
        input
    }
}

private enum TypedCapabilityInferenceFixture: Inference {
    typealias Input = String
    typealias Output = String

    static let definition = InferenceDefinition(
        identifier: .init(
            rawValue: "fixture.typed_inference"
        ),
        purpose: "Prove typed Inference capability selection authoring."
    )
}

private enum TypedCapabilityAgentFixture: Agent {
    typealias Input = String
    typealias Output = String

    static let purpose =
        "Prove typed Agent capability selection authoring."

    static let definition = AgentDefinition(
        identifier: .init(
            rawValue: "fixture.typed_agent"
        ),
        purpose: purpose
    )
}

let capabilitySelectionCompositionFlows: [TestFlow] = [
    TestFlow(
        "agent-capability-selection-composition",
        tags: [
            "agentic",
            "agent",
            "capabilities",
            "composition",
        ]
    ) {
        let swift = Namespace(
            rawValue: "swift"
        )
        let git = Namespace(
            rawValue: "git"
        )

        let read = ToolIdentifier(
            rawValue: "read_file"
        )
        let mutate = ToolIdentifier(
            rawValue: "mutate_files"
        )
        let build = ToolIdentifier(
            rawValue: "swift_build"
        )

        let left = AgentCapabilitySelection<ToolIdentifier>(
            domains: [
                swift,
            ],
            members: [
                read,
                mutate,
            ],
            excluding: [
                mutate,
            ]
        )

        let right = AgentCapabilitySelection<ToolIdentifier>(
            domains: [
                swift,
                git,
            ],
            members: [
                mutate,
                build,
                read,
            ],
            excluding: [
                build,
            ]
        )

        let combined = left + right

        try Expect.equal(
            combined.domains,
            [
                swift,
                git,
            ],
            "selection composition preserves first-seen domain order without duplicates"
        )
        try Expect.equal(
            combined.members,
            [
                read,
                mutate,
                build,
            ],
            "selection composition unions explicit members without prematurely resolving exclusions"
        )
        try Expect.equal(
            combined.excluding,
            [
                mutate,
                build,
            ],
            "selection composition unions exclusions in stable first-seen order"
        )
        try Expect.equal(
            AgentCapabilitySelection<ToolIdentifier>.none + left,
            left,
            "none is the left identity for capability selections"
        )
        try Expect.equal(
            left + AgentCapabilitySelection<ToolIdentifier>.none,
            left,
            "none is the right identity for capability selections"
        )

        let typedTools = AgentCapabilitySelection<ToolIdentifier>(
            domains: [
                LinkerCatalogFixture.definition.namespace,
            ],
            members: [
                LinkerCatalogFixture.Tools.Alpha.self,
                LinkerCatalogFixture.Tools.Beta.self,
            ],
            excluding: [
                LinkerCatalogFixture.Tools.Beta.self,
            ]
        )

        try Expect.equal(
            typedTools.domains,
            [
                LinkerCatalogFixture.definition.namespace,
            ],
            "typed Tool selection preserves explicit domains"
        )
        try Expect.equal(
            typedTools.members,
            [
                LinkerCatalogFixture.Tools.Alpha.definition.identifier,
                LinkerCatalogFixture.Tools.Beta.definition.identifier,
            ],
            "typed Tool members lower to canonical Tool identifiers"
        )
        try Expect.equal(
            typedTools.excluding,
            [
                LinkerCatalogFixture.Tools.Beta.definition.identifier,
            ],
            "typed Tool exclusions lower to canonical Tool identifiers"
        )

        let typedProgram = AgentCapabilitySelection<ProgramIdentifier>(
            members: [
                TypedCapabilityProgramFixture.self,
            ],
            excluding: [
                TypedCapabilityProgramFixture.self,
            ]
        )

        try Expect.equal(
            typedProgram.members,
            [
                TypedCapabilityProgramFixture.definition.identifier,
            ],
            "typed Program members lower to canonical Program identifiers"
        )
        try Expect.equal(
            typedProgram.excluding,
            [
                TypedCapabilityProgramFixture.definition.identifier,
            ],
            "typed Program exclusions lower to canonical Program identifiers"
        )

        let typedInference = AgentCapabilitySelection<InferenceIdentifier>(
            members: [
                TypedCapabilityInferenceFixture.self,
            ],
            excluding: [
                TypedCapabilityInferenceFixture.self,
            ]
        )

        try Expect.equal(
            typedInference.members,
            [
                TypedCapabilityInferenceFixture.definition.identifier,
            ],
            "typed Inference members lower to canonical Inference identifiers"
        )
        try Expect.equal(
            typedInference.excluding,
            [
                TypedCapabilityInferenceFixture.definition.identifier,
            ],
            "typed Inference exclusions lower to canonical Inference identifiers"
        )

        let typedAgent = AgentCapabilitySelection<AgentIdentifier>(
            members: [
                TypedCapabilityAgentFixture.self,
            ],
            excluding: [
                TypedCapabilityAgentFixture.self,
            ]
        )

        try Expect.equal(
            typedAgent.members,
            [
                TypedCapabilityAgentFixture.definition.identifier,
            ],
            "typed Agent members lower to canonical Agent identifiers"
        )
        try Expect.equal(
            typedAgent.excluding,
            [
                TypedCapabilityAgentFixture.definition.identifier,
            ],
            "typed Agent exclusions lower to canonical Agent identifiers"
        )

        let typedPerKindDomainScope = AgentCapabilityScope(
            tools: .init(
                domains: [
                    LinkerCatalogFixture.self,
                ]
            ),
            programs: .init(
                domains: [
                    LinkerCatalogFixture.self,
                ]
            ),
            inferences: .init(
                domains: [
                    LinkerCatalogFixture.self,
                ]
            ),
            agents: .init(
                domains: [
                    LinkerCatalogFixture.self,
                ]
            )
        )

        let typedWholeDomainScope = AgentCapabilityScope(
            domains: [
                LinkerCatalogFixture.self,
            ]
        )

        try Expect.equal(
            typedWholeDomainScope,
            typedPerKindDomainScope,
            "whole-Domain capability scope lowers equivalently across Tool, Program, Inference, and Agent selections"
        )

        let typedWholeDomainWithMembers = AgentCapabilityScope(
            domains: [
                LinkerCatalogFixture.self,
            ],
            programs: .init(
                members: [
                    TypedCapabilityProgramFixture.self,
                ]
            ),
            inferences: .init(
                members: [
                    TypedCapabilityInferenceFixture.self,
                ]
            ),
            agents: .init(
                members: [
                    TypedCapabilityAgentFixture.self,
                ]
            )
        )

        try Expect.equal(
            typedWholeDomainWithMembers.tools.domains,
            [
                LinkerCatalogFixture.definition.namespace,
            ],
            "whole-Domain scope applies its namespace to Tool selection"
        )
        try Expect.equal(
            typedWholeDomainWithMembers.programs.domains,
            [
                LinkerCatalogFixture.definition.namespace,
            ],
            "whole-Domain scope applies its namespace to Program selection"
        )
        try Expect.equal(
            typedWholeDomainWithMembers.inferences.domains,
            [
                LinkerCatalogFixture.definition.namespace,
            ],
            "whole-Domain scope applies its namespace to Inference selection"
        )
        try Expect.equal(
            typedWholeDomainWithMembers.agents.domains,
            [
                LinkerCatalogFixture.definition.namespace,
            ],
            "whole-Domain scope applies its namespace to Agent selection"
        )
        try Expect.equal(
            typedWholeDomainWithMembers.programs.members,
            [
                TypedCapabilityProgramFixture.definition.identifier,
            ],
            "whole-Domain scope preserves explicit typed Program members"
        )
        try Expect.equal(
            typedWholeDomainWithMembers.inferences.members,
            [
                TypedCapabilityInferenceFixture.definition.identifier,
            ],
            "whole-Domain scope preserves explicit typed Inference members"
        )
        try Expect.equal(
            typedWholeDomainWithMembers.agents.members,
            [
                TypedCapabilityAgentFixture.definition.identifier,
            ],
            "whole-Domain scope preserves explicit typed Agent members"
        )

        let program = ProgramIdentifier(
            rawValue: "fixture.program"
        )
        let inference = InferenceIdentifier(
            rawValue: "fixture.inference"
        )
        let agent = AgentIdentifier(
            rawValue: "fixture.agent"
        )

        let capabilities = AgentCapabilities(
            available: .init(
                tools: .init(
                    members: [
                        read,
                    ]
                ),
                programs: .init(
                    members: [
                        program,
                    ]
                )
            ),
            visible: .init(
                tools: .init(
                    members: [
                        read,
                    ]
                )
            )
        ) + AgentCapabilities(
            available: .init(
                tools: .init(
                    domains: [
                        swift,
                    ],
                    members: [
                        build,
                    ]
                ),
                inferences: .init(
                    members: [
                        inference,
                    ]
                ),
                agents: .init(
                    members: [
                        agent,
                    ]
                )
            ),
            visible: .init(
                tools: .init(
                    members: [
                        build,
                    ]
                ),
                programs: .init(
                    members: [
                        program,
                    ]
                )
            )
        )

        try Expect.equal(
            capabilities.available.tools,
            AgentCapabilitySelection(
                domains: [
                    swift,
                ],
                members: [
                    read,
                    build,
                ]
            ),
            "available capability scope composes Tool selections component-wise"
        )
        try Expect.equal(
            capabilities.available.programs.members,
            [
                program,
            ],
            "available capability scope preserves Program selections"
        )
        try Expect.equal(
            capabilities.available.inferences.members,
            [
                inference,
            ],
            "available capability scope composes Inference selections"
        )
        try Expect.equal(
            capabilities.available.agents.members,
            [
                agent,
            ],
            "available capability scope composes delegated-Agent selections"
        )
        try Expect.equal(
            capabilities.visible.tools.members,
            [
                read,
                build,
            ],
            "visible capability scope composes independently from availability"
        )
        try Expect.equal(
            capabilities.visible.programs.members,
            [
                program,
            ],
            "visible capability scope may expose Programs independently"
        )

        var mutableCapabilities = capabilities
        mutableCapabilities.visible = .none

        try Expect.equal(
            mutableCapabilities.visible,
            .none,
            "AgentCapabilities visibility is mutable runtime-friendly state"
        )
        try Expect.equal(
            mutableCapabilities.available,
            capabilities.available,
            "mutating visibility does not mutate availability"
        )
        try Expect.equal(
            AgentCapabilities.none + capabilities,
            capabilities,
            "none is the left identity for AgentCapabilities"
        )
        try Expect.equal(
            capabilities + AgentCapabilities.none,
            capabilities,
            "none is the right identity for AgentCapabilities"
        )

        return [
            .field(
                "domains",
                String(combined.domains.count)
            ),
            .field(
                "members",
                String(combined.members.count)
            ),
            .field(
                "excluding",
                String(combined.excluding.count)
            ),
        ]
    },
    TestFlow(
        "agent-capability-selection-resolution",
        tags: [
            "agentic",
            "agent",
            "capabilities",
            "catalog",
            "resolution",
            "provenance",
        ]
    ) {
        let namespace = Namespace(
            rawValue: "fixture.capability_resolution"
        )
        let domainTool = ToolIdentifier(
            rawValue: "fixture.domain_tool"
        )
        let excludedTool = ToolIdentifier(
            rawValue: "fixture.excluded_tool"
        )
        let explicitTool = ToolIdentifier(
            rawValue: "fixture.explicit_tool"
        )
        let unknownTool = ToolIdentifier(
            rawValue: "fixture.unknown_tool"
        )
        let program = ProgramIdentifier(
            rawValue: "fixture.domain_program"
        )
        let inference = InferenceIdentifier(
            rawValue: "fixture.domain_inference"
        )
        let agent = AgentIdentifier(
            rawValue: "fixture.domain_agent"
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
                        ToolDefinition(
                            identifier: domainTool,
                            purpose: "Domain Tool"
                        )
                    )
                ),
                .init(
                    namespace: namespace,
                    declaration: .tool(
                        ToolDefinition(
                            identifier: excludedTool,
                            purpose: "Excluded Tool"
                        )
                    )
                ),
                .init(
                    declaration: .tool(
                        ToolDefinition(
                            identifier: explicitTool,
                            purpose: "Explicit Tool"
                        )
                    )
                ),
                .init(
                    namespace: namespace,
                    declaration: .program(
                        ProgramDefinition(
                            identifier: program,
                            purpose: "Domain Program"
                        )
                    )
                ),
                .init(
                    namespace: namespace,
                    declaration: .inference(
                        InferenceDefinition(
                            identifier: inference,
                            purpose: "Domain Inference"
                        )
                    )
                ),
                .init(
                    namespace: namespace,
                    declaration: .agent(
                        AgentDefinition(
                            identifier: agent,
                            purpose: "Domain Agent"
                        )
                    )
                ),
            ]
        )

        let resolved = catalog.resolve(
            AgentCapabilityScope(
                tools: .init(
                    domains: [
                        namespace,
                    ],
                    members: [
                        explicitTool,
                        unknownTool,
                    ],
                    excluding: [
                        excludedTool,
                    ]
                ),
                programs: .init(
                    domains: [
                        namespace,
                    ]
                ),
                inferences: .init(
                    domains: [
                        namespace,
                    ]
                ),
                agents: .init(
                    domains: [
                        namespace,
                    ]
                )
            )
        )

        try Expect.equal(
            resolved.tools,
            [
                explicitTool,
                unknownTool,
                domainTool,
            ],
            "explicit members survive semantic resolution, selected Domain members expand, and exclusions win"
        )
        try Expect.equal(
            resolved.programs,
            [
                program,
            ],
            "selected Domain Programs resolve"
        )
        try Expect.equal(
            resolved.inferences,
            [
                inference,
            ],
            "selected Domain Inferences resolve"
        )
        try Expect.equal(
            resolved.agents,
            [
                agent,
            ],
            "selected Domain Agents resolve"
        )
        try Expect.equal(
            catalog.declarations,
            catalog.entries.map(\.declaration),
            "declarations remains the compatibility projection of Catalog entries"
        )
        try Expect.equal(
            AgentCapabilitySet.none,
            AgentCapabilitySet(),
            "AgentCapabilitySet.none is empty"
        )

        let linkerCatalog =
            LinkerCatalogFixture.catalog

        try Expect.equal(
            linkerCatalog.entries.isEmpty,
            false,
            "linker-derived Domain catalogs expose entries"
        )
        try Expect.equal(
            linkerCatalog.entries.allSatisfy { entry in
                entry.namespace
                    == LinkerCatalogFixture.namespace
            },
            true,
            "linker-derived entries retain their Domain namespace"
        )

        let unscopedCollision =
            Catalog.unscoped.entries.first { entry in
                guard case .tool(let definition) =
                    entry.declaration
                else {
                    return false
                }

                return definition.identifier.rawValue
                    == "unscoped_standard_collision"
            }

        try Expect.equal(
            unscopedCollision != nil,
            true,
            "the unscoped linker fixture remains discoverable"
        )

        if let unscopedCollision {
            try Expect.equal(
                unscopedCollision.namespace == nil,
                true,
                "unscoped declarations retain nil namespace provenance"
            )
        }

        return [
            .field(
                "tools",
                String(resolved.tools.count)
            ),
            .field(
                "linker_entries",
                String(linkerCatalog.entries.count)
            ),
        ]
    },
]

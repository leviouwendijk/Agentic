import Agentic
import AgenticLinkerCatalogFixture
import Testing

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

import Agentic
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
        ) + AgentCapabilities(
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
        )

        try Expect.equal(
            capabilities.tools,
            AgentCapabilitySelection(
                domains: [
                    swift,
                ],
                members: [
                    read,
                    build,
                ]
            ),
            "AgentCapabilities composes tool selections component-wise"
        )
        try Expect.equal(
            capabilities.programs.members,
            [
                program,
            ],
            "AgentCapabilities preserves program selections"
        )
        try Expect.equal(
            capabilities.inferences.members,
            [
                inference,
            ],
            "AgentCapabilities composes inference selections"
        )
        try Expect.equal(
            capabilities.agents.members,
            [
                agent,
            ],
            "AgentCapabilities composes delegated-agent selections"
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
]

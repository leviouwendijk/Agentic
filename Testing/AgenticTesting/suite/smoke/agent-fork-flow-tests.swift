import Agentic
import AgenticLinkerCatalogFixture
import Testing

extension SmokeDomain.Agents {
    @Agent
    enum MacroSmokeFork: AgentFork {
        typealias Base = MacroSmokeAgent

        static let fork = AgentDerivation(
            instructions: .appending("Report what changed."),
            available: .domains(LinkerCatalogFixture.self),
            visible: .tools(LinkerCatalogFixture.Tools.Alpha.self),
            removing: .tools(SmokeDomain.Tools.MacroSmokeTool.self)
        )
    }

    @Agent
    enum MacroSmokeForkOfFork: AgentFork {
        typealias Base = MacroSmokeFork

        static let fork = AgentDerivation(
            purpose: "Prove a fork can be forked.",
            instructions: .prepending("Read first.")
        )
    }
}

let agentForkFlows: [TestFlow] = [
    TestFlow(
        "agent-fork-derivation",
        tags: [
            "agentic",
            "agent",
            "fork",
        ]
    ) {
        typealias Base = SmokeDomain.Agents.MacroSmokeAgent
        let fork = SmokeDomain.Agents.MacroSmokeFork.definition
        let tool = SmokeDomain.Tools.MacroSmokeTool.identifier
        let alpha = LinkerCatalogFixture.Tools.Alpha.definition.identifier

        try Expect.notEqual(
            fork.identifier,
            Base.definition.identifier,
            "a fork has its own identifier"
        )
        try Expect.equal(fork.purpose, Base.purpose, "purpose is inherited")
        try Expect.equal(fork.modelSelection, Base.modelSelection, "model selection is inherited")
        try Expect.equal(
            fork.instructions,
            "Respect observed evidence.\n\nInvestigate the fixture.\n\nReport what changed.",
            "appended instructions follow the base's"
        )
        try Expect.equal(
            fork.instructionSnapshot?.references.map(\.identifier),
            [SmokeDomain.Instructions.Debugging.definition.identifier],
            "the base's instruction references survive the fork"
        )
        try Expect.equal(
            fork.capabilities.available.tools.domains,
            [LinkerCatalogFixture.definition.namespace],
            "available domains are added"
        )
        try Expect.equal(fork.capabilities.visible.tools.members, [alpha], "removed members leave, added ones join")
        try Expect.equal(fork.capabilities.available.tools.excluding, [tool], "removed members are excluded")

        let nested = SmokeDomain.Agents.MacroSmokeForkOfFork.definition
        try Expect.equal(nested.purpose, "Prove a fork can be forked.", "purpose can be overridden")
        try Expect.equal(
            nested.instructions,
            "Read first.\n\nRespect observed evidence.\n\nInvestigate the fixture.\n\nReport what changed.",
            "a fork of a fork composes in order"
        )
        try Expect.equal(nested.capabilities, fork.capabilities, "capabilities carry through an unchanged fork")

        return [
            .field("fork", fork.identifier.rawValue),
            .field("nested", nested.identifier.rawValue),
        ]
    },
]

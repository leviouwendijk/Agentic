import Agentic
import TestFlows

extension AgenticFlowTesting {
    static func runCoreToolSetBuilderRegistration() async throws -> [TestFlowDiagnostic] {
        let fileRegistry = try Agentic.tool.registry {
            CoreFileToolSet()
        }

        try Expect.equal(
            fileRegistry.count,
            4,
            "core file tool set count"
        )

        _ = try Expect.notNil(
            fileRegistry.tool(
                named: "read_file"
            ),
            "core file tool set read_file"
        )

        _ = try Expect.notNil(
            fileRegistry.tool(
                named: "write_file"
            ),
            "core file tool set write_file"
        )

        _ = try Expect.notNil(
            fileRegistry.tool(
                named: "edit_file"
            ),
            "core file tool set edit_file"
        )

        _ = try Expect.notNil(
            fileRegistry.tool(
                named: "scan_paths"
            ),
            "core file tool set scan_paths"
        )

        let contextRegistry = try Agentic.tool.registry {
            CoreContextToolSet()
        }

        try Expect.equal(
            contextRegistry.count,
            3,
            "core context tool set count"
        )

        _ = try Expect.notNil(
            contextRegistry.tool(
                named: "compose_context"
            ),
            "core context tool set compose_context"
        )

        _ = try Expect.notNil(
            contextRegistry.tool(
                named: "inspect_context_sources"
            ),
            "core context tool set inspect_context_sources"
        )

        _ = try Expect.notNil(
            contextRegistry.tool(
                named: "estimate_context_size"
            ),
            "core context tool set estimate_context_size"
        )

        let coreRegistry = try Agentic.tool.registry {
            CoreToolSet(
                includeInteractionTools: true
            )
        }

        try Expect.equal(
            coreRegistry.count,
            8,
            "core tool set count"
        )

        _ = try Expect.notNil(
            coreRegistry.tool(
                named: "clarify_with_user"
            ),
            "core tool set clarify_with_user"
        )

        return [
            .field(
                "file_tools",
                "\(fileRegistry.count)"
            ),
            .field(
                "context_tools",
                "\(contextRegistry.count)"
            ),
            .field(
                "core_tools",
                "\(coreRegistry.count)"
            ),
            .field(
                "interaction_tools",
                "included"
            )
        ]
    }
}

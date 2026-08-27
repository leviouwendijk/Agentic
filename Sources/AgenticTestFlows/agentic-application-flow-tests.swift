import Agentic
import TestFlows

extension AgenticFlowTesting {
    static func runApplicationComposition() async throws -> [TestFlowDiagnostic] {
        let probe = ApplicationAdapterProbe()

        let application = Agentic.application(
            "application-probe",
            title: "Application Probe",
            metadata: [
                "fixture": "true",
            ]
        ) {
            tools {
                CoreFileToolSet()
            }

            skills {
                AgentSkill(
                    identifier: "application-probe-skill",
                    name: "Application Probe Skill",
                    summary: "Proves AgenticApplication skill composition.",
                    body: "Application declarations remain inert until a runtime realizes them."
                )
            }

            adapter(
                "application_probe"
            ) {
                await probe.make()
            }

            modelProvider(
                ApplicationModelProvider()
            )
        }

        try Expect.equal(
            application.identifier.rawValue,
            "application-probe",
            "application identifier"
        )

        try Expect.equal(
            application.title,
            "Application Probe",
            "application title"
        )

        try Expect.equal(
            application.metadata["fixture"],
            "true",
            "application metadata"
        )

        try Expect.equal(
            application.toolRegistrations.count,
            1,
            "application tool registration count"
        )

        try Expect.equal(
            application.skillRegistrations.count,
            1,
            "application skill registration count"
        )

        try Expect.equal(
            application.adapterRegistrations.count,
            1,
            "application adapter registration count"
        )

        try Expect.equal(
            application.modelProviders.count,
            1,
            "application model provider count"
        )

        try Expect.equal(
            await probe.count(),
            0,
            "application construction does not initialize adapters"
        )

        let adapterRegistration = try Expect.notNil(
            application.adapterRegistrations.first,
            "application adapter registration"
        )

        try Expect.equal(
            adapterRegistration.identifier.rawValue,
            "application_probe",
            "application adapter identifier"
        )

        _ = try await adapterRegistration.make()

        try Expect.equal(
            await probe.count(),
            1,
            "adapter initializes only when explicitly realized"
        )

        let provider = try Expect.notNil(
            application.modelProviders.first,
            "application model provider"
        )

        try Expect.equal(
            provider.descriptor.source.rawValue,
            "application_probe",
            "application model provider source"
        )

        try Expect.equal(
            provider.descriptor.adapterIdentifier.rawValue,
            "application_probe",
            "application model provider adapter identifier"
        )

        return [
            .field(
                "application",
                application.identifier.rawValue
            ),
            .field(
                "tool_registrations",
                String(
                    application.toolRegistrations.count
                )
            ),
            .field(
                "skill_registrations",
                String(
                    application.skillRegistrations.count
                )
            ),
            .field(
                "adapter_registrations",
                String(
                    application.adapterRegistrations.count
                )
            ),
            .field(
                "model_providers",
                String(
                    application.modelProviders.count
                )
            ),
        ]
    }
}

private actor ApplicationAdapterProbe {
    private var makeCount = 0

    func make() -> MockModelAdapter {
        makeCount += 1

        return .buffered(
            text: "application-probe"
        )
    }

    func count() -> Int {
        makeCount
    }
}

private struct ApplicationModelProvider:
    AgentModelProvider
{
    let descriptor = AgentModelProviderDescriptor(
        source: "application_probe",
        adapterIdentifier: "application_probe",
        displayName: "Application Probe",
        metadata: [
            "fixture": "true",
        ]
    )
}

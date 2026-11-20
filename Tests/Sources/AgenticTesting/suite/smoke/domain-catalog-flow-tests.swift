import Agentic
import AgenticStandard
import Testing

let domainCatalogFlows: [TestFlow] = [
    TestFlow(
        "domain-catalog-without-build-plugin",
        tags: [
            "agentic",
            "catalog",
            "domain",
            "derived",
            "linker",
        ]
    ) {
        try Expect.equal(
            Standard.catalog.domains,
            [
                Standard.definition,
            ],
            "derived Standard catalog retains its domain definition"
        )

        try Expect.equal(
            Standard.catalog.tools.contains(
                where: { definition in
                    definition.identifier.rawValue
                        == "advisor_ask"
                }
            ),
            true,
            "derived Standard catalog discovers tools declared in extension files"
        )

        try Expect.equal(
            Standard.catalog.inferences.isEmpty,
            false,
            "derived Standard catalog discovers inference declarations"
        )

        try Expect.equal(
            Standard.catalog.programs.isEmpty,
            false,
            "derived Standard catalog discovers Program declarations"
        )

        try Expect.equal(
            Standard.catalog.declarations.isEmpty,
            false,
            "derived Standard catalog contains semantic declarations"
        )

        let composed =
            Catalog.none
            + Standard.catalog

        try Expect.equal(
            composed,
            Standard.catalog,
            "Catalog.none is structural composition identity"
        )

        return [
            .field(
                "domains",
                String(Standard.catalog.domains.count)
            ),
            .field(
                "tools",
                String(Standard.catalog.tools.count)
            ),
            .field(
                "programs",
                String(Standard.catalog.programs.count)
            ),
            .field(
                "inferences",
                String(Standard.catalog.inferences.count)
            ),
            .field(
                "agents",
                String(Standard.catalog.agents.count)
            ),
        ]
    },
]

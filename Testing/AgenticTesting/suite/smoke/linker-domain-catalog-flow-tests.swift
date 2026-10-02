import Agentic
import AgenticLinkerCatalogFixture
import AgenticStandard
import Testing

let linkerDomainCatalogFlows: [TestFlow] = [
    TestFlow(
        "linker-domain-catalog-without-build-plugin",
        tags: [
            "agentic",
            "catalog",
            "domain",
            "linker",
            "section",
        ]
    ) {
        let catalog = LinkerCatalogFixture.catalog
        let identifiers = Set(
            catalog.tools.map {
                $0.identifier.rawValue
            }
        )

        try Expect.equal(
            catalog.domains,
            [
                LinkerCatalogFixture.definition,
            ],
            "Domain.catalog retains the domain definition without generated source"
        )

        try Expect.equal(
            identifiers.contains(
                "linker_fixture_alpha"
            ),
            true,
            "Domain.catalog discovers Alpha without referencing Alpha.self"
        )

        try Expect.equal(
            identifiers.contains(
                "linker_fixture_beta"
            ),
            true,
            "Domain.catalog discovers Beta without referencing Beta.self"
        )

        return [
            .field(
                "tools",
                String(catalog.tools.count)
            ),
            .field(
                "alpha",
                String(
                    identifiers.contains(
                        "linker_fixture_alpha"
                    )
                )
            ),
            .field(
                "beta",
                String(
                    identifiers.contains(
                        "linker_fixture_beta"
                    )
                )
            ),
        ]
    },
    TestFlow(
        "unscoped-linker-catalog-isolation",
        tags: [
            "agentic",
            "catalog",
            "linker",
            "unscoped",
            "collision",
        ]
    ) {
        let collisionIdentifier =
            "unscoped_standard_collision"

        let domainIdentifiers = Set(
            AgenticStandard.Standard.catalog.tools.map {
                $0.identifier.rawValue
            }
        )
        let fixtureDomainIdentifiers = Set(
            AgenticLinkerCatalogFixture.LinkerCatalogFixture.catalog.tools.map {
                $0.identifier.rawValue
            }
        )
        let unscopedIdentifiers = Set(
            Catalog.unscoped.tools.map {
                $0.identifier.rawValue
            }
        )

        try Expect.equal(
            domainIdentifiers.contains(
                collisionIdentifier
            ),
            false,
            "A top-level Tool named Standard does not collide with the Standard Domain catalog"
        )

        try Expect.equal(
            fixtureDomainIdentifiers.contains(
                collisionIdentifier
            ),
            false,
            "An unscoped Tool does not leak into another Domain catalog"
        )

        try Expect.equal(
            unscopedIdentifiers.contains(
                collisionIdentifier
            ),
            true,
            "A top-level Tool remains linker-discoverable through Catalog.unscoped"
        )

        try Expect.equal(
            Catalog.unscoped.domains.isEmpty,
            true,
            "The unscoped catalog does not invent a synthetic DomainDefinition"
        )

        return [
            .field(
                "standard_collision",
                String(
                    domainIdentifiers.contains(
                        collisionIdentifier
                    )
                )
            ),
            .field(
                "unscoped",
                String(
                    unscopedIdentifiers.contains(
                        collisionIdentifier
                    )
                )
            ),
        ]
    },
]

import Agentic
import AgenticLinkerCatalogFixture
import Testing

let capabilityNameFlows: [TestFlow] = [
    TestFlow(
        "capability-identity-computed-from-the-domain",
        tags: ["agentic", "capability", "naming"]
    ) {
        try Expect.equal(
            NamedCatalogFixture.Tools.Build.identifier.rawValue,
            "fixture_tool_build",
            "a named domain computes <domain>_tool_<name>"
        )
        try Expect.equal(
            NamedCatalogFixture.Tools.RunProduct.identifier.rawValue,
            "fixture_tool_run_product",
            "the name keeps its underscores"
        )
        try Expect.equal(
            LinkerCatalogFixture.Tools.Alpha.identifier.rawValue,
            "linker_fixture_alpha",
            "a domain without a primary name keeps the authored identifier"
        )
        try Expect.equal(
            NamedCatalogFixture.definition.names.map(\.raw),
            ["fixture", "fx", "fixtures"],
            "primary name first, then the aliases as written"
        )
        try Expect.isNil(LinkerCatalogFixture.definition.name, "@Domain without arguments has no primary name")

        let parsed = try CapabilityIdentity(parsing: "fixture_tool_run_product")
        try Expect.equal(parsed.domain.raw, "fixture", "domain is up to the first underscore")
        try Expect.equal(parsed.kind, .tool, "kind is the second part")
        try Expect.equal(parsed.name.raw, "run_product", "name is the rest")
        try Expect.equal(parsed.string, "fixture_tool_run_product", "the string round-trips")
        try Expect.throwsError("the parser takes the full form only") {
            _ = try CapabilityIdentity(parsing: "fixture.build")
        }
        try Expect.throwsError("an unknown kind") {
            _ = try CapabilityIdentity(parsing: "swift_build")
        }
        try Expect.throwsError("past the provider limit") {
            _ = try CapabilityIdentity(parsing: "fixture_tool_" + String(repeating: "x", count: 60))
        }
        try Expect.throwsError("an underscore in a domain name") {
            _ = try DomainName("swift_lang")
        }
        return [
            .field("named", NamedCatalogFixture.Tools.Build.identifier.rawValue),
            .field("authored", LinkerCatalogFixture.Tools.Alpha.identifier.rawValue),
        ]
    },
    TestFlow(
        "capability-resolver-accepts-aliases-and-bare-names",
        tags: ["agentic", "capability", "naming", "resolver"]
    ) {
        let resolver = CapabilityResolver(domains: [
            NamedCatalogFixture.definition,
            OtherCatalogFixture.definition,
            LinkerCatalogFixture.definition,
        ])
        let candidates = [
            "fixture_tool_build",
            "fixture_tool_run_product",
            "other_tool_build",
            "linker_fixture_alpha",
            "read_agent_transcript",
        ]
        func resolve(_ text: String, domain: String? = nil) throws -> String {
            try resolver.resolve(text, domain: domain, among: candidates)
        }

        try Expect.equal(try resolve("fixture_tool_build"), "fixture_tool_build", "the full string, exactly")
        try Expect.equal(try resolve("linker_fixture_alpha"), "linker_fixture_alpha", "an authored identifier, exactly")
        try Expect.equal(try resolve("fixture.build"), "fixture_tool_build", "domain.name")
        try Expect.equal(try resolve("fx.build"), "fixture_tool_build", "alias.name")
        try Expect.equal(try resolve("fx_tool_build"), "fixture_tool_build", "the full form with an alias")
        try Expect.equal(try resolve("build", domain: "fixtures"), "fixture_tool_build", "a bare name with an aliased domain")
        try Expect.equal(try resolve("run_product"), "fixture_tool_run_product", "a bare name only one domain has")

        do {
            _ = try resolve("build")
            throw ExpectationFailure("a shared bare name must be ambiguous")
        } catch let error as CapabilityReferenceError {
            try Expect.equal(
                error,
                .ambiguous("build", candidates: ["fixture_tool_build", "other_tool_build"], domains: ["fixture", "other"]),
                "both candidates, qualified"
            )
            try Expect.true(
                error.localizedDescription.contains("Pass domain (\"fixture\" or \"other\")"),
                "the message says how to disambiguate"
            )
        }
        try Expect.throwsError("an unknown domain") { _ = try resolve("nope.build") }
        try Expect.throwsError("domain and name disagree") { _ = try resolve("other.build", domain: "fx") }
        try Expect.throwsError("nothing by that name") { _ = try resolve("deploy") }
        try Expect.throwsError("an authored id that parses is not a domain") { _ = try resolve("transcript", domain: "read") }
        return [.field("candidates", candidates.joined(separator: ", "))]
    },
    TestFlow(
        "catalog-naming-problems",
        tags: ["agentic", "catalog", "naming"]
    ) {
        let catalog = NamedCatalogFixture.catalog + OtherCatalogFixture.catalog + LinkerCatalogFixture.catalog
        try Expect.equal(catalog.namingProblems, [], "the fixture domains are consistent")

        let clash = Catalog(domains: [
            DomainDefinition(namespace: .init(rawValue: "a"), name: try DomainName("swift"), aliases: [try DomainName("sbm")]),
            DomainDefinition(namespace: .init(rawValue: "b"), name: try DomainName("zig"), aliases: [try DomainName("sbm")]),
        ])
        try Expect.equal(
            clash.namingProblems,
            [.duplicateDomainName("sbm", namespaces: ["a", "b"])],
            "two domains claiming one alias"
        )
        try Expect.throwsError("validateNames throws on a clash") { try clash.validateNames() }
        return [.field("problems", clash.namingProblems.map(\.description).joined(separator: " "))]
    },
]

private struct ExpectationFailure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

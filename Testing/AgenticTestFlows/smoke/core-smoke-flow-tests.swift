import Agentic
import AgenticTesting
import Schema
import Workspace

@Domain
enum SmokeDomain {}

struct SmokeToolInput:
    Source,
    RawRepresentable
{
    let rawValue: String

    init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    static var jsonschema: JSONSchema {
        .string()
    }
}

struct SmokeToolOutput: Result {
    let value: String

    static var jsonschema: JSONSchema {
        .object()
    }
}

struct SmokeTool:
    Tool
{
    typealias Input = SmokeToolInput
    typealias Output = SmokeToolOutput

    static let definition = ToolDefinition(
        identifier: .init(rawValue: "smoke_tool"),
        purpose: "Prove the core Tool declaration contract."
    )

    func call(
        _ input: Input,
        workspace _: WorkspaceContext?
    ) async throws -> Output {
        .init(
            value: input.rawValue
        )
    }

    func process(
        _ output: Output,
        input: Input
    ) throws -> ToolCall.ResultProjection? {
        .init(
            status: "smoke",
            summary: "\(input.rawValue):\(output.value)"
        )
    }

    func reconcile(
        _ input: Input,
        after failure: ToolCall.Failure,
        workspace _: WorkspaceContext?
    ) async throws -> ToolCall.Reconciliation<Output>? {
        _ = input
        _ = failure
        return .not_applied
    }
}

struct AgenticTest {
    static func runDomainSmoke() {
        ContractProof.domain(
            SmokeDomain.self
        )
        ContractProof.tool(
            SmokeTool.self
        )

        guard SmokeDomain.definition.namespace.rawValue == "smoke_domain" else {
            fatalError(
                "Expected @Domain to synthesize definition namespace smoke_domain, got \(SmokeDomain.definition.namespace.rawValue)."
            )
        }

        guard SmokeDomain.namespace.rawValue == "smoke_domain" else {
            fatalError(
                "Expected Domain.namespace to resolve through definition, got \(SmokeDomain.namespace.rawValue)."
            )
        }

        _ = SmokeDomain.Agents.self
        _ = SmokeDomain.Inferences.self
        _ = SmokeDomain.Programs.self
        _ = SmokeDomain.Tools.self
        _ = SmokeDomain.Realizations.self

        print("PASS: @Domain smoke")
    }

}

import Agentic
import Primitives
import Schema
import Testing

private enum CapabilityContractSmokeFailure: Error {
    case unexpectedSuccess
    case unexpectedOutcome
}

func runCapabilityContractSmoke() throws {
    let input = SmokeToolInput(rawValue: "capability-contract")
    let transport = ToolCall(
        id: "smoke-contract-call",
        tool: SmokeTool.definition.identifier,
        input: try JSONValue.encoding(input)
    )
    let raw = CapabilityCall.Raw(transport)
    let typed = try CapabilityRequest<SmokeTool>(parsing: raw)
    try Expect.equal(
        typed.input.rawValue,
        input.rawValue,
        "raw input decodes to the authored type"
    )

    let wrong = CapabilityCall.Raw(
        id: raw.id,
        capability: .program(.init(rawValue: "smoke_tool")),
        input: raw.input
    )
    do {
        _ = try CapabilityRequest<SmokeTool>(parsing: wrong)
        throw CapabilityContractSmokeFailure.unexpectedSuccess
    } catch let error as CapabilityRequestError {
        guard case let .mismatchedCapability(expected, actual) = error else {
            throw CapabilityContractSmokeFailure.unexpectedOutcome
        }
        try Expect.equal(expected, SmokeTool.reference, "expected typed identity")
        try Expect.equal(actual, wrong.capability, "actual raw identity")
    }

    let completed: Execution.Outcome<SmokeToolOutput, String> =
        .completed(.init(value: "ok"))
    guard case let .completed(output) = completed else {
        throw CapabilityContractSmokeFailure.unexpectedOutcome
    }
    try Expect.equal(output.value, "ok", "completed output remains typed")

    let suspended: Execution.Outcome<SmokeToolOutput, String> =
        .suspended("checkpoint-1")
    guard case let .suspended(checkpoint) = suspended else {
        throw CapabilityContractSmokeFailure.unexpectedOutcome
    }
    try Expect.equal(checkpoint, "checkpoint-1", "suspension carries executor state")
}

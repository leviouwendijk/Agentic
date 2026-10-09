import Agentic
import Foundation
import Primitives
import Schema
import Testing

private enum KindBindingSmokeError: Error {
    case unexpectedSuccess
    case unexpectedError
}

func runCapabilityKindBindingsSmoke() throws {
    typealias I = SmokeDomain.Inferences.MacroSmokeInference
    let inference = InferenceBinding(I.self)
    try Expect.equal(inference.reference, I.reference, "inference reference stays typed")
    try Expect.equal(
        inference.capabilityContract.input,
        I.contract.input,
        "inference binding retains the authored input contract"
    )

    let inferenceCall = CapabilityCall.Raw(
        id: "inference-binding-smoke",
        capability: I.reference,
        input: try JSONValue.encoding(I.Input(value: "hello"))
    )
    let config = InferenceRealizationConfiguration(
        strategy: .direct,
        instructions: "Smoke test typed inference binding.",
        budget: .singleAttempt
    )
    let prepared = try inference.invocation(
        from: inferenceCall,
        realization: config
    )
    try Expect.equal(prepared.definition.identifier, I.definition.identifier,
                     "prepared invocation retains inference identity")
    let direct = try inference.invocation(
        input: inferenceCall.input,
        realization: config
    )
    try Expect.equal(direct.definition.identifier, I.definition.identifier,
                     "bound inference accepts a resolved semantic input")
    let decoded = try JSONDecoder().decode(I.Input.self, from: prepared.input)
    try Expect.equal(decoded.value, "hello", "typed inference input preserved")

    do {
        _ = try inference.invocation(from: inferenceCall)
        throw KindBindingSmokeError.unexpectedSuccess
    } catch let error as InferenceBindingError {
        guard case let .missingRealization(identifier) = error else {
            throw KindBindingSmokeError.unexpectedError
        }
        try Expect.equal(identifier, I.definition.identifier, "missing realization preserves identity")
    }

    typealias A = SmokeDomain.Agents.MacroSmokeAgent
    let agent = AgentBinding(A.self)
    try Expect.equal(agent.reference, A.reference, "agent reference stays typed")
    try Expect.equal(agent.capabilityContract.output, A.contract.output,
                     "agent binding retains authored output contract")
    let agentRaw = CapabilityCall.Raw(
        id: "agent-binding-smoke",
        capability: A.reference,
        input: try JSONValue.encoding(A.Input(objective: "evaluate"))
    )
    let agentCall = try agent.call(from: agentRaw)
    try Expect.equal(agentCall.id, agentRaw.id, "agent call ID preserved")
    try Expect.equal(agentCall.agent, A.definition.identifier,
                     "agent call uses resolved identity")

    let wrong = CapabilityCall.Raw(
        id: agentRaw.id,
        capability: .tool(.init(rawValue: A.definition.identifier.rawValue)),
        input: agentRaw.input
    )
    do {
        _ = try agent.call(from: wrong)
        throw KindBindingSmokeError.unexpectedSuccess
    } catch let error as CapabilityRequestError {
        guard case let .mismatchedCapability(expected, actual) = error else {
            throw KindBindingSmokeError.unexpectedError
        }
        try Expect.equal(expected, A.reference, "expected Agent reference retained")
        try Expect.equal(actual, wrong.capability, "mismatched Tool reference retained")
    }

    let invalid = CapabilityCall.Raw(
        id: "invalid-agent-input",
        capability: A.reference,
        input: try JSONValue.encoding(123)
    )
    do {
        _ = try agent.call(from: invalid)
        throw KindBindingSmokeError.unexpectedSuccess
    } catch is KindBindingSmokeError {
        throw KindBindingSmokeError.unexpectedError
    } catch {
        // A matching identifier does not bypass typed input decoding.
    }
}

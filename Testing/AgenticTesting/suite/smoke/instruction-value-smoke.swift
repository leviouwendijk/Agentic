import Agentic
import Foundation
import Testing

func runInstructionValueSmoke() throws {
    let method = Instruction(
        identifier: "swift_lang.debugging_method",
        content: "Identify the earliest observable divergence.",
        source: "SwiftLang/Guidance/debugging.md"
    )
    let methodRevision = method.revision
    try Expect.equal(methodRevision, InstructionRevision.of(method.content))
    try Expect.equal(methodRevision.hasPrefix("sha256:"), true)
    try Expect.equal(methodRevision.count, 71)
    try Expect.equal(
        methodRevision,
        "sha256:d1343b08afb6ba39066311069da08af45b0b28d0b96673f6d597bf4521d71f9c"
    )

    let revised = Instruction(
        identifier: method.identifier,
        content: "Inspect the first failing operation.",
        source: method.source
    )
    try Expect.equal(revised.identifier, method.identifier)
    try Expect.equal(revised.revision == methodRevision, false)

    let composition: Instructions = [
        .instruction(method),
        .text("Investigate the reported Swift compiler failure."),
        .instruction(method),
    ]
    try Expect.equal(
        composition.resolved,
        "Identify the earliest observable divergence.\n\n"
            + "Investigate the reported Swift compiler failure.\n\n"
            + "Identify the earliest observable divergence."
    )
    try Expect.equal(
        composition.references.map(\.identifier),
        [method.identifier, method.identifier],
        "composition must retain order and repetitions"
    )
    let encoded = try JSONEncoder().encode(composition)
    let roundTrip = try JSONDecoder().decode(
        Instructions.self,
        from: encoded
    )
    try Expect.equal(roundTrip, composition)
    try Expect.equal(roundTrip.snapshot, composition.snapshot)

    let plain: Instructions = "Plain instruction text."
    try Expect.equal(plain.resolved, "Plain instruction text.")
    try Expect.equal(plain.snapshot.references.isEmpty, true)
    let single = InferenceRealizationConfiguration(
        strategy: .direct,
        instructions: method,
        budget: .singleAttempt
    )
    try Expect.equal(single.instructions, method.content)
    try Expect.equal(single.instructionSnapshot.references.count, 1)

    let original = InferenceRealizationConfiguration(
        strategy: .direct,
        instructions: composition,
        budget: .singleAttempt
    )
    try Expect.equal(original.instructions, composition.resolved)
    try Expect.equal(original.instructionSnapshot.references.count, 2)
    let literal = InferenceRealizationConfiguration(
        strategy: .direct,
        instructions: "Legacy string configuration",
        budget: .singleAttempt
    )
    let literalDecoded = try JSONDecoder().decode(
        InferenceRealizationConfiguration.self,
        from: JSONEncoder().encode(literal)
    )
    try Expect.equal(literalDecoded, literal)
    try Expect.equal(literalDecoded.instructionSnapshot.references.isEmpty, true)
    let restored = try JSONDecoder().decode(
        InferenceRealizationConfiguration.self,
        from: JSONEncoder().encode(original)
    )
    try Expect.equal(restored, original)
    try Expect.equal(
        restored.instructionSnapshot.revision,
        InstructionRevision.of(composition.resolved)
    )

    var optimized = original
    optimized.instructions = "Rewritten by optimizer."
    try Expect.equal(optimized.instructionSnapshot.references.isEmpty, true)
    try Expect.equal(optimized.instructionSnapshot.references.count, 0)
    try Expect.equal(original.instructionSnapshot.references.count, 2)
    let agent = SmokeDomain.Agents.MacroSmokeAgent.definition
    try Expect.equal(
        agent.instructions,
        "Respect observed evidence.\n\nInvestigate the fixture."
    )
    try Expect.equal(agent.instructionSnapshot?.references.count, 1)
    let realization = SmokeDomain.Realizations
        .MacroSmokeInferenceRealization.definition.configuration
    try Expect.equal(
        realization.instructions,
        "Respect observed evidence.\n\nUse the direct smoke realization."
    )
    try Expect.equal(realization.instructionSnapshot.references.count, 1)
}

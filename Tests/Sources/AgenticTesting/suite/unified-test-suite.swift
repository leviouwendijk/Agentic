import Agentic
import AgenticStandard
import Foundation
import Schema
import Surface
import Testing

enum UnifiedAgenticTestSuite {
    static let testSuite = TestSuite(
        "agentic",
        title: "Agentic tests"
    ) {
        AgenticSmokeFlowSuite.testSuite
        capabilitySelectionCompositionFlows.map {
            TestNode.test(
                Test($0)
            )
        }
        agentForkFlows.map {
            TestNode.test(
                Test($0)
            )
        }
        domainCatalogFlows.map {
            TestNode.test(
                Test($0)
            )
        }
        linkerDomainCatalogFlows.map {
            TestNode.test(
                Test($0)
            )
        }
        capabilityNameFlows.map {
            TestNode.test(
                Test($0)
            )
        }
        ModelRoutingFlowSuite.testSuite
        ModelRoutingImplementationTestSuite.testSuite
        AgenticInferenceFlowSuite.testSuite
        ProgramsFlowSuite.testSuite
        OptimizerFlowSuite.testSuite
        InferenceAdapterFlowSuite.testSuite
        RecoveryFlowSuite.testSuite
        HarnessTestSuite.testSuite
        UserInputSchemaTestSuite.testSuite
        ExecutionTestSuite.testSuite
        IntentsTestSuite.testSuite
        ContextContractSuite.testSuite
        SessionSearchTestSuite.testSuite
    }
}


private enum UserInputSchemaTestError: Error {
    case expectedOneOf
    case expectedObject
    case expectedClosedObject
    case missingKind
    case invalidKind
    case missingPayload(String)
    case expectedClarifyInputObject
    case missingClarifyInput
    case clarifyInputNotDiscriminated
}

enum UserInputSchemaTestSuite {
    static let testSuite = TestSuite(
        "user-input-schema",
        title: "User input model-facing schema tests"
    ) {
        Test(
            "user-input-spec-discriminator-contract"
        ) {
            guard case .oneOf(let variants) = SurfaceQuestion.jsonschema.form else {
                throw UserInputSchemaTestError.expectedOneOf
            }

            try Expect.equal(
                variants.count,
                4,
                "SurfaceQuestion exposes exactly its four semantic input kinds"
            )

            var observedKinds: [String] = []

            for variant in variants {
                guard case .object(
                    let properties,
                    let additionalProperties
                ) = variant.form else {
                    throw UserInputSchemaTestError.expectedObject
                }

                guard case .disallowed = additionalProperties else {
                    throw UserInputSchemaTestError.expectedClosedObject
                }

                guard let kindProperty = properties.first(
                    where: { property in
                        property.name == "kind"
                    }
                ) else {
                    throw UserInputSchemaTestError.missingKind
                }

                guard
                    kindProperty.required,
                    case .string(let cases) = kindProperty.schema.form,
                    cases.count == 1,
                    let kind = cases.first
                else {
                    throw UserInputSchemaTestError.invalidKind
                }

                guard properties.contains(
                    where: { property in
                        property.name == kind
                            && property.required
                    }
                ) else {
                    throw UserInputSchemaTestError.missingPayload(
                        kind
                    )
                }

                observedKinds.append(
                    kind
                )
            }

            try Expect.equal(
                observedKinds,
                [
                    "text",
                    "choice",
                    "confirmation",
                    "form",
                ],
                "SurfaceQuestion schema preserves the canonical semantic discriminator values"
            )
            try Expect.equal(
                observedKinds.contains("text_field"),
                false,
                "presentation control text_field is never exposed as a semantic input kind"
            )
            try Expect.equal(
                SurfaceQuestion.jsonschema.description?.contains(
                    "text_field"
                ) ?? false,
                true,
                "SurfaceQuestion documentation explicitly distinguishes presentation controls from semantic kinds"
            )
        }

        Test(
            "clarify-with-user-exposes-semantic-input-schema"
        ) {
            guard case .object(
                let properties,
                _
            ) = Standard.Tools.ClarifyWithUser.Input.jsonschema.form else {
                throw UserInputSchemaTestError.expectedClarifyInputObject
            }

            guard let input = properties.first(
                where: { property in
                    property.name == "input"
                }
            ) else {
                throw UserInputSchemaTestError.missingClarifyInput
            }

            try Expect.equal(
                input.required,
                true,
                "standard_tool_clarify_with_user requires its semantic input specification"
            )
            try Expect.equal(
                input.description?.contains(
                    "semantic input shape"
                ) ?? false,
                true,
                "@JSONSchema propagates the authored input documentation into the tool schema"
            )

            guard case .oneOf(let variants) = input.schema.form else {
                throw UserInputSchemaTestError.clarifyInputNotDiscriminated
            }

            try Expect.equal(
                variants.count,
                4,
                "standard_tool_clarify_with_user exposes the complete SurfaceQuestion discriminated union to the model"
            )
        }

        Test(
            "user-input-response-refines-choice-answers"
        ) {
            let options: [SurfaceChoice.Option] = [
                .init(
                    id: "a",
                    label: "A",
                    value: "a"
                ),
                .init(
                    id: "b",
                    label: "B",
                    value: "b"
                ),
            ]
            let one = try UserInputRequest(
                prompt: "Pick one.",
                input: .choice(
                    .init(
                        options: options,
                        rule: .one
                    )
                )
            )
            let many = try UserInputRequest(
                prompt: "Pick several.",
                input: .choice(
                    .init(
                        options: options,
                        rule: .many,
                        minimum: 1
                    )
                )
            )

            try Expect.equal(
                try UserInputResponse(
                    .choice(
                        .option(
                            " b "
                        )
                    ),
                    for: one
                ).answer,
                .choice(
                    .option(
                        "b"
                    )
                ),
                "rule one accepts a declared option and trims its identifier"
            )
            try Expect.equal(
                try UserInputResponse(
                    .choice(
                        .init(
                            selected: [
                                "b",
                                "a",
                                "a",
                            ]
                        )
                    ),
                    for: many
                ).answer,
                .choice(
                    .init(
                        selected: [
                            "a",
                            "b",
                        ]
                    )
                ),
                "rule many de-duplicates selections in option order"
            )

            var rejected = false

            do {
                _ = try UserInputResponse(
                    .choice(
                        .init(
                            selected: [
                                "a",
                                "b",
                            ]
                        )
                    ),
                    for: one
                )
            } catch SurfaceQuestion.Error.tooManySelections {
                rejected = true
            }

            try Expect.equal(
                rejected,
                true,
                "rule one rejects more than one selection"
            )

            let decoded = try JSONDecoder().decode(
                UserInputReply.self,
                from: Data(
                    #"{"kind":"answer","answer":{"kind":"choice","choice":{"selected":["a"]}}}"#.utf8
                )
            )

            try Expect.equal(
                decoded,
                .choice(
                    .option(
                        "a"
                    )
                ),
                "the model-facing choice answer shape decodes into a reply"
            )
        }
    }
}
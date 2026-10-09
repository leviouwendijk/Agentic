import Agentic
import AgenticStandard
import Schema
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
        ContextContractSuite.testSuite
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
            guard case .oneOf(let variants) = UserInputSpec.jsonschema.form else {
                throw UserInputSchemaTestError.expectedOneOf
            }

            try Expect.equal(
                variants.count,
                5,
                "UserInputSpec exposes exactly its five semantic input kinds"
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
                    "single_choice",
                    "multi_choice",
                    "confirmation",
                    "form",
                ],
                "UserInputSpec schema preserves the canonical semantic discriminator values"
            )
            try Expect.equal(
                observedKinds.contains("text_field"),
                false,
                "presentation control text_field is never exposed as a semantic input kind"
            )
            try Expect.equal(
                UserInputSpec.jsonschema.description?.contains(
                    "text_field"
                ) ?? false,
                true,
                "UserInputSpec documentation explicitly distinguishes presentation controls from semantic kinds"
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
                "clarify_with_user requires its semantic input specification"
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
                5,
                "clarify_with_user exposes the complete UserInputSpec discriminated union to the model"
            )
        }
    }
}
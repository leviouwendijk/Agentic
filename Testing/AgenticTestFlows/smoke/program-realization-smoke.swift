import Agentic
import AgenticTesting

extension SmokeDomain.Realizations {
    @InferenceRealization
    struct MacroSmokeInferenceRealizationOverride {
        typealias InferenceType =
            SmokeDomain.Inferences.MacroSmokeInference

        static let strategy:
            InferenceStrategyIdentifier = .direct

        static let instructions =
            "Use the override smoke realization."
    }
}

func runProgramRealizationSmoke() {
    let site =
        SmokeDomain.Programs.MacroSmokeProgram.compose

    let inferenceRealization =
        SmokeDomain.Realizations
            .MacroSmokeInferenceRealization
            .definition

    let overrideInferenceRealization =
        SmokeDomain.Realizations
            .MacroSmokeInferenceRealizationOverride
            .definition

    ContractProof.inferenceSite(
        site,
        program:
            SmokeDomain.Programs.MacroSmokeProgram.self,
        inference:
            SmokeDomain.Inferences.MacroSmokeInference.self
    )

    guard site.identifier.rawValue ==
        "smoke_domain.programs.macro_smoke_program.sites.compose"
    else {
        fatalError(
            "Unexpected Inference site semantic identifier: \(site.identifier.rawValue)"
        )
    }

    guard site.program ==
        SmokeDomain.Programs.MacroSmokeProgram.definition.identifier
    else {
        fatalError(
            "Expected Inference site to preserve Program ownership."
        )
    }

    guard site.inference ==
        SmokeDomain.Inferences.MacroSmokeInference.definition.identifier
    else {
        fatalError(
            "Expected Inference site to preserve Inference identity."
        )
    }

    let programRealization =
        SmokeDomain.Programs.MacroSmokeProgram.realization {
            site.use(
                SmokeDomain.Realizations
                    .MacroSmokeInferenceRealization.self
            )
        }

    guard programRealization.bindings.count == 1 else {
        fatalError(
            "Expected exactly one authored Program realization binding."
        )
    }

    guard let binding = programRealization.binding(
        for: site
    ) else {
        fatalError(
            "Expected typed Inference site binding."
        )
    }

    guard binding.site == site.identifier else {
        fatalError(
            "Expected Program realization binding to preserve site identity."
        )
    }

    guard binding.inference ==
        SmokeDomain.Inferences.MacroSmokeInference.definition.identifier
    else {
        fatalError(
            "Expected Program realization binding to preserve Inference identity."
        )
    }

    guard binding.realization == inferenceRealization.identifier else {
        fatalError(
            "Expected Program realization binding to preserve realization identity."
        )
    }

    let authoredReplacement =
        SmokeDomain.Programs.MacroSmokeProgram.realization {
            site.use(
                SmokeDomain.Realizations
                    .MacroSmokeInferenceRealization.self
            )
            site.use(
                SmokeDomain.Realizations
                    .MacroSmokeInferenceRealizationOverride.self
            )
        }

    guard authoredReplacement.bindings.count == 1 else {
        fatalError(
            "Authored duplicate sites must resolve to one binding."
        )
    }

    guard authoredReplacement.binding(
        for: site
    )?.realization == overrideInferenceRealization.identifier
    else {
        fatalError(
            "Later authored site bindings must replace earlier bindings."
        )
    }

    let replaced = programRealization.replacing(
        site,
        with: overrideInferenceRealization
    )

    guard replaced.bindings.count == 1 else {
        fatalError(
            "Replacing one site must not duplicate its binding."
        )
    }

    guard replaced.binding(
        for: site
    )?.realization == overrideInferenceRealization.identifier
    else {
        fatalError(
            "Expected explicit replacement to use the supplied realization."
        )
    }

    do {
        _ = try ProgramRealization<
            SmokeDomain.Programs.MacroSmokeProgram
        >(
            bindings: [
                site.use(
                    SmokeDomain.Realizations
                        .MacroSmokeInferenceRealization.self
                ),
                site.use(
                    SmokeDomain.Realizations
                        .MacroSmokeInferenceRealizationOverride.self
                ),
            ]
        )

        fatalError(
            "Expected duplicate dynamic Inference site bindings to be rejected."
        )
    } catch let error as ProgramRealizationParsingError {
        guard case .duplicateInferenceSite(let identifier) = error,
            identifier == site.identifier
        else {
            fatalError(
                "Unexpected Program realization parsing error: \(error)"
            )
        }
    } catch {
        fatalError(
            "Unexpected Program realization parsing error: \(error)"
        )
    }

    print(
        "PASS: nonthrowing typed Program realization authoring"
    )
}


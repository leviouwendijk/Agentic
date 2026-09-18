import Agentic

func runProgramRealizationSmoke() {
    let site =
        SmokeDomain.Programs.MacroSmokeProgram.compose

    let inferenceRealization =
        SmokeDomain.Realizations
            .MacroSmokeInferenceRealization
            .definition

    requireOwnedInferenceSite(
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

    do {
        let programRealization = try
            SmokeDomain.Programs.MacroSmokeProgram.realization(
                .init(
                    site,
                    realization: inferenceRealization
                )
            )

        guard programRealization.bindings.count == 1 else {
            fatalError(
                "Expected exactly one Program realization binding."
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

        let replaced = programRealization.replacing(
            site,
            with: inferenceRealization
        )

        guard replaced.bindings.count == 1 else {
            fatalError(
                "Replacing one site must not duplicate its binding."
            )
        }

        do {
            _ = try ProgramRealization<
                SmokeDomain.Programs.MacroSmokeProgram
            >(
                bindings: [
                    .init(
                        site,
                        realization: inferenceRealization
                    ),
                    .init(
                        site,
                        realization: inferenceRealization
                    ),
                ]
            )

            fatalError(
                "Expected duplicate Inference site bindings to be rejected."
            )
        } catch let error as ProgramRealizationParsingError {
            guard case .duplicateInferenceSite(let identifier) = error,
                identifier == site.identifier
            else {
                fatalError(
                    "Unexpected Program realization parsing error: \(error)"
                )
            }
        }
    } catch {
        fatalError(
            "Unexpected Program realization error: \(error)"
        )
    }

    print(
        "PASS: owned typed Program realization semantics"
    )
}

private func requireOwnedInferenceSite<
    ProgramType: Program,
    InferenceType: Inference
>(
    _: InferenceSite<
        ProgramType,
        InferenceType
    >,
    program _: ProgramType.Type,
    inference _: InferenceType.Type
) {}

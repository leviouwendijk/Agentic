import Agentic

extension SmokeDomain.Programs.MacroSmokeProgram {
    static let composeSite:
        InferenceSite<SmokeDomain.Inferences.MacroSmokeInference> = .init(
            identifier: .init(
                rawValue: "smoke_domain.programs.macro_smoke_program.sites.compose"
            )
        )
}

func runProgramRealizationSmoke() {
    let site =
        SmokeDomain.Programs.MacroSmokeProgram.composeSite

    let inferenceRealization =
        SmokeDomain.Realizations
            .MacroSmokeInferenceRealization
            .definition

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

    print("PASS: typed Program realization semantics")
}

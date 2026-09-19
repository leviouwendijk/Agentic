@resultBuilder
public enum ProgramRealizationBuilder<
    ProgramType: Program
> {
    public static func buildBlock(
        _ components: [
            ProgramRealization<ProgramType>.Binding
        ]...
    ) -> [ProgramRealization<ProgramType>.Binding] {
        components.flatMap { component in
            component
        }
    }

    public static func buildExpression(
        _ expression: ProgramRealization<ProgramType>.Binding
    ) -> [ProgramRealization<ProgramType>.Binding] {
        [
            expression,
        ]
    }
}

public extension InferenceSite {
    func use<RealizationType: InferenceRealization>(
        _ realization: RealizationType.Type
    ) -> ProgramRealization<ProgramType>.Binding
    where RealizationType.InferenceType == InferenceType {
        .init(
            self,
            realization: realization.definition
        )
    }
}

public extension Program {
    static func realization(
        @ProgramRealizationBuilder<Self>
        _ content: () -> [ProgramRealization<Self>.Binding]
    ) -> ProgramRealization<Self> {
        .init(
            authoredBindings: content()
        )
    }
}

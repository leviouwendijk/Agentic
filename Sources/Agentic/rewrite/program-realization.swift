public enum ProgramRealizationParsingError:
    Error,
    Sendable,
    Equatable
{
    case duplicateInferenceSite(
        InferenceSiteIdentifier
    )
}

public struct ProgramRealization<
    ProgramType: Program
>:
    Sendable,
    Codable,
    Hashable
{
    public struct Binding:
        Sendable,
        Codable,
        Hashable
    {
        public let site: InferenceSiteIdentifier
        public let inference: InferenceIdentifier
        public let realization: InferenceRealizationIdentifier
        public let configuration: InferenceRealizationConfiguration

        public init<InferenceType: Inference>(
            _ site: InferenceSite<InferenceType>,
            realization: InferenceRealizationDefinition<InferenceType>
        ) {
            self.site = site.identifier
            self.inference = site.inference
            self.realization = realization.identifier
            self.configuration = realization.configuration
        }
    }

    public let bindings: [Binding]

    public init(
        bindings: [Binding] = []
    ) throws {
        var seen: Set<InferenceSiteIdentifier> = []

        for binding in bindings {
            guard seen.insert(binding.site).inserted else {
                throw ProgramRealizationParsingError
                    .duplicateInferenceSite(
                        binding.site
                    )
            }
        }

        self.bindings = bindings
    }

    private init(
        validatedBindings: [Binding]
    ) {
        bindings = validatedBindings
    }

    public func binding<InferenceType: Inference>(
        for site: InferenceSite<InferenceType>
    ) -> Binding? {
        bindings.first { binding in
            binding.site == site.identifier
        }
    }

    public func replacing<InferenceType: Inference>(
        _ site: InferenceSite<InferenceType>,
        with realization: InferenceRealizationDefinition<InferenceType>
    ) -> Self {
        let replacement = Binding(
            site,
            realization: realization
        )

        var bindings = bindings

        if let index = bindings.firstIndex(
            where: { binding in
                binding.site == site.identifier
            }
        ) {
            bindings[index] = replacement
        } else {
            bindings.append(
                replacement
            )
        }

        return Self(
            validatedBindings: bindings
        )
    }
}

public extension Program {
    static func realization(
        _ bindings: ProgramRealization<Self>.Binding...
    ) throws -> ProgramRealization<Self> {
        try .init(
            bindings: bindings
        )
    }
}

import Schema

public extension Decision {
    /// Ordered levels define positions 0...(levels.count - 1).
    /// Use a domain-specific Level type to distinguish different scales statically.
    struct Scale<Level: HashableProduct>:
        Sendable,
        Codable,
        Hashable,
        JSONSchemaProviding
    {
        public let id: String
        public let levels: [Option<Level>]

        public init(
            id: String,
            levels: [Option<Level>]
        ) throws {
            try requireIdentifier(id)

            guard levels.count >= 2 else {
                throw Error.invalidScale
            }

            try requireOptions(levels)
            self.id = id
            self.levels = levels
        }

        private enum CodingKeys:
            String,
            CodingKey
        {
            case id
            case levels
        }

        public init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )

            try self.init(
                id: container.decode(
                    String.self,
                    forKey: .id
                ),
                levels: container.decode(
                    [Option<Level>].self,
                    forKey: .levels
                )
            )
        }

        public static var jsonschema: JSONSchema {
            .object(
                properties: [
                    .init(
                        name: "id",
                        schema: String.jsonschema,
                        required: true
                    ),
                    .init(
                        name: "levels",
                        schema: [Option<Level>].jsonschema,
                        required: true
                    ),
                ],
                additionalProperties: .disallowed
            )
        }
    }

    struct Score<Level: HashableProduct>:
        Sendable,
        Codable,
        Hashable,
        JSONSchemaProviding
    {
        public let scale: Scale<Level>
        /// Entries retain the exact low-to-high order of the authored scale.
        public let probabilities: [Weight<Level>]
        public let confidence: Confidence?

        public init(
            scale: Scale<Level>,
            probabilities: [Weight<Level>],
            confidence: Confidence? = nil
        ) throws {
            guard probabilities.map(\.value)
                == scale.levels.map(\.value)
            else {
                throw Error.invalidDistribution
            }

            try requireDistribution(
                probabilities.map(\.probability)
            )

            self.scale = scale
            self.probabilities = probabilities
            self.confidence = confidence
        }

        /// Probability-weighted ordinal position on the authored scale.
        public var value: Double {
            probabilities
                .enumerated()
                .reduce(0.0) {
                    $0
                        + Double($1.offset)
                        * $1.element.probability.value
                }
        }

        private enum CodingKeys:
            String,
            CodingKey
        {
            case scale
            case value
            case probabilities
            case confidence
        }

        public init(
            from decoder: any Decoder
        ) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )
            let scale = try container.decode(
                Scale<Level>.self,
                forKey: .scale
            )
            let reportedValue = try container.decode(
                Double.self,
                forKey: .value
            )
            let probabilities = try container.decode(
                [Weight<Level>].self,
                forKey: .probabilities
            )
            let confidence = try container.decodeIfPresent(
                Confidence.self,
                forKey: .confidence
            )

            try self.init(
                scale: scale,
                probabilities: probabilities,
                confidence: confidence
            )

            guard reportedValue.isFinite,
                  abs(
                    reportedValue - value
                  ) <= Decision.probabilityTolerance
            else {
                throw Error.invalidScore
            }
        }

        public func encode(
            to encoder: any Encoder
        ) throws {
            var container = encoder.container(
                keyedBy: CodingKeys.self
            )

            try container.encode(
                scale,
                forKey: .scale
            )
            try container.encode(
                value,
                forKey: .value
            )
            try container.encode(
                probabilities,
                forKey: .probabilities
            )
            try container.encodeIfPresent(
                confidence,
                forKey: .confidence
            )
        }

        public static var jsonschema: JSONSchema {
            .object(
                properties: [
                    .init(
                        name: "scale",
                        schema: Scale<Level>.jsonschema,
                        required: true
                    ),
                    .init(
                        name: "value",
                        schema: Double.jsonschema,
                        required: true
                    ),
                    .init(
                        name: "probabilities",
                        schema: [Weight<Level>].jsonschema,
                        required: true
                    ),
                    .init(
                        name: "confidence",
                        schema: Confidence.jsonschema,
                        required: false
                    ),
                ],
                additionalProperties: .disallowed
            )
        }
    }
}

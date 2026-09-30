import Schema

public extension Decision {
    struct Option<Value: HashableProduct>:
        Sendable,
        Codable,
        Hashable,
        JSONSchemaProviding
    {
        public let id: String
        public let value: Value
        public let description: Content

        public init(
            id: String,
            value: Value,
            description: Content
        ) throws {
            try requireIdentifier(id)
            self.id = id
            self.value = value
            self.description = description
        }

        private enum CodingKeys:
            String,
            CodingKey
        {
            case id
            case value
            case description
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
                value: container.decode(
                    Value.self,
                    forKey: .value
                ),
                description: container.decode(
                    Content.self,
                    forKey: .description
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
                        name: "value",
                        schema: Value.jsonschema,
                        required: true
                    ),
                    .init(
                        name: "description",
                        schema: Content.jsonschema,
                        required: true
                    ),
                ],
                additionalProperties: .disallowed
            )
        }
    }

    struct Weight<Value: HashableProduct>:
        Sendable,
        Codable,
        Hashable,
        JSONSchemaProviding
    {
        public let value: Value
        public let probability: Probability

        public init(
            value: Value,
            probability: Probability
        ) {
            self.value = value
            self.probability = probability
        }

        public static var jsonschema: JSONSchema {
            .object(
                properties: [
                    .init(
                        name: "value",
                        schema: Value.jsonschema,
                        required: true
                    ),
                    .init(
                        name: "probability",
                        schema: Probability.jsonschema,
                        required: true
                    ),
                ],
                additionalProperties: .disallowed
            )
        }
    }

    struct Choice<Value: HashableProduct>:
        Sendable,
        Codable,
        Hashable,
        JSONSchemaProviding
    {
        public let value: Value
        public let probabilities: [Weight<Value>]
        public let confidence: Confidence?

        public init(
            value: Value,
            probabilities: [Weight<Value>],
            confidence: Confidence? = nil
        ) throws {
            try requireDistribution(
                probabilities.map(\.probability)
            )

            guard Set(
                probabilities.map(\.value)
            ).count == probabilities.count
            else {
                throw Error.duplicateValue
            }

            guard probabilities.contains(
                where: {
                    $0.value == value
                }
            ) else {
                throw Error.invalidSelection
            }

            self.value = value
            self.probabilities = probabilities
            self.confidence = confidence
        }

        public var mostProbableValues: [Value] {
            guard let maximum = probabilities
                .map(\.probability.value)
                .max()
            else {
                return []
            }

            return probabilities
                .filter {
                    $0.probability.value == maximum
                }
                .map(\.value)
        }

        private enum CodingKeys:
            String,
            CodingKey
        {
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

            try self.init(
                value: container.decode(
                    Value.self,
                    forKey: .value
                ),
                probabilities: container.decode(
                    [Weight<Value>].self,
                    forKey: .probabilities
                ),
                confidence: container.decodeIfPresent(
                    Confidence.self,
                    forKey: .confidence
                )
            )
        }

        public static var jsonschema: JSONSchema {
            .object(
                properties: [
                    .init(
                        name: "value",
                        schema: Value.jsonschema,
                        required: true
                    ),
                    .init(
                        name: "probabilities",
                        schema: [Weight<Value>].jsonschema,
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

import Foundation

public extension Decision {
    /// Provider-neutral question metadata; application values remain in Query's binding.
    struct Criterion:
        Sendable,
        Codable,
        Hashable
    {
        public let id: String
        public let description: Content
    }

    struct Question:
        Sendable,
        Codable,
        Hashable
    {
        public enum Kind:
            Sendable,
            Codable,
            Hashable
        {
            case binary(
                positive: Content?,
                negative: Content?
            )
            case choice(
                options: [Criterion]
            )
            case score(
                scale: String,
                levels: [Criterion]
            )
        }

        public let id: String
        public let instructions: Content
        public let kind: Kind
    }

    /// Semantic answers after provider parsing, before typed reconstruction.
    enum Answer:
        Sendable,
        Codable,
        Hashable
    {
        case binary(Probability)
        case choice(
            selected: String,
            probabilities: [String: Probability],
            confidence: Confidence?
        )
        case score(
            probabilities: [Probability],
            confidence: Confidence?
        )
    }

    /// An immutable question set and its invocation-local typed answer binding.
    /// The executable binding is deliberately not Codable.
    struct Query<Output: Sendable>: Sendable {
        public let questions: [Question]
        fileprivate let binding:
            @Sendable ([String: Answer]) throws -> Output

        fileprivate init(
            questions: [Question],
            binding: @escaping @Sendable ([String: Answer]) throws -> Output
        ) {
            self.questions = questions
            self.binding = binding
        }

        public func resolve(
            _ answers: [String: Answer]
        ) throws -> Output {
            guard Set(answers.keys)
                == Set(questions.map(\.id))
            else {
                throw Error.questionMismatch
            }

            return try binding(answers)
        }

        public func map<Mapped: Sendable>(
            _ transform: @escaping @Sendable (Output) throws -> Mapped
        ) -> Query<Mapped> {
            Query<Mapped>(
                questions: questions
            ) { answers in
                try transform(
                    binding(answers)
                )
            }
        }
    }

    static func binary(
        id: String = "decision",
        instructions: Content,
        positive: Content? = nil,
        negative: Content? = nil
    ) throws -> Query<Probability> {
        let question = try question(
            id: id,
            instructions: instructions,
            kind: .binary(
                positive: positive,
                negative: negative
            )
        )

        return Query(
            questions: [question]
        ) { answers in
            guard case .binary(let probability)? = answers[id] else {
                throw Error.answerMismatch(id)
            }

            return probability
        }
    }

    static func choice<Value: HashableProduct>(
        id: String = "decision",
        instructions: Content,
        options: [Option<Value>]
    ) throws -> Query<Choice<Value>> {
        try requireOptions(options)

        let question = try question(
            id: id,
            instructions: instructions,
            kind: .choice(
                options: options.map {
                    Criterion(
                        id: $0.id,
                        description: $0.description
                    )
                }
            )
        )

        return Query(
            questions: [question]
        ) { answers in
            guard case .choice(
                let selected,
                let probabilities,
                let confidence
            )? = answers[id]
            else {
                throw Error.answerMismatch(id)
            }

            guard Set(probabilities.keys)
                == Set(options.map(\.id))
            else {
                throw Error.invalidDistribution
            }

            guard let option = options.first(
                where: {
                    $0.id == selected
                }
            ) else {
                throw Error.invalidSelection
            }

            let weights = try options.map {
                option -> Weight<Value> in
                guard let probability = probabilities[
                    option.id
                ] else {
                    throw Error.invalidDistribution
                }

                return Weight(
                    value: option.value,
                    probability: probability
                )
            }

            return try Choice(
                value: option.value,
                probabilities: weights,
                confidence: confidence
            )
        }
    }

    static func score<Level: HashableProduct>(
        id: String = "decision",
        instructions: Content,
        scale: Scale<Level>
    ) throws -> Query<Score<Level>> {
        let question = try question(
            id: id,
            instructions: instructions,
            kind: .score(
                scale: scale.id,
                levels: scale.levels.map {
                    Criterion(
                        id: $0.id,
                        description: $0.description
                    )
                }
            )
        )

        return Query(
            questions: [question]
        ) { answers in
            guard case .score(
                let probabilities,
                let confidence
            )? = answers[id]
            else {
                throw Error.answerMismatch(id)
            }

            guard probabilities.count
                == scale.levels.count
            else {
                throw Error.invalidDistribution
            }

            let weights = Swift.zip(
                scale.levels,
                probabilities
            ).map {
                Weight(
                    value: $0.0.value,
                    probability: $0.1
                )
            }

            return try Score(
                scale: scale,
                probabilities: weights,
                confidence: confidence
            )
        }
    }

    /// Groups independently evaluated questions against one shared state.
    /// This does not introduce dependencies between questions.
    static func zip<Left: Sendable, Right: Sendable>(
        _ left: Query<Left>,
        _ right: Query<Right>
    ) throws -> Query<(Left, Right)> {
        let questions = left.questions
            + right.questions
        var identifiers: Set<String> = []

        for question in questions {
            guard identifiers.insert(
                question.id
            ).inserted else {
                throw Error.duplicateIdentifier(
                    question.id
                )
            }
        }

        return Query(
            questions: questions
        ) { answers in
            (
                try left.binding(answers),
                try right.binding(answers)
            )
        }
    }
}

extension Decision {
    static func requireOptions<Value: HashableProduct>(
        _ options: [Option<Value>]
    ) throws {
        guard !options.isEmpty else {
            throw Error.emptyOptions
        }

        var identifiers: Set<String> = []
        var values: Set<Value> = []

        for option in options {
            guard identifiers.insert(
                option.id
            ).inserted else {
                throw Error.duplicateIdentifier(
                    option.id
                )
            }

            guard values.insert(
                option.value
            ).inserted else {
                throw Error.duplicateValue
            }
        }
    }

    private static func question(
        id: String,
        instructions: Content,
        kind: Question.Kind
    ) throws -> Question {
        try requireIdentifier(id)

        guard !instructions.isEmptyText else {
            throw Error.emptyInstructions
        }

        return Question(
            id: id,
            instructions: instructions,
            kind: kind
        )
    }
}

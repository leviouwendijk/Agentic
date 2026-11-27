import Surface

public enum UserInputReply: Sendable, Codable, Hashable {
    case answer(SurfaceAnswer)
    case skip

    private enum CodingKeys: String, CodingKey {
        case kind
        case answer
    }

    private enum Kind: String, Codable {
        case answer
        case skip
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        let kind = try container.decode(
            Kind.self,
            forKey: .kind
        )

        switch kind {
        case .answer:
            self = .answer(
                try container.decode(
                    SurfaceAnswer.self,
                    forKey: .answer
                )
            )

        case .skip:
            self = .skip
        }
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        switch self {
        case .answer(let answer):
            try container.encode(
                Kind.answer,
                forKey: .kind
            )
            try container.encode(
                answer,
                forKey: .answer
            )

        case .skip:
            try container.encode(
                Kind.skip,
                forKey: .kind
            )
        }
    }
}

public extension UserInputReply {
    static func text(
        _ value: String
    ) -> Self {
        .answer(
            .text(
                value
            )
        )
    }

    static func choice(
        _ value: SurfaceChoice.Answer
    ) -> Self {
        .answer(
            .choice(
                value
            )
        )
    }

    static func confirmation(
        _ value: Bool
    ) -> Self {
        .answer(
            .confirmation(
                value
            )
        )
    }

    static func form(
        _ value: SurfaceForm.Answer
    ) -> Self {
        .answer(
            .form(
                value
            )
        )
    }
}


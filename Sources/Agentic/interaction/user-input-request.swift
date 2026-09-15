import Foundation

public struct UserInputRequest: Sendable, Codable, Hashable {
    public struct Raw: Sendable, Codable, Hashable {
        public var prompt: String
        public var reason: String?
        public var input: UserInputSpec
        public var presentation: UserInputPresentation?
        public var metadata: [String: String]

        public init(
            prompt: String,
            reason: String? = nil,
            input: UserInputSpec = .text(
                .init()
            ),
            presentation: UserInputPresentation? = nil,
            metadata: [String: String] = [:]
        ) {
            self.prompt = prompt
            self.reason = reason
            self.input = input
            self.presentation = presentation
            self.metadata = metadata
        }
    }

    public let prompt: String
    public let reason: String?
    public let input: UserInputSpec
    public let presentation: UserInputPresentation?
    public let metadata: [String: String]

    public init(
        _ raw: Raw
    ) throws {
        try UserInputRefinement.requireRequest(
            raw
        )

        prompt = raw.prompt
        reason = raw.reason
        input = raw.input
        presentation = raw.presentation
        metadata = raw.metadata
    }

    public init(
        prompt: String,
        reason: String? = nil,
        input: UserInputSpec = .text(
            .init()
        ),
        presentation: UserInputPresentation? = nil,
        metadata: [String: String] = [:]
    ) throws {
        try self.init(
            .init(
                prompt: prompt,
                reason: reason,
                input: input,
                presentation: presentation,
                metadata: metadata
            )
        )
    }

    public init(
        from decoder: any Decoder
    ) throws {
        try self.init(
            Raw(
                from: decoder
            )
        )
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        try Raw(
            prompt: prompt,
            reason: reason,
            input: input,
            presentation: presentation,
            metadata: metadata
        ).encode(
            to: encoder
        )
    }
}

@available(*, deprecated, renamed: "UserInputRequest")
public typealias PendingUserInput = UserInputRequest

public struct UserInputResponse: Sendable, Hashable {
    public let answer: UserInputAnswer

    public init(
        answer: UserInputAnswer,
        for request: UserInputRequest
    ) throws {
        self.answer = try UserInputRefinement.answer(
            answer,
            for: request.input
        )
    }
}

private enum UserInputRefinement {
    static func requireRequest(
        _ raw: UserInputRequest.Raw
    ) throws {
        guard !raw.prompt.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            throw UserInputError.emptyPrompt
        }

        try requireInput(
            raw.input
        )
    }

    static func requireInput(
        _ input: UserInputSpec
    ) throws {
        switch input {
        case .text(let spec):
            try requireTextConstraint(
                spec.constraint
            )

            if let defaultText = spec.defaultText {
                _ = try text(
                    defaultText,
                    constraint: spec.constraint
                )
            }

        case .single_choice(let spec):
            try requireChoices(
                spec.choices
            )

            if let defaultChoiceID = spec.defaultChoiceID {
                try requireCanonicalIdentifier(
                    defaultChoiceID,
                    invalid: UserInputError.invalidChoiceID
                )

                guard spec.choices.contains(where: {
                    $0.id == defaultChoiceID
                }) else {
                    throw UserInputError.unknownDefaultChoiceID(
                        defaultChoiceID
                    )
                }
            }

        case .multi_choice(let spec):
            try requireChoices(
                spec.choices
            )
            try requireSelectionBounds(
                spec
            )

            let known = Set(
                spec.choices.map(\.id)
            )
            var defaults: Set<String> = []

            for id in spec.defaultChoiceIDs {
                try requireCanonicalIdentifier(
                    id,
                    invalid: UserInputError.invalidChoiceID
                )

                guard defaults.insert(id).inserted else {
                    throw UserInputError.duplicateChoiceID(
                        id
                    )
                }

                guard known.contains(id) else {
                    throw UserInputError.unknownDefaultChoiceID(
                        id
                    )
                }
            }

            if let maximum = spec.maximumSelectionCount,
               spec.defaultChoiceIDs.count > maximum {
                throw UserInputError.tooManySelections(
                    maximum
                )
            }

        case .confirmation(let spec):
            guard !spec.confirmLabel.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty,
            !spec.cancelLabel.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
            else {
                throw UserInputError.emptyConfirmationLabel
            }

        case .form(let spec):
            guard !spec.fields.isEmpty else {
                throw UserInputError.emptyForm
            }

            var fieldIDs: Set<String> = []

            for field in spec.fields {
                try requireCanonicalIdentifier(
                    field.id,
                    invalid: UserInputError.invalidFieldID
                )

                guard fieldIDs.insert(field.id).inserted else {
                    throw UserInputError.duplicateFieldID(
                        field.id
                    )
                }

                guard !field.label.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty else {
                    throw UserInputError.emptyFieldLabel(
                        field.id
                    )
                }

                try requireTextConstraint(
                    field.constraint
                )

                if let defaultText = field.defaultText {
                    _ = try text(
                        defaultText,
                        constraint: field.constraint
                    )
                }
            }
        }
    }

    static func requireChoices(
        _ choices: [UserInputChoice]
    ) throws {
        guard !choices.isEmpty else {
            throw UserInputError.emptyChoices
        }

        var choiceIDs: Set<String> = []

        for choice in choices {
            try requireCanonicalIdentifier(
                choice.id,
                invalid: UserInputError.invalidChoiceID
            )

            guard choiceIDs.insert(choice.id).inserted else {
                throw UserInputError.duplicateChoiceID(
                    choice.id
                )
            }

            guard !choice.label.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty else {
                throw UserInputError.emptyChoiceLabel(
                    choice.id
                )
            }
        }
    }

    static func requireSelectionBounds(
        _ spec: MultiChoiceUserInput
    ) throws {
        guard spec.minimumSelectionCount >= 0 else {
            throw UserInputError.invalidSelectionBounds(
                minimum: spec.minimumSelectionCount,
                maximum: spec.maximumSelectionCount
            )
        }

        if let maximum = spec.maximumSelectionCount {
            guard maximum >= spec.minimumSelectionCount,
                  maximum <= spec.choices.count
            else {
                throw UserInputError.invalidSelectionBounds(
                    minimum: spec.minimumSelectionCount,
                    maximum: maximum
                )
            }
        } else {
            guard spec.minimumSelectionCount <= spec.choices.count else {
                throw UserInputError.invalidSelectionBounds(
                    minimum: spec.minimumSelectionCount,
                    maximum: nil
                )
            }
        }
    }

    static func requireTextConstraint(
        _ constraint: UserInputTextConstraint?
    ) throws {
        guard let constraint else {
            return
        }

        if let minimum = constraint.minimumLength,
           minimum < 0 {
            throw UserInputError.invalidTextBounds(
                minimum: minimum,
                maximum: constraint.maximumLength
            )
        }

        if let maximum = constraint.maximumLength,
           maximum < 0 {
            throw UserInputError.invalidTextBounds(
                minimum: constraint.minimumLength,
                maximum: maximum
            )
        }

        if let minimum = constraint.minimumLength,
           let maximum = constraint.maximumLength,
           minimum > maximum {
            throw UserInputError.invalidTextBounds(
                minimum: minimum,
                maximum: maximum
            )
        }
    }

    static func requireCanonicalIdentifier(
        _ value: String,
        invalid: (String) -> UserInputError
    ) throws {
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty,
              trimmed == value
        else {
            throw invalid(
                value
            )
        }
    }

    static func answer(
        _ answer: UserInputAnswer,
        for input: UserInputSpec
    ) throws -> UserInputAnswer {
        switch (input, answer) {
        case (.text(let spec), .text(let value)):
            return .text(
                try text(
                    value,
                    constraint: spec.constraint
                )
            )

        case (.single_choice(let spec), .single_choice(let value)):
            return .single_choice(
                try singleChoice(
                    value,
                    spec: spec
                )
            )

        case (.multi_choice(let spec), .multi_choice(let value)):
            return .multi_choice(
                try multiChoice(
                    value,
                    spec: spec
                )
            )

        case (.confirmation, .confirmation(let value)):
            return .confirmation(
                value
            )

        case (.form(let spec), .form(let value)):
            return .form(
                try form(
                    value,
                    spec: spec
                )
            )

        default:
            throw UserInputError.answerKindMismatch
        }
    }

    static func text(
        _ value: String,
        constraint: UserInputTextConstraint?
    ) throws -> String {
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let constraint = constraint ?? .init()

        if constraint.required,
           trimmed.isEmpty {
            throw UserInputError.emptyTextAnswer
        }

        if let minimum = constraint.minimumLength,
           trimmed.count < minimum {
            throw UserInputError.textTooShort(
                minimum
            )
        }

        if let maximum = constraint.maximumLength,
           trimmed.count > maximum {
            throw UserInputError.textTooLong(
                maximum
            )
        }

        return trimmed
    }

    static func singleChoice(
        _ answer: SingleChoiceUserInputAnswer,
        spec: SingleChoiceUserInput
    ) throws -> SingleChoiceUserInputAnswer {
        switch answer {
        case .choice(let rawID):
            let id = rawID.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !id.isEmpty else {
                throw UserInputError.emptyTextAnswer
            }

            guard spec.choices.contains(where: {
                $0.id == id
            }) else {
                throw UserInputError.unknownChoiceID(
                    id
                )
            }

            return .choice(
                id
            )

        case .custom(let rawValue):
            guard spec.allowsCustomValue else {
                throw UserInputError.customValueNotAllowed
            }

            let value = rawValue.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !value.isEmpty else {
                throw UserInputError.emptyCustomValue
            }

            return .custom(
                value
            )
        }
    }

    static func multiChoice(
        _ answer: MultiChoiceUserInputAnswer,
        spec: MultiChoiceUserInput
    ) throws -> MultiChoiceUserInputAnswer {
        let known = Set(
            spec.choices.map(\.id)
        )
        var seen: Set<String> = []
        var choiceIDs: [String] = []

        for rawID in answer.choiceIDs {
            let id = rawID.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !id.isEmpty else {
                continue
            }

            guard known.contains(id) else {
                throw UserInputError.unknownChoiceID(
                    id
                )
            }

            guard seen.insert(id).inserted else {
                continue
            }

            choiceIDs.append(
                id
            )
        }

        guard choiceIDs.count >= spec.minimumSelectionCount else {
            throw UserInputError.tooFewSelections(
                spec.minimumSelectionCount
            )
        }

        if let maximum = spec.maximumSelectionCount,
           choiceIDs.count > maximum {
            throw UserInputError.tooManySelections(
                maximum
            )
        }

        return .init(
            choiceIDs: choiceIDs
        )
    }

    static func form(
        _ answer: FormUserInputAnswer,
        spec: FormUserInput
    ) throws -> FormUserInputAnswer {
        let known = Set(
            spec.fields.map(\.id)
        )

        for id in answer.values.keys where !known.contains(id) {
            throw UserInputError.unknownFieldID(
                id
            )
        }

        var values: [String: String] = [:]

        for field in spec.fields {
            let rawValue = answer.values[field.id]
                ?? field.defaultText
                ?? ""
            let value = try text(
                rawValue,
                constraint: field.constraint
            )

            if !value.isEmpty {
                values[field.id] = value
            }
        }

        return .init(
            values: values
        )
    }
}

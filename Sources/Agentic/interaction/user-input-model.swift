import Foundation
import Macros
import Schema

public enum UserInputSpec:
    Sendable,
    Codable,
    Hashable,
    JSONSchemaProviding
{
    public static var jsonschema: JSONSchema {
        .any
    }

    case text(TextUserInput)
    case single_choice(SingleChoiceUserInput)
    case multi_choice(MultiChoiceUserInput)
    case confirmation(ConfirmationUserInput)
    case form(FormUserInput)

    private enum CodingKeys: String, CodingKey {
        case kind
        case text
        case single_choice
        case multi_choice
        case confirmation
        case form
    }

    private enum Kind: String, Codable {
        case text
        case single_choice
        case multi_choice
        case confirmation
        case form
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
        case .text:
            self = .text(
                try container.decode(
                    TextUserInput.self,
                    forKey: .text
                )
            )

        case .single_choice:
            self = .single_choice(
                try container.decode(
                    SingleChoiceUserInput.self,
                    forKey: .single_choice
                )
            )

        case .multi_choice:
            self = .multi_choice(
                try container.decode(
                    MultiChoiceUserInput.self,
                    forKey: .multi_choice
                )
            )

        case .confirmation:
            self = .confirmation(
                try container.decode(
                    ConfirmationUserInput.self,
                    forKey: .confirmation
                )
            )

        case .form:
            self = .form(
                try container.decode(
                    FormUserInput.self,
                    forKey: .form
                )
            )
        }
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        switch self {
        case .text(let value):
            try container.encode(
                Kind.text,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .text
            )

        case .single_choice(let value):
            try container.encode(
                Kind.single_choice,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .single_choice
            )

        case .multi_choice(let value):
            try container.encode(
                Kind.multi_choice,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .multi_choice
            )

        case .confirmation(let value):
            try container.encode(
                Kind.confirmation,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .confirmation
            )

        case .form(let value):
            try container.encode(
                Kind.form,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .form
            )
        }
    }
}

public struct TextUserInput: Sendable, Codable, Hashable {
    public var placeholder: String?
    public var defaultText: String?
    public var multiline: Bool
    public var constraint: UserInputTextConstraint?

    private enum CodingKeys: String, CodingKey {
        case placeholder
        case defaultText
        case multiline
        case validation
    }

    public init(
        placeholder: String? = nil,
        defaultText: String? = nil,
        multiline: Bool = false,
        constraint: UserInputTextConstraint? = nil
    ) {
        self.placeholder = placeholder
        self.defaultText = defaultText
        self.multiline = multiline
        self.constraint = constraint
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        placeholder = try container.decodeIfPresent(
            String.self,
            forKey: .placeholder
        )
        defaultText = try container.decodeIfPresent(
            String.self,
            forKey: .defaultText
        )
        multiline = try container.decodeIfPresent(
            Bool.self,
            forKey: .multiline
        ) ?? false
        constraint = try container.decodeIfPresent(
            UserInputTextConstraint.self,
            forKey: .validation
        )
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encodeIfPresent(
            placeholder,
            forKey: .placeholder
        )
        try container.encodeIfPresent(
            defaultText,
            forKey: .defaultText
        )
        try container.encode(
            multiline,
            forKey: .multiline
        )
        try container.encodeIfPresent(
            constraint,
            forKey: .validation
        )
    }
}

public struct SingleChoiceUserInput: Sendable, Codable, Hashable {
    public var choices: [UserInputChoice]
    public var defaultChoiceID: String?
    public var allowsCustomValue: Bool

    public init(
        choices: [UserInputChoice],
        defaultChoiceID: String? = nil,
        allowsCustomValue: Bool = false
    ) {
        self.choices = choices
        self.defaultChoiceID = defaultChoiceID
        self.allowsCustomValue = allowsCustomValue
    }
}

public struct MultiChoiceUserInput: Sendable, Codable, Hashable {
    public var choices: [UserInputChoice]
    public var defaultChoiceIDs: [String]
    public var minimumSelectionCount: Int
    public var maximumSelectionCount: Int?

    public init(
        choices: [UserInputChoice],
        defaultChoiceIDs: [String] = [],
        minimumSelectionCount: Int = 0,
        maximumSelectionCount: Int? = nil
    ) {
        self.choices = choices
        self.defaultChoiceIDs = defaultChoiceIDs
        self.minimumSelectionCount = minimumSelectionCount
        self.maximumSelectionCount = maximumSelectionCount
    }
}

public struct ConfirmationUserInput: Sendable, Codable, Hashable {
    public var defaultValue: Bool?
    public var confirmLabel: String
    public var cancelLabel: String

    public init(
        defaultValue: Bool? = nil,
        confirmLabel: String = "Confirm",
        cancelLabel: String = "Cancel"
    ) {
        self.defaultValue = defaultValue
        self.confirmLabel = confirmLabel
        self.cancelLabel = cancelLabel
    }
}

public struct FormUserInput: Sendable, Codable, Hashable {
    public var fields: [UserInputField]
    public var submitLabel: String?

    public init(
        fields: [UserInputField],
        submitLabel: String? = nil
    ) {
        self.fields = fields
        self.submitLabel = submitLabel
    }
}

public struct UserInputChoice: Sendable, Codable, Hashable, Identifiable {
    public var id: String
    public var label: String
    public var value: String
    public var description: String?
    public var isDefault: Bool
    public var isDestructive: Bool
    public var metadata: [String: String]

    public init(
        id: String,
        label: String,
        value: String,
        description: String? = nil,
        isDefault: Bool = false,
        isDestructive: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.description = description
        self.isDefault = isDefault
        self.isDestructive = isDestructive
        self.metadata = metadata
    }
}

public struct UserInputField: Sendable, Codable, Hashable, Identifiable {
    public var id: String
    public var label: String
    public var placeholder: String?
    public var defaultText: String?
    public var multiline: Bool
    public var requirement: UserInputRequirement
    public var constraint: UserInputTextConstraint?
    public var metadata: [String: String]

    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case placeholder
        case defaultText
        case multiline
        case requirement
        case validation
        case metadata
    }

    private struct LegacyConstraintRequirement: Decodable {
        let required: Bool?
    }

    public init(
        id: String,
        label: String,
        placeholder: String? = nil,
        defaultText: String? = nil,
        multiline: Bool = false,
        requirement: UserInputRequirement = .required,
        constraint: UserInputTextConstraint? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.label = label
        self.placeholder = placeholder
        self.defaultText = defaultText
        self.multiline = multiline
        self.requirement = requirement
        self.constraint = constraint
        self.metadata = metadata
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        id = try container.decode(
            String.self,
            forKey: .id
        )
        label = try container.decode(
            String.self,
            forKey: .label
        )
        placeholder = try container.decodeIfPresent(
            String.self,
            forKey: .placeholder
        )
        defaultText = try container.decodeIfPresent(
            String.self,
            forKey: .defaultText
        )
        multiline = try container.decodeIfPresent(
            Bool.self,
            forKey: .multiline
        ) ?? false

        let legacy = try container.decodeIfPresent(
            LegacyConstraintRequirement.self,
            forKey: .validation
        )

        requirement = try container.decodeIfPresent(
            UserInputRequirement.self,
            forKey: .requirement
        ) ?? (legacy?.required == false ? .optional : .required)
        constraint = try container.decodeIfPresent(
            UserInputTextConstraint.self,
            forKey: .validation
        )
        metadata = try container.decodeIfPresent(
            [String: String].self,
            forKey: .metadata
        ) ?? [:]
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            id,
            forKey: .id
        )
        try container.encode(
            label,
            forKey: .label
        )
        try container.encodeIfPresent(
            placeholder,
            forKey: .placeholder
        )
        try container.encodeIfPresent(
            defaultText,
            forKey: .defaultText
        )
        try container.encode(
            multiline,
            forKey: .multiline
        )
        try container.encode(
            requirement,
            forKey: .requirement
        )
        try container.encodeIfPresent(
            constraint,
            forKey: .validation
        )
        try container.encode(
            metadata,
            forKey: .metadata
        )
    }
}

public struct UserInputTextConstraint: Sendable, Codable, Hashable {
    public var allowsEmpty: Bool
    public var minimumLength: Int?
    public var maximumLength: Int?
    public var patternDescription: String?

    private enum CodingKeys: String, CodingKey {
        case allowsEmpty
        case required
        case minimumLength
        case maximumLength
        case patternDescription
    }

    public init(
        allowsEmpty: Bool = false,
        minimumLength: Int? = nil,
        maximumLength: Int? = nil,
        patternDescription: String? = nil
    ) {
        self.allowsEmpty = allowsEmpty
        self.minimumLength = minimumLength
        self.maximumLength = maximumLength
        self.patternDescription = patternDescription
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        if let allowsEmpty = try container.decodeIfPresent(
            Bool.self,
            forKey: .allowsEmpty
        ) {
            self.allowsEmpty = allowsEmpty
        } else if let legacyRequired = try container.decodeIfPresent(
            Bool.self,
            forKey: .required
        ) {
            self.allowsEmpty = !legacyRequired
        } else {
            self.allowsEmpty = false
        }

        minimumLength = try container.decodeIfPresent(
            Int.self,
            forKey: .minimumLength
        )
        maximumLength = try container.decodeIfPresent(
            Int.self,
            forKey: .maximumLength
        )
        patternDescription = try container.decodeIfPresent(
            String.self,
            forKey: .patternDescription
        )
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        try container.encode(
            allowsEmpty,
            forKey: .allowsEmpty
        )
        try container.encodeIfPresent(
            minimumLength,
            forKey: .minimumLength
        )
        try container.encodeIfPresent(
            maximumLength,
            forKey: .maximumLength
        )
        try container.encodeIfPresent(
            patternDescription,
            forKey: .patternDescription
        )
    }
}

@JSONSchema
public struct UserInputPresentation: Sendable, Codable, Hashable {
    public var title: String?
    public var help: String?
    public var preferredControl: UserInputControl?
    public var ordering: UserInputOrdering

    public init(
        title: String? = nil,
        help: String? = nil,
        preferredControl: UserInputControl? = nil,
        ordering: UserInputOrdering = .provided
    ) {
        self.title = title
        self.help = help
        self.preferredControl = preferredControl
        self.ordering = ordering
    }
}

@JSONSchema
public enum UserInputControl: String, Sendable, Codable, Hashable, CaseIterable {
    case text_field
    case text_area
    case radio_list
    case checkbox_list
    case confirmation
    case form
}

@JSONSchema
public enum UserInputOrdering: String, Sendable, Codable, Hashable, CaseIterable {
    case provided
    case alphabetical
    case grouped
}

public enum UserInputAnswer: Sendable, Codable, Hashable {
    case text(String)
    case single_choice(SingleChoiceUserInputAnswer)
    case multi_choice(MultiChoiceUserInputAnswer)
    case confirmation(Bool)
    case form(FormUserInputAnswer)

    private enum CodingKeys: String, CodingKey {
        case kind
        case text
        case single_choice
        case multi_choice
        case confirmation
        case form
    }

    private enum Kind: String, Codable {
        case text
        case single_choice
        case multi_choice
        case confirmation
        case form
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
        case .text:
            self = .text(
                try container.decode(
                    String.self,
                    forKey: .text
                )
            )

        case .single_choice:
            self = .single_choice(
                try container.decode(
                    SingleChoiceUserInputAnswer.self,
                    forKey: .single_choice
                )
            )

        case .multi_choice:
            self = .multi_choice(
                try container.decode(
                    MultiChoiceUserInputAnswer.self,
                    forKey: .multi_choice
                )
            )

        case .confirmation:
            self = .confirmation(
                try container.decode(
                    Bool.self,
                    forKey: .confirmation
                )
            )

        case .form:
            self = .form(
                try container.decode(
                    FormUserInputAnswer.self,
                    forKey: .form
                )
            )
        }
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        switch self {
        case .text(let value):
            try container.encode(
                Kind.text,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .text
            )

        case .single_choice(let value):
            try container.encode(
                Kind.single_choice,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .single_choice
            )

        case .multi_choice(let value):
            try container.encode(
                Kind.multi_choice,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .multi_choice
            )

        case .confirmation(let value):
            try container.encode(
                Kind.confirmation,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .confirmation
            )

        case .form(let value):
            try container.encode(
                Kind.form,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .form
            )
        }
    }
}

public enum SingleChoiceUserInputAnswer: Sendable, Codable, Hashable {
    case choice(String)
    case custom(String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case choice
        case custom
    }

    private enum Kind: String, Codable {
        case choice
        case custom
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
        case .choice:
            self = .choice(
                try container.decode(
                    String.self,
                    forKey: .choice
                )
            )

        case .custom:
            self = .custom(
                try container.decode(
                    String.self,
                    forKey: .custom
                )
            )
        }
    }

    public func encode(
        to encoder: any Encoder
    ) throws {
        var container = encoder.container(
            keyedBy: CodingKeys.self
        )

        switch self {
        case .choice(let id):
            try container.encode(
                Kind.choice,
                forKey: .kind
            )
            try container.encode(
                id,
                forKey: .choice
            )

        case .custom(let value):
            try container.encode(
                Kind.custom,
                forKey: .kind
            )
            try container.encode(
                value,
                forKey: .custom
            )
        }
    }
}

public struct MultiChoiceUserInputAnswer: Sendable, Codable, Hashable {
    public var choiceIDs: [String]

    public init(
        choiceIDs: [String]
    ) {
        self.choiceIDs = choiceIDs
    }
}

public struct FormUserInputAnswer: Sendable, Codable, Hashable {
    public var values: [String: String]

    public init(
        values: [String: String]
    ) {
        self.values = values
    }
}

public enum UserInputError: Error, Sendable, LocalizedError, Equatable {
    case emptyPrompt
    case emptyChoices
    case duplicateChoiceID(String)
    case invalidChoiceID(String)
    case emptyChoiceLabel(String)
    case unknownDefaultChoiceID(String)
    case invalidSelectionBounds(minimum: Int, maximum: Int?)
    case invalidTextBounds(minimum: Int?, maximum: Int?)
    case emptyConfirmationLabel
    case emptyForm
    case duplicateFieldID(String)
    case invalidFieldID(String)
    case emptyFieldLabel(String)
    case answerKindMismatch
    case emptyTextAnswer
    case textTooShort(Int)
    case textTooLong(Int)
    case unknownChoiceID(String)
    case customValueNotAllowed
    case emptyCustomValue
    case tooFewSelections(Int)
    case tooManySelections(Int)
    case unknownFieldID(String)
    case requiredInputCannotBeSkipped
    case missingRequiredField(String)

    public var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "User input request requires a non-empty prompt."
        case .emptyChoices:
            return "Choice input requires at least one choice."
        case .duplicateChoiceID(let id):
            return "Choice id '\(id)' appears more than once."
        case .invalidChoiceID(let id):
            return "Choice id '\(id)' must be non-empty and must not contain surrounding whitespace."
        case .emptyChoiceLabel(let id):
            return "Choice '\(id)' requires a non-empty label."
        case .unknownDefaultChoiceID(let id):
            return "Default choice id '\(id)' is not present in the declared choices."
        case .invalidSelectionBounds(let minimum, let maximum):
            if let maximum {
                return "Selection bounds are invalid: minimum \(minimum), maximum \(maximum)."
            }
            return "Selection minimum must not be negative: \(minimum)."
        case .invalidTextBounds(let minimum, let maximum):
            return "Text length bounds are invalid: minimum \(String(describing: minimum)), maximum \(String(describing: maximum))."
        case .emptyConfirmationLabel:
            return "Confirmation labels must be non-empty."
        case .emptyForm:
            return "Form input requires at least one field."
        case .duplicateFieldID(let id):
            return "Form field id '\(id)' appears more than once."
        case .invalidFieldID(let id):
            return "Form field id '\(id)' must be non-empty and must not contain surrounding whitespace."
        case .emptyFieldLabel(let id):
            return "Form field '\(id)' requires a non-empty label."
        case .answerKindMismatch:
            return "Answer kind does not match requested input kind."
        case .emptyTextAnswer:
            return "Text answer must not be empty."
        case .textTooShort(let minimum):
            return "Text answer must contain at least \(minimum) character(s)."
        case .textTooLong(let maximum):
            return "Text answer must contain at most \(maximum) character(s)."
        case .unknownChoiceID(let id):
            return "Unknown choice id '\(id)'."
        case .customValueNotAllowed:
            return "Custom values are not allowed for this single-choice input."
        case .emptyCustomValue:
            return "Custom choice value must not be empty."
        case .tooFewSelections(let minimum):
            return "Expected at least \(minimum) selected choice(s)."
        case .tooManySelections(let maximum):
            return "Expected at most \(maximum) selected choice(s)."
        case .unknownFieldID(let id):
            return "Unknown form field id '\(id)'."
        case .requiredInputCannotBeSkipped:
            return "Required user input cannot be skipped."
        case .missingRequiredField(let id):
            return "Required form field '\(id)' is missing."
        }
    }
}


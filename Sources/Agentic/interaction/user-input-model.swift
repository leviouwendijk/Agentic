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
        JSONSchema(
            form: .oneOf([
                variant(
                    kind: "text",
                    payload: "text",
                    schema: TextUserInput.jsonschema,
                    description: "Configuration for free-form textual user input."
                ),
                variant(
                    kind: "single_choice",
                    payload: "single_choice",
                    schema: SingleChoiceUserInput.jsonschema,
                    description: "Configuration for choosing exactly one value."
                ),
                variant(
                    kind: "multi_choice",
                    payload: "multi_choice",
                    schema: MultiChoiceUserInput.jsonschema,
                    description: "Configuration for choosing zero or more values."
                ),
                variant(
                    kind: "confirmation",
                    payload: "confirmation",
                    schema: ConfirmationUserInput.jsonschema,
                    description: "Configuration for a boolean confirmation."
                ),
                variant(
                    kind: "form",
                    payload: "form",
                    schema: FormUserInput.jsonschema,
                    description: "Configuration for a structured form."
                ),
            ]),
            description: """
            Semantic user-input specification. The `kind` discriminator must be one of `text`, `single_choice`, `multi_choice`, `confirmation`, or `form`, and the matching payload must use the same-named property. Presentation controls such as `text_field` and `text_area` belong to `presentation.preferredControl` and are not valid `kind` values.
            """
        )
    }

    private static func variant(
        kind: String,
        payload: String,
        schema: JSONSchema,
        description: String
    ) -> JSONSchema {
        .object(
            properties: [
                .init(
                    name: "kind",
                    schema: .string(
                        cases: [
                            kind,
                        ]
                    ),
                    required: true,
                    description: "Semantic input kind for this branch."
                ),
                .init(
                    name: payload,
                    schema: schema,
                    required: true,
                    description: description
                ),
            ],
            additionalProperties: .disallowed
        )
    }

    /// Request free-form textual input. Encode its configuration under `text`.
    case text(TextUserInput)

    /// Request exactly one choice. Encode its configuration under `single_choice`.
    case single_choice(SingleChoiceUserInput)

    /// Request zero or more choices. Encode its configuration under `multi_choice`.
    case multi_choice(MultiChoiceUserInput)

    /// Request a boolean confirmation. Encode its configuration under `confirmation`.
    case confirmation(ConfirmationUserInput)

    /// Request a structured set of textual fields. Encode its configuration under `form`.
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

/// Configuration for free-form textual user input.
public struct TextUserInput:
    Sendable,
    Codable,
    Hashable,
    JSONSchemaProviding
{
    /// Placeholder shown before the user enters text.
    public var placeholder: String?

    /// Initial text offered to the user, if any.
    public var defaultText: String?

    /// Whether the interface should support multiline text entry.
    public var multiline: Bool

    /// Optional validation constraints for the submitted text.
    public var constraint: UserInputTextConstraint?

    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                .init(
                    name: "placeholder",
                    schema: String.jsonschema,
                    description: "Placeholder shown before the user enters text."
                ),
                .init(
                    name: "defaultText",
                    schema: String.jsonschema,
                    description: "Initial text offered to the user, if any."
                ),
                .init(
                    name: "multiline",
                    schema: Bool.jsonschema,
                    description: "Whether the interface should support multiline text entry. Defaults to false when omitted."
                ),
                .init(
                    name: "validation",
                    schema: UserInputTextConstraint.jsonschema,
                    description: "Optional validation constraints for the submitted text."
                ),
            ],
            additionalProperties: .disallowed
        )
    }

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

/// Configuration for selecting exactly one value from a declared choice set.
@JSONSchema
public struct SingleChoiceUserInput: Sendable, Codable, Hashable {
    /// Choices available to the user.
    public var choices: [UserInputChoice]

    /// Identifier of the initially selected choice, if any.
    public var defaultChoiceID: String?

    /// Whether the user may supply a value not represented by a declared choice.
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

/// Configuration for selecting multiple values from a declared choice set.
@JSONSchema
public struct MultiChoiceUserInput: Sendable, Codable, Hashable {
    /// Choices available to the user.
    public var choices: [UserInputChoice]

    /// Choice identifiers selected initially.
    public var defaultChoiceIDs: [String]

    /// Minimum number of choices the user must select.
    public var minimumSelectionCount: Int

    /// Maximum number of choices the user may select, or no maximum when omitted.
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

/// Configuration for a boolean confirmation request.
@JSONSchema
public struct ConfirmationUserInput: Sendable, Codable, Hashable {
    /// Initially selected confirmation value, if any.
    public var defaultValue: Bool?

    /// Label shown for the affirmative action.
    public var confirmLabel: String

    /// Label shown for the negative action.
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

/// Configuration for a structured form composed of textual fields.
@JSONSchema
public struct FormUserInput: Sendable, Codable, Hashable {
    /// Fields presented to the user in the form.
    public var fields: [UserInputField]

    /// Optional label for the form submission action.
    public var submitLabel: String?

    public init(
        fields: [UserInputField],
        submitLabel: String? = nil
    ) {
        self.fields = fields
        self.submitLabel = submitLabel
    }
}

/// One semantic choice that may be presented to the user.
@JSONSchema
public struct UserInputChoice: Sendable, Codable, Hashable, Identifiable {
    /// Stable identifier used when returning this choice.
    public var id: String

    /// Human-readable label shown to the user.
    public var label: String

    /// Semantic value represented by the choice.
    public var value: String

    /// Additional explanation associated with the choice.
    public var description: String?

    /// Whether this choice should initially be selected.
    public var isDefault: Bool

    /// Whether selecting this choice represents a destructive action.
    public var isDestructive: Bool

    /// Additional application-defined metadata.
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

/// One textual field in a structured user-input form.
public struct UserInputField:
    Sendable,
    Codable,
    Hashable,
    Identifiable,
    JSONSchemaProviding
{
    /// Stable identifier used to associate the returned value with this field.
    public var id: String

    /// Human-readable label shown for this field.
    public var label: String

    /// Placeholder shown before the user enters text.
    public var placeholder: String?

    /// Initial text offered for this field, if any.
    public var defaultText: String?

    /// Whether this field should support multiline text entry.
    public var multiline: Bool

    /// Whether the user must provide this field.
    public var requirement: UserInputRequirement

    /// Optional validation constraints for the field value.
    public var constraint: UserInputTextConstraint?

    /// Additional application-defined metadata.
    public var metadata: [String: String]

    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                .init(
                    name: "id",
                    schema: String.jsonschema,
                    required: true,
                    description: "Stable identifier used to associate the returned value with this field."
                ),
                .init(
                    name: "label",
                    schema: String.jsonschema,
                    required: true,
                    description: "Human-readable label shown for this field."
                ),
                .init(
                    name: "placeholder",
                    schema: String.jsonschema,
                    description: "Placeholder shown before the user enters text."
                ),
                .init(
                    name: "defaultText",
                    schema: String.jsonschema,
                    description: "Initial text offered for this field, if any."
                ),
                .init(
                    name: "multiline",
                    schema: Bool.jsonschema,
                    description: "Whether this field should support multiline text entry. Defaults to false when omitted."
                ),
                .init(
                    name: "requirement",
                    schema: UserInputRequirement.jsonschema,
                    description: "Whether the user must provide this field. Defaults to required when omitted."
                ),
                .init(
                    name: "validation",
                    schema: UserInputTextConstraint.jsonschema,
                    description: "Optional validation constraints for the field value."
                ),
                .init(
                    name: "metadata",
                    schema: [String: String].jsonschema,
                    description: "Additional application-defined metadata."
                ),
            ],
            additionalProperties: .disallowed
        )
    }

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

/// Validation constraints applied to textual user input.
public struct UserInputTextConstraint:
    Sendable,
    Codable,
    Hashable,
    JSONSchemaProviding
{
    /// Whether an empty textual value is accepted.
    public var allowsEmpty: Bool

    /// Minimum accepted character count, if constrained.
    public var minimumLength: Int?

    /// Maximum accepted character count, if constrained.
    public var maximumLength: Int?

    /// Human-readable description of any content pattern the value should satisfy.
    public var patternDescription: String?

    public static var jsonschema: JSONSchema {
        .object(
            properties: [
                .init(
                    name: "allowsEmpty",
                    schema: Bool.jsonschema,
                    description: "Whether an empty textual value is accepted. Defaults to false when omitted."
                ),
                .init(
                    name: "minimumLength",
                    schema: Int.jsonschema,
                    description: "Minimum accepted character count, if constrained."
                ),
                .init(
                    name: "maximumLength",
                    schema: Int.jsonschema,
                    description: "Maximum accepted character count, if constrained."
                ),
                .init(
                    name: "patternDescription",
                    schema: String.jsonschema,
                    description: "Human-readable description of any content pattern the value should satisfy."
                ),
            ],
            additionalProperties: .disallowed
        )
    }

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

/// Optional presentation hints for rendering a semantic user-input request.
/// Presentation does not determine `UserInputSpec.kind`.
@JSONSchema
public struct UserInputPresentation: Sendable, Codable, Hashable {
    /// Optional title shown with the request.
    public var title: String?

    /// Optional explanatory help shown with the request.
    public var help: String?

    /// Preferred visual control. This is presentation-only and does not determine `UserInputSpec.kind`.
    public var preferredControl: UserInputControl?

    /// Preferred ordering for choices or form elements.
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

/// Presentation-only control hint for rendering user input.
/// Values such as `text_field` and `text_area` are not semantic `UserInputSpec.kind` values.
@JSONSchema
public enum UserInputControl: String, Sendable, Codable, Hashable, CaseIterable {
    case text_field
    case text_area
    case radio_list
    case checkbox_list
    case confirmation
    case form
}

/// Presentation ordering applied without changing the semantic input kind.
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


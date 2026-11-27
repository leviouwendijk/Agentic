import Foundation
import Macros
import Schema
import Surface

public struct UserInputRequest: Sendable, Codable, Hashable, JSONSchemaProviding {
    @JSONSchema
    public struct Raw: Sendable, Codable, Hashable {
        public var prompt: String
        public var reason: String?
        public var requirement: SurfaceQuestion.Requirement?
        public var input: SurfaceQuestion
        public var presentation: SurfaceQuestion.Presentation?
        public var metadata: [String: String]

        public init(
            prompt: String,
            reason: String? = nil,
            requirement: SurfaceQuestion.Requirement? = nil,
            input: SurfaceQuestion = .text(
                .init()
            ),
            presentation: SurfaceQuestion.Presentation? = nil,
            metadata: [String: String] = [:]
        ) {
            self.prompt = prompt
            self.reason = reason
            self.requirement = requirement
            self.input = input
            self.presentation = presentation
            self.metadata = metadata
        }
    }

    public static var jsonschema: JSONSchema {
        Raw.jsonschema
    }

    public let prompt: String
    public let reason: String?
    public let requirement: SurfaceQuestion.Requirement
    public let input: SurfaceQuestion
    public let presentation: SurfaceQuestion.Presentation?
    public let metadata: [String: String]

    public init(
        _ raw: Raw
    ) throws {
        guard !raw.prompt.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            throw SurfaceQuestion.Error.emptyPrompt
        }

        try raw.input.validate()

        prompt = raw.prompt
        reason = raw.reason
        requirement = raw.requirement ?? .required
        input = raw.input
        presentation = raw.presentation
        metadata = raw.metadata
    }

    public init(
        prompt: String,
        reason: String? = nil,
        requirement: SurfaceQuestion.Requirement = .required,
        input: SurfaceQuestion = .text(
            .init()
        ),
        presentation: SurfaceQuestion.Presentation? = nil,
        metadata: [String: String] = [:]
    ) throws {
        try self.init(
            .init(
                prompt: prompt,
                reason: reason,
                requirement: requirement,
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
            requirement: requirement,
            input: input,
            presentation: presentation,
            metadata: metadata
        ).encode(
            to: encoder
        )
    }
}


public struct UserInputResponse: Sendable, Hashable {
    public enum Outcome: Sendable, Hashable {
        case answered(SurfaceAnswer)
        case skipped
    }

    public let outcome: Outcome

    public init(
        _ reply: UserInputReply,
        for request: UserInputRequest
    ) throws {
        switch reply {
        case .answer(let answer):
            outcome = .answered(
                try request.input.refine(
                    answer
                )
            )

        case .skip:
            guard request.requirement == .optional else {
                throw SurfaceQuestion.Error.requiredInputCannotBeSkipped
            }

            outcome = .skipped
        }
    }

    public init(
        answer: SurfaceAnswer,
        for request: UserInputRequest
    ) throws {
        try self.init(
            .answer(
                answer
            ),
            for: request
        )
    }

    public init(
        skipping request: UserInputRequest
    ) throws {
        try self.init(
            .skip,
            for: request
        )
    }

    public var answer: SurfaceAnswer? {
        guard case .answered(let answer) = outcome else {
            return nil
        }

        return answer
    }

    public var reply: UserInputReply {
        switch outcome {
        case .answered(let answer):
            return .answer(
                answer
            )

        case .skipped:
            return .skip
        }
    }

    public var isSkipped: Bool {
        if case .skipped = outcome {
            return true
        }

        return false
    }
}

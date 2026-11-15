import Foundation
import Primitives
import Schema

/// How a structured output travels to a model and back.
public enum AgentOutputRepresentation: String, Sendable, Codable, Hashable, CaseIterable {
    /// The provider enforces the schema (`responseFormat: .jsonschema`).
    case native_schema
    /// The schema is an instruction; the answer arrives as text.
    case prompted_json
}

/// A structured output contract: which representation a model gets, how
/// the request says so, and how the answer is parsed. Shared by inference
/// adapters, delegated agents and the model broker, so there is one
/// implementation of each step.
public struct AgentOutputContract: Sendable, Hashable {
    public let schema: JSONSchema

    public init(
        schema: JSONSchema
    ) {
        self.schema = schema
    }

    /// Native when the profile enforces schemas, prompted otherwise.
    public func representation(
        for profile: AgentModelProfile
    ) -> AgentOutputRepresentation {
        profile.capabilities.contains(.structured_output) ? .native_schema : .prompted_json
    }

    /// `request` as `representation` asks for this contract.
    public func requesting(
        _ request: AgentRequest,
        as representation: AgentOutputRepresentation
    ) throws -> AgentRequest {
        var request = request
        switch representation {
        case .native_schema:
            request.responseFormat = .jsonschema(schema)
        case .prompted_json:
            request.responseFormat = .text
            let instruction = Message(
                role: .system,
                text: try instruction()
            )
            let leading = request.messages.prefix { $0.role == .system }.count
            request.messages.insert(instruction, at: leading)
        }
        return request
    }

    /// The answer, parsed against this contract.
    public func parse(
        _ answer: String
    ) throws(AgentOutputFailure) -> AgentStructuredAnswer {
        try AgentStructuredAnswer(.init(text: answer, contract: self))
    }

    /// What a repair turn tells the model about a failed answer.
    public func repairInstruction(
        for failure: AgentOutputFailure
    ) -> String {
        """
        Your previous answer could not be used: \(failure).
        Reply with only the corrected JSON value for the required schema: \
        no prose and no code fences. Do not redo the work; restate the result.
        """
    }

    func instruction() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let text = String(decoding: try encoder.encode(schema.jsonvalue), as: UTF8.self)
        return """
            Your final answer must be only a JSON value that conforms to this JSON Schema: \
            no prose before or after it and no code fences. Tool calls before the final \
            answer are unaffected.
            \(text)
            """
    }
}

/// A model's answer parsed into the value its contract requires: JSON,
/// possibly inside one code fence, that conforms to the schema.
public struct AgentStructuredAnswer: Invariant, Sendable, Hashable {
    public struct Raw: Sendable, Hashable {
        public var text: String
        public var contract: AgentOutputContract

        public init(
            text: String,
            contract: AgentOutputContract
        ) {
            self.text = text
            self.contract = contract
        }
    }

    public let value: JSONValue

    public init(
        _ raw: Raw
    ) throws(AgentOutputFailure) {
        let text = Self.unfenced(raw.text)
        guard !text.isEmpty else {
            throw .empty
        }
        guard let json = try? JSONDecoder().decode(JSONValue.self, from: Data(text.utf8)) else {
            throw .not_json
        }
        do {
            self.value = try JSONSchemaConforming(.init(value: json, schema: raw.contract.schema)).value
        } catch {
            throw .nonconforming(error.description)
        }
    }

    /// Decodes the conforming value into the contract's Swift type.
    public func decoded<T: Decodable>(
        as type: T.Type
    ) throws -> T {
        try JSONDecoder().decode(type, from: JSONEncoder().encode(value))
    }

    /// The text inside a single ``` fence, else the text itself.
    static func unfenced(
        _ text: String
    ) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```"), trimmed.hasSuffix("```"), trimmed.count > 6 else {
            return trimmed
        }
        let inner = trimmed.dropFirst(3).dropLast(3)
        let body = inner.firstIndex(of: "\n").map { inner[inner.index(after: $0)...] } ?? inner
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum AgentOutputFailure: Error, Sendable, Hashable, CustomStringConvertible, LocalizedError {
    case empty
    case not_json
    case nonconforming(String)

    public var description: String {
        switch self {
        case .empty:
            return "the answer is empty"
        case .not_json:
            return "the answer is not JSON"
        case .nonconforming(let reason):
            return "the answer does not satisfy the output contract (\(reason))"
        }
    }

    public var errorDescription: String? { description }
}

import Primitives

public struct ProgramIdentifier: StringIdentifier {
    public let rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }
}

public struct ProgramDefinition:
    Definition,
    Codable,
    Hashable
{
    public let identifier: ProgramIdentifier
    public let purpose: String
    public let title: String?
    public let tags: [String]

    public init(
        identifier: ProgramIdentifier,
        purpose: String,
        title: String? = nil,
        tags: [String] = []
    ) {
        self.identifier = identifier
        self.purpose = purpose
        self.title = title
        self.tags = tags
    }
}

public protocol Program: Sendable {
    associatedtype Input:
        Codable & Sendable

    associatedtype Output:
        Codable & Sendable

    static var definition: ProgramDefinition { get }

    func run(
        _ input: Input,
        in context: ProgramContext
    ) async throws -> Output
}

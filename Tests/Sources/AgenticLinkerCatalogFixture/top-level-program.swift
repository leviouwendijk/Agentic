import Agentic
import Macros
import Schema

@DomainMember(LinkerCatalogFixture.self)
@Program
public struct LinkerCatalogTopLevelProgram {
    @JSONSchema
    public struct Input: HashableSource {
        public init() {}
    }
    @JSONSchema
    public struct Output: HashableResult {
        public let text: String
        public init(text: String) { self.text = text }
    }
    public static let purpose = "Proves typed Domain membership for an external @Program."
    public init() {}
    public func run(_ input: Input, in context: ProgramContext) async throws -> Output {
        _ = input
        _ = context
        return Output(text: "linked")
    }
}

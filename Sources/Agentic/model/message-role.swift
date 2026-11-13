import Macros
import Schema

@JSONSchema
public enum MessageRole: String, Sendable, Codable, Hashable, CaseIterable {
    case system
    case user
    case assistant
    case tool
}

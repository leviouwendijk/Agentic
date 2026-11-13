import Macros
import Schema
/// Kind of media a resource holds.
@JSONSchema
public enum AgentModality:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case text
    case image
    case audio
    case video
    case document
}

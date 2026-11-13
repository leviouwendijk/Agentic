import Macros
import Schema

/// One block of message content.
@JSONSchema
public enum MessageContentBlock: Sendable, Codable, Hashable {
    /// Plain text.
    case text(String)
    /// An attached resource, such as an image or document.
    case resource(AgentResource)
    /// A function call emitted by the model.
    case call(FunctionCall)
    /// The response returned to the model for a function call.
    case result(ToolExecution.Response)
}

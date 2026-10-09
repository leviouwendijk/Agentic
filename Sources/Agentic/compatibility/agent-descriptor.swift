import Primitives

public extension AgentDescriptor {
    @available(*, deprecated, renamed: "input")
    var inputSchema: JSONValue { input }

    @available(*, deprecated, renamed: "output")
    var outputSchema: JSONValue { output }

    @available(*, deprecated, renamed: "init(identifier:description:input:output:)")
    init(identifier: AgentIdentifier, description: String, inputSchema: JSONValue, outputSchema: JSONValue) {
        self.init(identifier: identifier, description: description, input: inputSchema, output: outputSchema)
    }
}

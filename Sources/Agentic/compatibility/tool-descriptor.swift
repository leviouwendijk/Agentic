import Primitives

public extension ToolDescriptor {
    @available(*, deprecated, renamed: "input")
    var inputSchema: JSONValue? { input }

    @available(*, deprecated, renamed: "init(identifier:description:input:risk:)")
    init(identifier: ToolIdentifier, description: String, inputSchema: JSONValue?, risk: ActionRisk = .observe) {
        self.init(identifier: identifier, description: description, input: inputSchema, risk: risk)
    }

    @available(*, deprecated, renamed: "init(name:description:input:risk:)")
    init(name: String, description: String, inputSchema: JSONValue?, risk: ActionRisk = .observe) {
        self.init(name: name, description: description, input: inputSchema, risk: risk)
    }
}

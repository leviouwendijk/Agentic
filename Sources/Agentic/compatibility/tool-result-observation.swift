extension ToolResultObservation.Origin {
        @available(
            *,
            deprecated,
            message: "Use call.id instead."
        )
        public var toolCallID: String {
            call.id
        }
}

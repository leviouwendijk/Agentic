public func collection(
    _ identifier: AgentToolCollectionIdentifier,
    title: String? = nil,
    @AgentToolBuilder
    _ content: () throws -> [ToolBinding]
) rethrows -> [ToolBinding] {
    let metadata = AgentToolCollectionMetadata(
        identifier: identifier,
        title: title ?? identifier.rawValue
    )

    return try content().map { binding in
        binding.assigning(
            collection: metadata
        )
    }
}

public func collection(
    _ identifier: AgentToolCollectionIdentifier,
    title: String? = nil,
    @AgentToolBuilder
    _ content: () throws -> [AgentToolRegistration]
) rethrows -> [AgentToolRegistration] {
    let metadata = AgentToolCollectionMetadata(
        identifier: identifier,
        title: title ?? identifier.rawValue
    )

    return try content().map { registration in
        registration.assigning(
            collection: metadata
        )
    }
}

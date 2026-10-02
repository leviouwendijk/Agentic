public extension Catalog {
    /// Expands authored Domain selections into concrete identifiers while
    /// preserving explicit members even when they are not present in this
    /// semantic Catalog. Runtime must intersect the result with its installed
    /// executable universe before treating it as authority.
    func resolve(
        _ capabilities: AgentCapabilities
    ) -> AgentCapabilitySet {
        AgentCapabilitySet(
            tools: resolve(
                capabilities.tools
            ) { declaration in
                guard case .tool(let definition) = declaration else {
                    return nil
                }

                return definition.identifier
            },
            programs: resolve(
                capabilities.programs
            ) { declaration in
                guard case .program(let definition) = declaration else {
                    return nil
                }

                return definition.identifier
            },
            inferences: resolve(
                capabilities.inferences
            ) { declaration in
                guard case .inference(let definition) = declaration else {
                    return nil
                }

                return definition.identifier
            },
            agents: resolve(
                capabilities.agents
            ) { declaration in
                guard case .agent(let definition) = declaration else {
                    return nil
                }

                return definition.identifier
            }
        )
    }
}

private extension Catalog {
    func resolve<Identifier>(
        _ selection: AgentCapabilitySelection<Identifier>,
        identifier: (Declaration) -> Identifier?
    ) -> [Identifier]
    where
        Identifier: Sendable,
        Identifier: Codable,
        Identifier: Hashable
    {
        let selectedDomains = Set(
            selection.domains
        )
        let excluded = Set(
            selection.excluding
        )
        var seen = Set<Identifier>()
        var resolved: [Identifier] = []

        func append(
            _ identifier: Identifier
        ) {
            guard
                !excluded.contains(identifier),
                seen.insert(identifier).inserted
            else {
                return
            }

            resolved.append(
                identifier
            )
        }

        for member in selection.members {
            append(
                member
            )
        }

        for entry in entries {
            guard
                let namespace = entry.namespace,
                selectedDomains.contains(namespace),
                let resolvedIdentifier = identifier(
                    entry.declaration
                )
            else {
                continue
            }

            append(
                resolvedIdentifier
            )
        }

        return resolved
    }
}

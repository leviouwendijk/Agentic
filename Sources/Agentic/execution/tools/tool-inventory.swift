public struct ToolInventoryEntry:
    Sendable
{
    public let identifier: ToolIdentifier
    public let title: String
    public let description: String
    public let risk: ActionRisk
    public let isModelFacing: Bool
    public let collectionIdentifier:
        AgentToolCollectionIdentifier

    public init(
        identifier: ToolIdentifier,
        title: String,
        description: String,
        risk: ActionRisk,
        isModelFacing: Bool,
        collectionIdentifier:
            AgentToolCollectionIdentifier
    ) {
        self.identifier = identifier
        self.title = title
        self.description = description
        self.risk = risk
        self.isModelFacing = isModelFacing
        self.collectionIdentifier = collectionIdentifier
    }
}

public struct ToolInventoryCollection:
    Sendable
{
    public let identifier: AgentToolCollectionIdentifier
    public let title: String
    public let toolIdentifiers: [ToolIdentifier]

    public init(
        identifier: AgentToolCollectionIdentifier,
        title: String,
        toolIdentifiers: [ToolIdentifier]
    ) {
        self.identifier = identifier
        self.title = title
        self.toolIdentifiers = toolIdentifiers
    }
}

public enum ToolInventoryError:
    Error,
    Sendable
{
    case conflictingCollectionMetadata(
        AgentToolCollectionIdentifier
    )
    case toolAssignedToMultipleCollections(
        ToolIdentifier
    )
    case registeredToolMissingFromCompletedRegistry(
        ToolIdentifier
    )
}

public struct ToolInventory:
    Sendable
{
    public let collections: [ToolInventoryCollection]
    public let entries: [ToolInventoryEntry]

    public init(
        collections: [ToolInventoryCollection],
        entries: [ToolInventoryEntry]
    ) {
        self.collections = collections
        self.entries = entries
    }

    public var modelFacingEntries: [ToolInventoryEntry] {
        entries.filter(
            \.isModelFacing
        )
    }

    public func collection(
        identifiedBy identifier: AgentToolCollectionIdentifier
    ) -> ToolInventoryCollection? {
        collections.first { collection in
            collection.identifier == identifier
        }
    }

    public func entry(
        identifiedBy identifier: ToolIdentifier
    ) -> ToolInventoryEntry? {
        entries.first { entry in
            entry.identifier == identifier
        }
    }

    public static func materialize(
        registrations: [AgentToolRegistration],
        registry: ToolRegistry
    ) throws -> Self {
        var metadataByIdentifier:
            [AgentToolCollectionIdentifier: AgentToolCollectionMetadata] = [:]
        var registrationGroups:
            [AgentToolCollectionIdentifier: [AgentToolRegistration]] = [:]
        var collectionOrder:
            [AgentToolCollectionIdentifier] = []

        for registration in registrations {
            let metadata = registration.collection
                ?? .ungrouped
            let identifier = metadata.identifier

            if let existing = metadataByIdentifier[identifier] {
                guard existing == metadata else {
                    throw ToolInventoryError
                        .conflictingCollectionMetadata(
                            identifier
                        )
                }
            } else {
                metadataByIdentifier[identifier] = metadata
                collectionOrder.append(
                    identifier
                )
            }

            registrationGroups[identifier, default: []]
                .append(
                    registration
                )
        }

        let completedInspection = registry.inspect()
        let completedByIdentifier = Dictionary(
            uniqueKeysWithValues:
                completedInspection.tools.map { entry in
                    (
                        entry.identifier,
                        entry
                    )
                }
        )

        var claimedIdentifiers:
            Set<ToolIdentifier> = []
        var collections: [ToolInventoryCollection] = []
        var entries: [ToolInventoryEntry] = []

        for collectionIdentifier in collectionOrder {
            guard let metadata =
                metadataByIdentifier[collectionIdentifier]
            else {
                continue
            }

            var isolatedRegistry = ToolRegistry()

            for registration in
                registrationGroups[collectionIdentifier] ?? []
            {
                try registration.apply(
                    into: &isolatedRegistry
                )
            }

            let toolIdentifiers = isolatedRegistry
                .inspect()
                .tools
                .map(
                    \.identifier
                )

            for toolIdentifier in toolIdentifiers {
                guard claimedIdentifiers.insert(
                    toolIdentifier
                ).inserted else {
                    throw ToolInventoryError
                        .toolAssignedToMultipleCollections(
                            toolIdentifier
                        )
                }

                guard let inspection =
                    completedByIdentifier[toolIdentifier]
                else {
                    throw ToolInventoryError
                        .registeredToolMissingFromCompletedRegistry(
                            toolIdentifier
                        )
                }

                entries.append(
                    inventoryEntry(
                        inspection: inspection,
                        collection: metadata
                    )
                )
            }

            collections.append(
                .init(
                    identifier: metadata.identifier,
                    title: metadata.title,
                    toolIdentifiers: toolIdentifiers
                )
            )
        }

        let unclaimed = completedInspection.tools.filter { inspection in
            !claimedIdentifiers.contains(
                inspection.identifier
            )
        }

        if !unclaimed.isEmpty {
            let metadata = AgentToolCollectionMetadata.ungrouped
            let identifiers = unclaimed.map(
                \.identifier
            )

            if let index = collections.firstIndex(
                where: { collection in
                    collection.identifier == metadata.identifier
                }
            ) {
                let collection = collections[index]

                collections[index] = .init(
                    identifier: collection.identifier,
                    title: collection.title,
                    toolIdentifiers:
                        collection.toolIdentifiers
                        + identifiers
                )
            } else {
                collections.append(
                    .init(
                        identifier: metadata.identifier,
                        title: metadata.title,
                        toolIdentifiers: identifiers
                    )
                )
            }

            entries.append(
                contentsOf: unclaimed.map { inspection in
                    inventoryEntry(
                        inspection: inspection,
                        collection: metadata
                    )
                }
            )
        }

        return .init(
            collections: collections,
            entries: entries
        )
    }

    private static func inventoryEntry(
        inspection: ToolRegistryInspectionEntry,
        collection: AgentToolCollectionMetadata
    ) -> ToolInventoryEntry {
        .init(
            identifier: inspection.identifier,
            title: inspection.identifier.rawValue,
            description: inspection.description,
            risk: inspection.risk,
            isModelFacing: inspection.isModelFacing,
            collectionIdentifier: collection.identifier
        )
    }
}

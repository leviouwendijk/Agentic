import Agentic
import Macros
import Schema
import Testing

extension ExecutionTesting {
    static func runToolInventory()
        async throws
        -> [TestDiagnostic]
    {
        let registrations = tools {
            collection(
                "core",
                title: "Core"
            ) {
                ToolInventoryProbeTool<
                    InventoryCoreIdentity
                >()
            }

            collection(
                "media",
                title: "Media"
            ) {
                ToolInventoryProbeTool<
                    InventoryMediaIdentity
                >()
            }

            ToolInventoryProbeTool<
                InventoryUngroupedIdentity
            >()
        }

        var registry = try Agentic.tool.registry {
            registrations
        }

        try registry.register {
            ToolInventoryProbeTool<
                InventoryDirectIdentity
            >()
        }

        try Expect.equal(
            registry.count,
            4,
            "tool bootstrap registers only explicitly supplied executable tools"
        )

        let inventory = try ToolInventory.materialize(
            registrations: registrations,
            registry: registry
        )

        try Expect.equal(
            inventory.collections.map(
                \.identifier
            ),
            [
                AgentToolCollectionIdentifier(
                    rawValue: "core"
                ),
                AgentToolCollectionIdentifier(
                    rawValue: "media"
                ),
                AgentToolCollectionMetadata
                    .ungrouped
                    .identifier,
            ],
            "inventory preserves declared collection order and one ungrouped collection"
        )

        let core = try Expect.notNil(
            inventory.collection(
                identifiedBy: .init(
                    rawValue: "core"
                )
            ),
            "inventory contains Core grouping metadata"
        )
        let media = try Expect.notNil(
            inventory.collection(
                identifiedBy: .init(
                    rawValue: "media"
                )
            ),
            "inventory contains Media grouping metadata"
        )
        let ungrouped = try Expect.notNil(
            inventory.collection(
                identifiedBy:
                    AgentToolCollectionMetadata
                        .ungrouped
                        .identifier
            ),
            "inventory retains ungrouped executable tools"
        )

        try Expect.equal(
            core.toolIdentifiers,
            [
                "inventory_core",
            ],
            "Core grouping resolves to the exact executable tool"
        )
        try Expect.equal(
            media.toolIdentifiers,
            [
                "inventory_media",
            ],
            "Media grouping resolves independently of agent exposure"
        )
        try Expect.equal(
            ungrouped.toolIdentifiers,
            [
                "inventory_ungrouped",
                "inventory_direct",
            ],
            "direct registry additions are represented as ungrouped installation metadata"
        )

        try Expect.equal(
            inventory.entries.count,
            4,
            "inventory contains each executable tool exactly once"
        )
        try Expect.equal(
            inventory.modelFacingEntries.count,
            4,
            "inventory retains model-facing executable metadata"
        )

        try proveConflictingToolInventoryCollectionMetadataFails()

        return [
            .field(
                "collections",
                "\(inventory.collections.count)"
            ),
            .field(
                "entries",
                "\(inventory.entries.count)"
            ),
        ]
    }
}

private func proveConflictingToolInventoryCollectionMetadataFails()
    throws
{
    let registrations = tools {
        collection(
            "shared",
            title: "First"
        ) {
            ToolInventoryProbeTool<
                InventoryConflictAIdentity
            >()
        }

        collection(
            "shared",
            title: "Second"
        ) {
            ToolInventoryProbeTool<
                InventoryConflictBIdentity
            >()
        }
    }

    let registry = try Agentic.tool.registry {
        registrations
    }

    do {
        _ = try ToolInventory.materialize(
            registrations: registrations,
            registry: registry
        )

        throw ToolInventoryFlowError
            .expectedConflictingCollectionMetadata
    } catch ToolInventoryError
        .conflictingCollectionMetadata(let identifier)
    {
        try Expect.equal(
            identifier,
            AgentToolCollectionIdentifier(
                rawValue: "shared"
            ),
            "conflicting collection metadata is rejected deterministically"
        )
    }
}

private enum ToolInventoryFlowError: Error {
    case expectedConflictingCollectionMetadata
}

private protocol ToolInventoryProbeIdentity {
    static var identifier: ToolIdentifier { get }
}

private enum InventoryCoreIdentity: ToolInventoryProbeIdentity {
    static let identifier: ToolIdentifier =
        "inventory_core"
}

private enum InventoryMediaIdentity: ToolInventoryProbeIdentity {
    static let identifier: ToolIdentifier =
        "inventory_media"
}

private enum InventoryUngroupedIdentity: ToolInventoryProbeIdentity {
    static let identifier: ToolIdentifier =
        "inventory_ungrouped"
}

private enum InventoryDirectIdentity: ToolInventoryProbeIdentity {
    static let identifier: ToolIdentifier =
        "inventory_direct"
}

private enum InventoryConflictAIdentity: ToolInventoryProbeIdentity {
    static let identifier: ToolIdentifier =
        "inventory_conflict_a"
}

private enum InventoryConflictBIdentity: ToolInventoryProbeIdentity {
    static let identifier: ToolIdentifier =
        "inventory_conflict_b"
}

@JSONSchema
private struct ToolInventoryProbeInput:
    HashableSource
{
    let value: String?

    init(
        value: String? = nil
    ) {
        self.value = value
    }
}

private struct ToolInventoryProbeTool<
    Identity: ToolInventoryProbeIdentity
>: Tool {
    typealias Input = ToolInventoryProbeInput
    typealias Output = ToolInventoryProbeInput

    static var definition: ToolDefinition {
        .init(
            identifier: Identity.identifier,
            purpose: "Tool inventory probe.",
            risk: .observe
        )
    }

    func call(
        _ input: Input,
        in _: ToolContext
    ) async throws -> Output {
        input
    }
}

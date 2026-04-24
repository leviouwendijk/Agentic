---

# Next pass: persisted pricing catalogs

Create:

```text
Sources/Agentic/pricing/catalog/
```

## 2. Addition

```swift
// Sources/Agentic/pricing/catalog/model-pricing-catalog-document.swift
// scope: whole file addition

import Foundation

public struct ModelPricingCatalogDocument: Sendable, Codable, Hashable {
    public var version: Int
    public var snapshots: [ModelPricingSnapshot]
    public var createdAt: Date
    public var updatedAt: Date
    public var metadata: [String: String]

    public init(
        version: Int = 1,
        snapshots: [ModelPricingSnapshot] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.version = max(
            1,
            version
        )
        self.snapshots = snapshots
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
}
```

## 3. Addition

```swift
// Sources/Agentic/pricing/catalog/model-pricing-catalog-error.swift
// scope: whole file addition

import Foundation

public enum ModelPricingCatalogError: Error, Sendable, LocalizedError {
    case durableStorageRequired
    case unreadableCatalog(URL)
    case duplicatePricingKey(ModelPricingKey)

    public var errorDescription: String? {
        switch self {
        case .durableStorageRequired:
            return "Pricing catalog operations require durable Agentic storage."

        case .unreadableCatalog(let url):
            return "Pricing catalog at '\(url.path)' is unreadable."

        case .duplicatePricingKey(let key):
            return "Duplicate pricing entry for provider '\(key.provider)', model '\(key.model)', region '\(key.region ?? "default")'."
        }
    }
}
```

## 4. Addition

```swift
// Sources/Agentic/pricing/catalog/file-model-pricing-catalog.swift
// scope: whole file addition

import Foundation

public struct FileModelPricingCatalog: ModelPricingCatalog {
    public var catalogfile: URL

    public init(
        catalogfile: URL
    ) {
        self.catalogfile = catalogfile.standardizedFileURL
    }

    public init(
        catalogdir: URL,
        filename: String = "pricing-catalog.json"
    ) {
        self.init(
            catalogfile: catalogdir
                .standardizedFileURL
                .appendingPathComponent(
                    filename,
                    isDirectory: false
                )
        )
    }

    public func pricing(
        for key: ModelPricingKey
    ) throws -> ModelPricingSnapshot {
        let snapshots = try loadSnapshots()

        if let exact = snapshots.last(where: { $0.key == key }) {
            return exact
        }

        if key.region != nil {
            let fallback = ModelPricingKey(
                provider: key.provider,
                model: key.model,
                region: nil
            )

            if let fallback = snapshots.last(where: { $0.key == fallback }) {
                return fallback
            }
        }

        throw AgentCostError.missingPricingForModel(
            key
        )
    }

    public func loadDocument() throws -> ModelPricingCatalogDocument {
        guard FileManager.default.fileExists(
            atPath: catalogfile.path
        ) else {
            return .init()
        }

        let data = try Data(
            contentsOf: catalogfile
        )

        guard !data.isEmpty else {
            return .init()
        }

        return try decoder.decode(
            ModelPricingCatalogDocument.self,
            from: data
        )
    }

    public func loadSnapshots() throws -> [ModelPricingSnapshot] {
        try loadDocument().snapshots
    }

    public func saveDocument(
        _ document: ModelPricingCatalogDocument
    ) throws {
        try ensureParentDirectoryExists()

        var document = document
        document.updatedAt = Date()

        let data = try encoder.encode(
            document
        )

        try data.write(
            to: catalogfile,
            options: .atomic
        )
    }

    public func saveSnapshots(
        _ snapshots: [ModelPricingSnapshot],
        metadata: [String: String] = [:]
    ) throws {
        let previous = try loadDocument()

        try saveDocument(
            .init(
                version: previous.version,
                snapshots: snapshots,
                createdAt: previous.createdAt,
                updatedAt: Date(),
                metadata: metadata.isEmpty ? previous.metadata : metadata
            )
        )
    }

    public func upsert(
        _ snapshot: ModelPricingSnapshot
    ) throws {
        var document = try loadDocument()

        document.snapshots.removeAll {
            $0.key == snapshot.key
        }

        document.snapshots.append(
            snapshot
        )

        document.snapshots.sort { lhs, rhs in
            if lhs.provider != rhs.provider {
                return lhs.provider < rhs.provider
            }

            if lhs.model != rhs.model {
                return lhs.model < rhs.model
            }

            return (lhs.region ?? "") < (rhs.region ?? "")
        }

        try saveDocument(
            document
        )
    }

    public func remove(
        key: ModelPricingKey
    ) throws {
        var document = try loadDocument()

        document.snapshots.removeAll {
            $0.key == key
        }

        try saveDocument(
            document
        )
    }
}

private extension FileModelPricingCatalog {
    var encoder: JSONEncoder {
        let encoder = JSONEncoder()

        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        encoder.dateEncodingStrategy = .iso8601

        return encoder
    }

    var decoder: JSONDecoder {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .iso8601

        return decoder
    }

    func ensureParentDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: catalogfile.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
```

## 5. Addition

```swift
// Sources/Agentic/pricing/catalog/agent-runtime-environment+pricing-catalog.swift
// scope: whole file addition

import Foundation

public extension AgentRuntimeEnvironment {
    func pricingCatalogdir() -> URL? {
        switch sessionStorageMode {
        case .ephemeral:
            return nil

        case .global_home,
             .project_local,
             .custom:
            return home.rootURL
                .appendingPathComponent(
                    "pricing",
                    isDirectory: true
                )
        }
    }

    func pricingCatalogfile(
        filename: String = "pricing-catalog.json"
    ) -> URL? {
        pricingCatalogdir()?
            .appendingPathComponent(
                filename,
                isDirectory: false
            )
    }

    func createPricingCatalogDirectories() throws {
        guard let pricingCatalogdir else {
            throw ModelPricingCatalogError.durableStorageRequired
        }

        try FileManager.default.createDirectory(
            at: pricingCatalogdir,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    func filePricingCatalog(
        filename: String = "pricing-catalog.json",
        createDirectories: Bool = true
    ) throws -> FileModelPricingCatalog {
        if createDirectories {
            try createPricingCatalogDirectories()
        }

        guard let file = pricingCatalogfile(
            filename: filename
        ) else {
            throw ModelPricingCatalogError.durableStorageRequired
        }

        return FileModelPricingCatalog(
            catalogfile: file
        )
    }
}
```

## 6. Addition

```swift
// Sources/Agentic/pricing/catalog/agentic-runtime-bootstrap+pricing-catalog.swift
// scope: whole file addition

public extension Agentic.RuntimeBootstrapAPI {
    func pricingCatalog(
        environment: AgentRuntimeEnvironment,
        filename: String = "pricing-catalog.json",
        createDirectories: Bool = true
    ) throws -> FileModelPricingCatalog {
        try environment.filePricingCatalog(
            filename: filename,
            createDirectories: createDirectories
        )
    }

    func costTracker(
        environment: AgentRuntimeEnvironment,
        provider: String,
        region: String? = nil,
        defaultModel: String? = nil,
        reservedOutputTokens: Int = 0,
        catalog: (any ModelPricingCatalog)? = nil,
        metadata: [String: String] = [:]
    ) throws -> AgentCostTracker {
        let catalog = try catalog ?? pricingCatalog(
            environment: environment
        )

        return AgentCostTracker(
            catalog: catalog,
            provider: provider,
            region: region,
            defaultModel: defaultModel,
            reservedOutputTokens: reservedOutputTokens,
            metadata: metadata
        )
    }
}
```

## 7. Replacement

This wires the environment convenience initializer to accept your cost tracker. Your current environment initializer resolves stores from `AgentRuntimeEnvironment`, but it does not pass `costTracker` into the main `AgentRunner` init yet.

```swift
// Sources/Agentic/runtime/agent-runner+environment.swift
// scope: whole file replacement

import Foundation

public extension AgentRunner {
    init(
        adapter: any AgentModelAdapter,
        environment: AgentRuntimeEnvironment,
        sessionID: String,
        configuration: AgentRunnerConfiguration = .default,
        toolRegistry: ToolRegistry = .init(),
        extensions: [any AgentHarnessExtension] = [],
        approvalHandler: (any ToolApprovalHandler)? = nil,
        costTracker: AgentCostTracker? = nil,
        enableHistoryPersistence: Bool = true
    ) throws {
        let stores = try AgentRuntimeStoreResolver(
            environment: environment
        ).resolveStores(
            sessionID: sessionID
        )

        var resolvedConfiguration = configuration

        if enableHistoryPersistence,
           stores.historyStore != nil,
           resolvedConfiguration.historyPersistenceMode == .disabled {
            resolvedConfiguration.historyPersistenceMode = .checkpointmutation
        }

        self.init(
            adapter: adapter,
            configuration: resolvedConfiguration,
            toolRegistry: toolRegistry,
            extensions: extensions,
            workspace: environment.workspace,
            approvalHandler: approvalHandler,
            historyStore: stores.historyStore,
            eventSinks: stores.eventSinks,
            costTracker: costTracker
        )
    }
}
```

## 8. Optional addition

This gives you a nice explicit import/export surface for manually seeded catalogs, imported LiteLLM catalogs, or later AWS-normalized exports.

```swift
// Sources/Agentic/pricing/catalog/file-model-pricing-catalog+import-export.swift
// scope: whole file addition

import Foundation

public extension FileModelPricingCatalog {
    func importSnapshots(
        _ snapshots: [ModelPricingSnapshot],
        replacingExisting: Bool = false,
        metadata: [String: String] = [:]
    ) throws {
        if replacingExisting {
            try saveSnapshots(
                snapshots,
                metadata: metadata
            )

            return
        }

        var document = try loadDocument()

        for snapshot in snapshots {
            document.snapshots.removeAll {
                $0.key == snapshot.key
            }

            document.snapshots.append(
                snapshot
            )
        }

        document.metadata.merge(
            metadata
        ) { _, new in
            new
        }

        try saveDocument(
            document
        )
    }

    func exportDocument() throws -> ModelPricingCatalogDocument {
        try loadDocument()
    }
}
```

## Usage

```swift
// example usage snippet

let environment = try Agentic.runtime.environment()

let catalog = try Agentic.runtime.pricingCatalog(
    environment: environment
)

let claudePricing = try ModelPricingSnapshot.tokenPricing(
    provider: "bedrock",
    model: "anthropic.claude-example",
    region: "eu-west-1",
    source: .manual,
    sourceVersion: "manual-2026-04-24",
    currencyCode: "USD",
    inputMicrosPerMillionTokens: 3_000_000,
    outputMicrosPerMillionTokens: 15_000_000
)

try catalog.upsert(
    claudePricing
)

let costTracker = try Agentic.runtime.costTracker(
    environment: environment,
    provider: "bedrock",
    region: "eu-west-1",
    defaultModel: "anthropic.claude-example",
    reservedOutputTokens: 4_000
)

let runner = try AgentRunner(
    adapter: adapter,
    environment: environment,
    sessionID: sessionID,
    toolRegistry: registry,
    costTracker: costTracker
)
```

Run:

```text
swuild
```

This pass gives you:

```text
AgentHome/pricing/pricing-catalog.json
    persisted normalized model pricing snapshots

Agentic.runtime.pricingCatalog(...)
    file-backed catalog resolver

Agentic.runtime.costTracker(...)
    one-call runtime cost tracker

AgentRunner(environment:costTracker:)
    environment convenience initializer now preserves cost tracking
```



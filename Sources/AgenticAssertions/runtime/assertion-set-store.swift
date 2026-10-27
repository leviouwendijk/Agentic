import Agentic
import CryptoKit
import Foundation

public enum AssertionSetStoreError: Error, Sendable, Equatable {
    case invalid_id
    case expected_revision_mismatch
    case frozen
    case missing
}

/// An optionally durable, host-configured revision store. The model never selects
/// its storage directory. A nil directory supplies only process-local state.
public actor AssertionSetStore {
    public static let shared = AssertionSetStore()

    private let directory: URL?
    private var cache: [String: [Int: AssertionSet]] = [:]

    public init(directory: URL? = nil) {
        self.directory = directory
    }

    public func load(id: String, revision: Int? = nil) throws -> AssertionSet? {
        try validate(id)
        if let revision, let cached = cache[id]?[revision] { return cached }
        guard let directory else {
            return cache[id]?.values.max(by: { $0.revision < $1.revision })
        }
        let setDirectory = directory.appendingPathComponent(id, isDirectory: true)
        guard FileManager.default.fileExists(atPath: setDirectory.path) else {
            return cache[id]?.values.max(by: { $0.revision < $1.revision })
        }
        let files = try FileManager.default.contentsOfDirectory(
            at: setDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        let selected: URL?
        if let revision {
            selected = files.first(where: {
                $0.deletingPathExtension().lastPathComponent == String(format: "%012d", revision)
            })
        } else {
            selected = files.max(by: { $0.lastPathComponent < $1.lastPathComponent })
        }
        guard let selected else { return nil }
        let result = try JSONDecoder().decode(
            AssertionSet.self,
            from: Data(contentsOf: selected)
        )
        guard result.id == id, revision == nil || result.revision == revision else {
            throw AssertionSetStoreError.invalid_id
        }
        guard result.hash == (try fingerprint(
            id: result.id, revision: result.revision,
            assertions: result.assertions, frozen: result.frozen
        )) else { throw AssertionSetStoreError.invalid_id }
        cache[id, default: [:]][result.revision] = result
        return result
    }

    public func define(
        id: String,
        expectedRevision: Int?,
        assertions: [Assertion],
        freeze: Bool
    ) throws -> AssertionSet {
        try validate(id)
        let previous = try load(id: id)
        guard previous?.frozen != true else { throw AssertionSetStoreError.frozen }
        guard previous?.revision == expectedRevision else {
            throw AssertionSetStoreError.expected_revision_mismatch
        }
        let revision = (previous?.revision ?? 0) + 1
        let hash = try fingerprint(
            id: id, revision: revision, assertions: assertions, frozen: freeze
        )
        let next = AssertionSet(
            id: id, revision: revision, assertions: assertions,
            frozen: freeze, hash: hash
        )
        if let directory {
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true
            )
            let setDirectory = directory.appendingPathComponent(id, isDirectory: true)
            try FileManager.default.createDirectory(
                at: setDirectory, withIntermediateDirectories: true
            )
            let url = setDirectory.appendingPathComponent(
                String(format: "%012d.json", revision)
            )
            let data = try JSONEncoder().encode(next)
            try data.write(to: url, options: .atomic)
        }
        cache[id, default: [:]][revision] = next
        return next
    }

    private func validate(_ id: String) throws {
        guard !id.isEmpty, id.count <= 100,
              id.utf8.allSatisfy({ byte in
                  (byte >= 48 && byte <= 57)
                      || (byte >= 65 && byte <= 90)
                      || (byte >= 97 && byte <= 122)
                      || byte == 45 || byte == 95
              }) else {
            throw AssertionSetStoreError.invalid_id
        }
    }

    private struct FingerprintBody: Encodable {
        let id: String
        let revision: Int
        let assertions: [Assertion]
        let frozen: Bool
    }

    private func fingerprint(
        id: String,
        revision: Int,
        assertions: [Assertion],
        frozen: Bool
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(FingerprintBody(
            id: id, revision: revision, assertions: assertions, frozen: frozen
        ))
        return SHA256.hash(data: data).map {
            String(format: "%02x", $0)
        }.joined()
    }
}

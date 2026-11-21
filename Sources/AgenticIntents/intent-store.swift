import Agentic
import Foundation
import IO
import Readers
import Writers
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public extension Intents {
    protocol Store: Sendable {
        func load(
            _ id: Intent.ID
        ) async throws -> Intent?

        /// Newest first.
        func list() async throws -> [Intent]

        /// Creates the intent; false when its id already exists. Never overwrites.
        func insert(
            _ intent: Intent
        ) async throws -> Bool

        /// Replaces exactly `expected`; false when the stored intent differs.
        /// Must hold across independent stores over the same backing storage.
        func replace(
            _ intent: Intent,
            matching expected: Intent
        ) async throws -> Bool

        func delete(
            _ id: Intent.ID
        ) async throws
    }

    /// One JSON file per intent. Transitions are serialized across processes
    /// by an advisory lock on a lock file in the same directory, so every
    /// writer must go through this store.
    actor FileStore: Store {
        public let directory: URL

        public init(
            directory: URL
        ) {
            self.directory = directory.standardizedFileURL
        }

        public func load(
            _ id: Intent.ID
        ) async throws -> Intent? {
            try read(file(id))
        }

        public func list() async throws -> [Intent] {
            guard FileSystem.default.exists(directory) else {
                return []
            }
            let intents = try FileSystem.default.directory.contents(
                directory,
                options: [.skipsHiddenFiles]
            )
            .filter { $0.pathExtension == "json" }
            .compactMap { try read($0) }

            return intents.sorted { lhs, rhs in
                lhs.updatedAt == rhs.updatedAt
                    ? lhs.id < rhs.id
                    : lhs.updatedAt > rhs.updatedAt
            }
        }

        public func insert(
            _ intent: Intent
        ) async throws -> Bool {
            try locked {
                guard try read(file(intent.id)) == nil else {
                    return false
                }
                try write(intent)
                return true
            }
        }

        public func replace(
            _ intent: Intent,
            matching expected: Intent
        ) async throws -> Bool {
            guard intent.id == expected.id else {
                return false
            }
            return try locked {
                guard try read(file(expected.id)) == expected else {
                    return false
                }
                try write(intent)
                return true
            }
        }

        public func delete(
            _ id: Intent.ID
        ) async throws {
            try locked {
                let url = file(id)
                if FileSystem.default.exists(url) {
                    try FileSystem.default.remove(url)
                }
            }
        }
    }
}

private extension Intents.FileStore {
    func file(
        _ id: Intents.Intent.ID
    ) -> URL {
        directory.appendingPathComponent(
            "intent-\(id.raw).json",
            isDirectory: false
        )
    }

    func read(
        _ url: URL
    ) throws -> Intents.Intent? {
        let read = try DataFileReader(url).read(
            options: .init(missingFilePolicy: .returnEmpty)
        )
        guard !read.data.isEmpty else {
            return nil
        }
        return try JSONDecoder().decode(
            Intents.Intent.self,
            from: read.data
        )
    }

    func write(
        _ intent: Intents.Intent
    ) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try FileWriter(file(intent.id)).write(
            try encoder.encode(intent),
            options: .overwriteWithoutBackup
        )
    }

    func locked<T>(
        _ operation: () throws -> T
    ) throws -> T {
        try FileSystem.default.directory.create(directory)
        let lockfile = directory.appendingPathComponent(
            ".intents.lock",
            isDirectory: false
        )
        let descriptor = lockfile.path.withCString {
            open($0, O_CREAT | O_RDWR | O_CLOEXEC, mode_t(0o600))
        }
        guard descriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        defer {
            _ = flock(descriptor, LOCK_UN)
            _ = close(descriptor)
        }
        while flock(descriptor, LOCK_EX) != 0 {
            guard errno == EINTR else {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
        }
        return try operation()
    }
}

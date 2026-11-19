import Foundation
import IO
import Readers
import Writers

/// Keeps a session as it is: cited by published content (provenance) or
/// otherwise held as the faithful record. The marker lives in the
/// session's own directory (`sessions/<id>/pin.json`), so the session
/// keeps one location; retention skips it, routine scrubbing refuses it,
/// and the values its handles stand for are kept.
public struct SessionPin: Sendable, Codable, Hashable {
    public let pinned: Date
    /// Why, such as "cited by docs.hondenmeesters.nl/reactivity".
    public let reason: String

    public init(pinned: Date = Date(), reason: String) {
        self.pinned = pinned
        self.reason = reason
    }
}

public extension AgentRuntimeStorageLayout {
    func pinfile(sessionID: String) -> URL {
        sessiondir(sessionID: sessionID).appendingPathComponent("pin.json")
    }

    /// The session's pin; nil when it is not pinned.
    func pin(sessionID: String) -> SessionPin? {
        guard let read = try? TextFileReader(pinfile(sessionID: sessionID)).read(options: .init(missingFilePolicy: .returnEmpty)),
              read.existed
        else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SessionPin.self, from: Data(read.text.utf8))
    }

    /// Pins the session (or replaces its pin's reason).
    func pinSession(_ sessionID: String, _ pin: SessionPin) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let text = String(decoding: try encoder.encode(pin), as: UTF8.self)
        try FileWriter(pinfile(sessionID: sessionID)).write(text, options: .overwriteWithoutBackup)
    }

    func unpinSession(_ sessionID: String) throws {
        let file = pinfile(sessionID: sessionID)
        if FileSystem.default.exists(file) {
            try FileSystem.default.remove(file)
        }
    }

    /// Ids of every pinned session.
    func pinnedSessions() -> [String] {
        guard let entries = try? DirectoryInspector(sessionsdir).entries() else { return [] }
        return entries
            .filter { $0.kind == .directory }
            .map { $0.url.lastPathComponent }
            .filter { pin(sessionID: $0) != nil }
            .sorted()
    }
}

import CryptoKit
import Foundation
import Primitives

/// Stable authored identity, independent of subsequent content revisions.
public struct InstructionIdentifier: StringIdentifier {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Content-derived revision; never depends on Swift's randomized Hasher.
public enum InstructionRevision {
    public static func of(_ content: String) -> String {
        let digest = SHA256.hash(data: Data(content.utf8))
        return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
    }
}

/// An authored, immutable piece of guidance. An Instruction is not executable.
public struct Instruction: Sendable, Codable, Hashable {
    public let identifier: InstructionIdentifier
    public let content: String
    public let source: String?

    public init(
        identifier: InstructionIdentifier,
        content: String,
        source: String? = nil
    ) {
        self.identifier = identifier
        self.content = content
        self.source = source
    }

    public var revision: String {
        InstructionRevision.of(content)
    }

    public var reference: Reference {
        .init(identifier: identifier, revision: revision, source: source)
    }

    public struct Reference: Sendable, Codable, Hashable {
        public let identifier: InstructionIdentifier
        public let revision: String
        public let source: String?

        public init(
            identifier: InstructionIdentifier,
            revision: String,
            source: String? = nil
        ) {
            self.identifier = identifier
            self.revision = revision
            self.source = source
        }
    }
}

/// Order-preserving composition of reusable Instructions and local guidance.
/// Values are retained, so a snapshot does not depend on mutable source files.
public struct Instructions: Sendable, Codable, Hashable, ExpressibleByArrayLiteral, ExpressibleByStringLiteral {
    public enum Part: Sendable, Codable, Hashable {
        case instruction(Instruction)
        case text(String)

        public var content: String {
            switch self {
            case .instruction(let instruction): instruction.content
            case .text(let text): text
            }
        }
    }

    public let parts: [Part]

    public init(arrayLiteral elements: Part...) {
        self.init(elements)
    }

    public init(stringLiteral value: String) {
        self.init([.text(value)])
    }

    public init(_ text: String) {
        self.init([.text(text)])
    }
    public let separator: String

    public init(
        _ parts: [Part],
        separator: String = "\n\n"
    ) {
        self.parts = parts
        self.separator = separator
    }

    public var resolved: String {
        parts.map(\.content)
            .filter { !$0.isEmpty }
            .joined(separator: separator)
    }

    /// Preserve occurrence order, including repeated Instructions.
    public var references: [Instruction.Reference] {
        parts.compactMap { part in
            guard case .instruction(let instruction) = part else {
                return nil
            }
            return instruction.reference
        }
    }

    public var snapshot: InstructionSnapshot {
        .init(content: resolved, composition: self)
    }
}

/// The exact effective text and contributing authored content used by a run.
public struct InstructionSnapshot: Sendable, Codable, Hashable {
    public let content: String
    public let composition: Instructions?

    public init(
        content: String,
        composition: Instructions? = nil
    ) {
        self.content = content
        self.composition = composition
    }

    public var revision: String {
        InstructionRevision.of(content)
    }

    public var references: [Instruction.Reference] {
        composition?.references ?? []
    }
}

/// A single instruction-authoring seam: Strings, reusable values and
/// ordered compositions all yield an immutable execution snapshot.
public protocol InstructionSource: Sendable {
    var instructionSnapshot: InstructionSnapshot? { get }
}

extension String: InstructionSource {
    public var instructionSnapshot: InstructionSnapshot? {
        InstructionSnapshot(content: self)
    }
}

extension Optional: InstructionSource where Wrapped == String {
    public var instructionSnapshot: InstructionSnapshot? {
        map { InstructionSnapshot(content: $0) }
    }
}

extension Instruction: InstructionSource {
    public var instructionSnapshot: InstructionSnapshot? {
        Instructions([.instruction(self)]).snapshot
    }
}

extension Instructions: InstructionSource {
    public var instructionSnapshot: InstructionSnapshot? {
        snapshot
    }
}

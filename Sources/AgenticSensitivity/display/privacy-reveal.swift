import Agentic
import AgenticConfiguration
import Foundation
import Sensitivity

public extension Privacy {
    /// One handle as the owner's screen shows it.
    struct HandleDisplay: Sendable, Hashable {
        public enum State: String, Sendable, Hashable {
            /// The value, to be marked as scrubbed.
            case revealed
            /// The masked preview, by mode or because it is a secret.
            case masked
            /// The handle, by mode.
            case handle
            /// Not in the vault: expired, released or from another vault.
            case unknown
        }

        public let handle: Sensitivity.Handle
        public let state: State
        /// What to show inline: the value, the preview or the handle token.
        public let text: String
        /// What is known about it, for a hover or detail view; nil when unknown.
        public let description: Sensitivity.HandleDescription?
        public let expires: Date?

        public var kind: Sensitivity.Kind {
            handle.kind
        }
    }

    /// A run of text: plain, or a handle to render marked.
    enum DisplaySegment: Sendable, Hashable {
        case text(String)
        case handle(HandleDisplay)
    }

    /// Resolves handles for the owner's screens from a snapshot of the vault.
    /// Synchronous, so renderers call it per line. What it returns is for
    /// display only: never written to a record, a log or a model's context.
    struct Reveal: Sendable {
        public let mode: SensitivityFrame.DisplayMode
        private let entries: [String: Sensitivity.DisplayEntry]

        public init(
            mode: SensitivityFrame.DisplayMode,
            entries: [Sensitivity.DisplayEntry]
        ) {
            self.mode = mode
            self.entries = Dictionary(entries.map { ($0.description.handle.id, $0) }, uniquingKeysWith: { _, last in last })
        }

        /// Handles shown as handles: for surfaces without a vault.
        public static let handles = Reveal(mode: .handles, entries: [])

        public func display(
            _ handle: Sensitivity.Handle
        ) -> HandleDisplay {
            guard let entry = entries[handle.id], entry.description.handle.kind == handle.kind else {
                return HandleDisplay(handle: handle, state: .unknown, text: handle.token, description: nil, expires: nil)
            }
            let state: HandleDisplay.State
            let text: String
            switch mode {
            case .handles:
                (state, text) = (.handle, handle.token)
            case .masked:
                (state, text) = (.masked, entry.description.preview)
            case .revealed:
                // Secrets show masked inline; revealing one is a deliberate act.
                (state, text) = handle.kind == .secret
                    ? (.masked, entry.description.preview)
                    : (.revealed, entry.value)
            }
            return HandleDisplay(handle: handle, state: state, text: text, description: entry.description, expires: entry.expires)
        }

        /// The value behind one handle, whatever the mode, for an explicit
        /// reveal (a click, `/reveal <handle>`); nil when unknown.
        public func value(
            of handle: Sensitivity.Handle
        ) -> String? {
            guard let entry = entries[handle.id], entry.description.handle.kind == handle.kind else {
                return nil
            }
            return entry.value
        }

        /// `text` split into plain runs and handles, in order.
        public func segments(
            in text: String
        ) -> [DisplaySegment] {
            let occurrences = Sensitivity.Handle.occurrences(in: text)
            guard !occurrences.isEmpty else {
                return text.isEmpty ? [] : [.text(text)]
            }
            var segments: [DisplaySegment] = []
            var index = text.startIndex
            var offset = 0
            for occurrence in occurrences {
                let start = text.index(index, offsetBy: occurrence.range.startOffset - offset)
                if start > index {
                    segments.append(.text(String(text[index..<start])))
                }
                let end = text.index(start, offsetBy: occurrence.range.endOffset - occurrence.range.startOffset)
                segments.append(.handle(display(occurrence.handle)))
                index = end
                offset = occurrence.range.endOffset
            }
            if index < text.endIndex {
                segments.append(.text(String(text[index...])))
            }
            return segments
        }

        /// `text` with each handle replaced by its display text and no
        /// marking, for surfaces that cannot style a run.
        public func plain(
            _ text: String
        ) -> String {
            segments(in: text).map { segment in
                switch segment {
                case .text(let text): return text
                case .handle(let display): return display.text
                }
            }.joined()
        }
    }

    /// Opens reveals for the owner's screens. Held by the host's UI, never
    /// inserted into tool services, so no tool or model path reaches it.
    struct Revealer: Sendable {
        let vault: Sensitivity.Vault
        public let mode: SensitivityFrame.DisplayMode

        /// The vault's live values now, under `mode` (the configured mode
        /// when nil).
        public func reveal(
            mode: SensitivityFrame.DisplayMode? = nil
        ) async -> Reveal {
            let chosen = mode ?? self.mode
            guard chosen != .handles else {
                return .handles
            }
            return Reveal(mode: chosen, entries: await vault.displayEntries())
        }
    }

    /// The revealer for the vault `domains/sensitivity.frame` configures:
    /// the same vault sessions in this process use.
    static func revealer(
        home: AgentHome = AgentHomeLocator().resolveHome(),
        configuration: Configuration? = nil
    ) -> Revealer {
        let loaded = configuration ?? Configuration.load(home: home).configuration
        return Revealer(vault: vaults.vault(for: loaded), mode: loaded.display)
    }
}

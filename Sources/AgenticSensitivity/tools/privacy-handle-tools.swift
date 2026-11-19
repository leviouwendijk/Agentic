import Agentic
import Foundation
import Macros
import Schema
import Sensitivity

public extension Privacy.Tools {
    /// A handle as a model may know it: never the value.
    @JSONSchema
    struct HandleItem: HashableResult {
        /// As written in text, such as ⟦contact:7f3a91c2⟧.
        public let handle: String
        public let kind: String
        /// soft: any tool may use it; handle: related or granted tools.
        public let tier: String
        /// Masked, such as **** 4300.
        public let preview: String
        public let reason: String
        public let score: Int
        /// Where it was seen: tool and field path.
        public let sources: [String]
        /// Tools the owner allowed to use it.
        public let grants: [String]

        init(_ description: Sensitivity.HandleDescription) {
            self.handle = description.handle.token
            self.kind = description.handle.kind.rawValue
            self.tier = description.tier.rawValue
            self.preview = description.preview
            self.reason = description.reason
            self.score = description.score
            self.sources = description.sources
            self.grants = description.grants
        }
    }

    @Tool("privacy_handles")
    struct Handles {
        @JSONSchema
        public struct Input: HashableSource {
            /// Only these kinds: secret, contact, financial, network, link,
            /// identifier, identity.
            public let kinds: [String]?
            /// Only these handles, as written (⟦kind:id⟧).
            public let handles: [String]?

            public init(kinds: [String]? = nil, handles: [String]? = nil) {
                self.kinds = kinds
                self.handles = handles
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let handles: [HandleItem]
        }

        public static let purpose =
            "Describe the session's handles (⟦kind:id⟧): kind, masked preview, where each was seen, which tools may use it. Never shows values."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let vault = try Privacy.activeGuard(in: context).vault
            let wanted = Set((input.handles ?? []).flatMap { Sensitivity.Handle.occurrences(in: $0).map(\.handle.id) })
            let kinds = Set(input.kinds ?? [])
            let items = await vault.descriptions().filter { description in
                (kinds.isEmpty || kinds.contains(description.handle.kind.rawValue))
                    && (wanted.isEmpty || wanted.contains(description.handle.id))
            }
            return .init(handles: items.map(HandleItem.init))
        }
    }

    @Tool("privacy_grant")
    struct Grant {
        @JSONSchema
        public struct Input: HashableSource {
            /// The handle, as written (⟦kind:id⟧).
            public let handle: String
            /// The tool that will use its value, such as mail_send.
            public let tool: String
            /// What the value is needed for, for the owner deciding.
            public let purpose: String

            public init(handle: String, tool: String, purpose: String) {
                self.handle = handle
                self.tool = tool
                self.purpose = purpose
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let granted: Bool
            public let handle: HandleItem?
        }

        public static let purpose =
            "Ask the owner to let one tool use one handle's value, for a stated purpose. Needed when a tool refuses a handle from another domain. The value still never reaches the model."
        public static let risk: ActionRisk = .privileged

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let vault = try Privacy.activeGuard(in: context).vault
            guard let handle = Sensitivity.Handle.occurrences(in: input.handle).first?.handle,
                  await vault.grant(handle, to: input.tool)
            else {
                return .init(granted: false, handle: nil)
            }
            return .init(granted: true, handle: await vault.describe(handle).map(HandleItem.init))
        }
    }
}

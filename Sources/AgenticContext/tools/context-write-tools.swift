import Agentic
import Foundation
import Macros
import Schema

public extension Context.Tools {
    @Tool("context_check")
    struct Check {
        @JSONSchema
        public struct Input: HashableSource {
            /// Below context/, such as `business.frame`.
            public let file: String
            /// The whole file.
            public let text: String

            public init(file: String, text: String) {
                self.file = file
                self.text = text
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let valid: Bool
            /// `file:line:column: message` where located.
            public let problems: [String]
            /// The identifiers it defines.
            public let entries: [String]
        }

        public static let purpose =
            "Check a context file without saving it: syntax, every Entry against the Context schema, dates, and that every related identifier exists once it is saved."
        public static let risk: ActionRisk = .observe

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let check = Context.check(input.text, file: input.file, in: Context.store(in: context))
            return .init(valid: check.problems.isEmpty, problems: check.problems, entries: check.entries)
        }
    }

    @Tool("context_save")
    struct Save {
        @JSONSchema
        public struct Input: HashableSource {
            /// Below context/, such as `business.frame`; folders are made.
            public let file: String
            /// The whole file.
            public let text: String

            public init(file: String, text: String) {
                self.file = file
                self.text = text
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let saved: Bool
            public let file: String
            /// The previous file, kept.
            public let archived: String?
            /// Why it was not saved.
            public let problems: [String]
            public let entries: [String]
        }

        public static let purpose =
            "Save a context file, replacing the current one (which is archived). Checks it first exactly as context_check does and refuses one that does not hold. Only after the owner has seen what will be saved."
        public static let risk: ActionRisk = .privileged

        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let store = Context.store(in: context)
            let check = Context.check(input.text, file: input.file, in: store)
            let path = (try? store.url(input.file).path) ?? input.file
            guard check.problems.isEmpty else {
                return .init(saved: false, file: path, archived: nil, problems: check.problems, entries: check.entries)
            }
            let archived = try store.save(input.text, to: input.file)
            return .init(saved: true, file: path, archived: archived?.path, problems: [], entries: check.entries)
        }
    }
}

extension Context {
    static func check(_ text: String, file: String, in store: Store) -> (problems: [String], entries: [String]) {
        guard (try? store.url(file)) != nil else {
            return ([Context.StoreFailure.invalidPath(file).localizedDescription], [])
        }
        let replaced = store.library().replacing(file, with: text)
        let entries = replaced.library.items.filter { $0.file == file }.map(\.id)
        return (replaced.problems, entries)
    }
}

import Agentic
import Foundation
import Macros
import Schema

public extension Standard.Tools {
    @Tool
    struct ListCapabilities: Tool {
        @JSONSchema
        public struct Input: HashableSource {
            public let kind: FindCapabilities.Kind?
            public let domain: String?
            public let offset: Int?
            public let maximumResults: Int?

            public init(
                kind: FindCapabilities.Kind? = nil,
                domain: String? = nil,
                offset: Int? = nil,
                maximumResults: Int? = nil
            ) {
                self.kind = kind
                self.domain = domain
                self.offset = offset
                self.maximumResults = maximumResults
            }
        }

        @JSONSchema
        public struct Output: HashableResult {
            public let total: Int
            public let offset: Int
            public let entries: [FindCapabilities.Entry]

            public init(total: Int, offset: Int, entries: [FindCapabilities.Entry]) {
                self.total = total
                self.offset = offset
                self.entries = entries
            }
        }

        public static let purpose =
            "Enumerate available executable capabilities, paginated, without changing visibility or authority."
        public static let risk: ActionRisk = .observe
        public init() {}

        public func call(_ input: Input, in context: ToolContext) async throws -> Output {
            let (snapshot, available) = try await CapabilityDiscovery.available(in: context)
            let domain = input.domain?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let selected = available.filter { entry in
                guard let kind = FindCapabilities.Kind(rawValue: entry.kind) else { return false }
                if let wanted = input.kind, wanted != .all && wanted != kind { return false }
                if let domain, !domain.isEmpty, entry.namespace?.lowercased() != domain {
                    return false
                }
                return true
            }
            let offset = min(selected.count, max(0, input.offset ?? 0))
            let limit = min(50, max(1, input.maximumResults ?? 20))
            let page = selected.dropFirst(offset).prefix(limit)
            let entries = page.compactMap { entry -> FindCapabilities.Entry? in
                guard let kind = FindCapabilities.Kind(rawValue: entry.kind) else { return nil }
                return .init(
                    kind: kind,
                    identifier: entry.identifier,
                    namespace: entry.namespace,
                    purpose: entry.purpose,
                    wasVisible: CapabilityDiscovery.contains(entry.reference, in: snapshot.visible)
                )
            }
            return .init(total: selected.count, offset: offset, entries: entries)
        }
    }
}

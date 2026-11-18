import Agentic
import Schema

@Inference
public struct ContextEvidenceSelection {
    public typealias Input = String
    public typealias Output = [String]
    public static let purpose =
        "Select relevant evidence record IDs from a finite, source-validated candidate list; never invent IDs."
}

/// A bounded candidate-selection Program. Inference may rank approved records,
/// but may never mint a pointer, bypass source validation, or expand its budget.
@Program
public struct ContextPreparationProgram {
    public typealias Input = String
    public typealias Output = [String]
    public static let purpose = "Select a small, provenance-checked context working set."

    @InferenceSite
    public static var select: Site<ContextEvidenceSelection>

    public let index: Context.FindingIndex
    public let resolver: any Context.RecordResolving
    public let maximumFindings: Int

    public init(
        index: Context.FindingIndex,
        resolver: any Context.RecordResolving,
        maximumFindings: Int = 4
    ) {
        self.index = index
        self.resolver = resolver
        self.maximumFindings = min(8, max(0, maximumFindings))
    }

    public func run(_ input: String, in context: ProgramContext) async throws -> [String] {
        guard maximumFindings > 0 else { return [] }
        let eligible = try await index.eligible(
            for: input,
            maximum: maximumFindings * 4,
            using: resolver
        )
        guard !eligible.isEmpty else { return [] }
        let allowed = Set(eligible.map { $0.record.id })
        let prompt = "Task: \(input)\nSelect only IDs from:\n" + eligible.map {
            "\($0.record.id): \($0.terms.joined(separator: ", "))"
        }.joined(separator: "\n")

        // The deterministic fallback is explicit: never treat a failed model
        // attempt as a reason to approve an unknown or stale record.
        let proposed: [String]
        do {
            proposed = try await context.infer(Self.select, input: prompt)
        } catch ProgramContextError.inferenceUnavailable {
            proposed = eligible.map { $0.record.id }
        }
        var seen: Set<String> = []
        return Array(proposed.filter {
            allowed.contains($0) && seen.insert($0).inserted
        }.prefix(maximumFindings))
    }

    /// Convert only IDs already selected by this Program into canonical
    /// allocator operations, retaining all source pointers and dependencies.
    public func allocations(
        ids: [String],
        query: String
    ) async throws -> [Context.Allocation] {
        let candidates = try await index.eligible(for: query,
            maximum: maximumFindings * 4, using: resolver)
        let byID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.record.id, $0) })
        return ids.prefix(maximumFindings).compactMap { id in
            byID[id].map { Context.FindingIndex.allocation(for: $0) }
        }
    }
}

import AgenticStandard
import Difference
import Foundation
import Primitives

private enum CallTreeSmokeFailure: Error {
    case expected_rejection
}

enum CallTreeSmoke {
    static func run() throws {
        typealias Tool = Standard.Tools.CreateCallTree
        try AgenticStructuresSmoke.check(
            Tool.definition.identifier.rawValue == "create_call_tree",
            "create_call_tree tool identifier"
        )
        let before = try Tool.evaluate(.init(calls: [
            .init(id: "entry", symbol_id: "run", label: "run()"),
            .init(id: "first", symbol_id: "validate", parent_id: "entry", label: "validate()"),
            .init(id: "second", symbol_id: "validate", parent_id: "entry", label: "validate()"),
        ]))
        try AgenticStructuresSmoke.check(before.provenance == .proposed, "call trees are proposed")
        try AgenticStructuresSmoke.check(before.tree.roots.count == 1, "one call tree root")
        try AgenticStructuresSmoke.check(
            before.tree.roots[0].children.map { $0.value.id } == ["first", "second"],
            "input order determines sibling order"
        )
        try AgenticStructuresSmoke.check(
            before.tree.roots[0].children.map { $0.value.symbol_id } == ["validate", "validate"],
            "repeated symbol with separate occurrence identities"
        )
        let restored = try JSONDecoder().decode(Tool.Output.self, from: JSONEncoder().encode(before))
        try AgenticStructuresSmoke.check(restored == before, "call tree Codable roundtrip")

        let after = try Tool.evaluate(.init(calls: [
            .init(id: "entry", symbol_id: "run", label: "run()"),
            .init(id: "second", symbol_id: "validate", parent_id: "entry", label: "validate()"),
            .init(id: "first", symbol_id: "validate", parent_id: "entry", label: "validate()"),
        ]))
        let reorder = try TreeDiffer.make(
            before: before.tree,
            after: after.tree,
            source: .proposed,
            identity: { $0.id },
            label: { $0.label },
            equivalent: { $0 == $1 },
            sibling_order: .significant
        )
        let changed = reorder.tree.walk().map { $0.node.value }
        try AgenticStructuresSmoke.check(reorder.source == .proposed, "comparison provenance")
        try AgenticStructuresSmoke.check(
            changed.filter { $0.change == .moved && $0.movement_reasons == [.reordered] }.count == 1,
            "reordered sibling is a move, not content modification"
        )
        let display = TreeDifferenceRenderer.render(TreeDifferenceRenderPlan.make(
            TreeDifferenceLayout.make(reorder), show_movement_reasons: true
        ))
        try AgenticStructuresSmoke.check(display.contains("[reordered]"), "movement reason rendering")

        let reparent_before = try Tool.evaluate(.init(calls: [
            .init(id: "root", symbol_id: "run"),
            .init(id: "left", symbol_id: "branch", parent_id: "root"),
            .init(id: "right", symbol_id: "branch", parent_id: "root"),
            .init(id: "nested", symbol_id: "execute", parent_id: "left"),
        ]))
        let reparent_after = try Tool.evaluate(.init(calls: [
            .init(id: "root", symbol_id: "run"),
            .init(id: "left", symbol_id: "branch", parent_id: "root"),
            .init(id: "right", symbol_id: "branch", parent_id: "root"),
            .init(id: "nested", symbol_id: "execute", parent_id: "right"),
        ]))
        let reparent = try TreeDiffer.make(
            before: reparent_before.tree,
            after: reparent_after.tree,
            source: .proposed,
            identity: { $0.id },
            label: { $0.label },
            equivalent: { $0 == $1 },
            sibling_order: .significant
        )
        let nested = reparent.tree.walk().map { $0.node.value }.first { $0.id == "nested" }
        try AgenticStructuresSmoke.check(
            nested?.change == .moved && nested?.movement_reasons == [.reparented],
            "reparenting does not falsely modify the call payload"
        )

        do {
            _ = try Tool.evaluate(.init(calls: [
                .init(id: "x", symbol_id: "run"), .init(id: "x", symbol_id: "run")
            ]))
            throw CallTreeSmokeFailure.expected_rejection
        } catch Tool.Failure.duplicate_id {}
        do {
            _ = try Tool.evaluate(.init(calls: [
                .init(id: "x", symbol_id: "run", parent_id: "missing")
            ]))
            throw CallTreeSmokeFailure.expected_rejection
        } catch Tool.Failure.unknown_parent {}
        do {
            _ = try Tool.evaluate(.init(calls: [
                .init(id: "x", symbol_id: "run", parent_id: "x")
            ]))
            throw CallTreeSmokeFailure.expected_rejection
        } catch Tool.Failure.self_parent {}
        do {
            _ = try Tool.evaluate(.init(calls: [
                .init(id: "a", symbol_id: "a", parent_id: "b"),
                .init(id: "b", symbol_id: "b", parent_id: "a"),
            ]))
            throw CallTreeSmokeFailure.expected_rejection
        } catch Tool.Failure.cycle {}
        do {
            _ = try Tool.evaluate(.init(calls: [
                .init(id: " ", symbol_id: "run")
            ]))
            throw CallTreeSmokeFailure.expected_rejection
        } catch Tool.Failure.empty_id {}
        do {
            let calls = (0...65).map { index in
                Tool.Call(
                    id: "call-\(index)",
                    symbol_id: "nested",
                    parent_id: index == 0 ? nil : "call-\(index - 1)"
                )
            }
            _ = try Tool.evaluate(.init(calls: calls))
            throw CallTreeSmokeFailure.expected_rejection
        } catch Tool.Failure.excessive_depth {}
        do {
            let calls = (0...512).map { index in
                Tool.Call(id: "call-\(index)", symbol_id: "nested")
            }
            _ = try Tool.evaluate(.init(calls: calls))
            throw CallTreeSmokeFailure.expected_rejection
        } catch Tool.Failure.too_many_calls {}
        print("PASS create_call_tree: ordering, provenance, identity, diffs, validation, Codable")
    }
}

import Agentic
import Foundation
import TestFlows

enum RecoveryFlowSuite: TestFlowRegistry {
    static let title = "Recovery flow tests"

    static let flows: [TestFlow] = [
        TestFlow(
            "recovery-vocabulary",
            tags: [
                "agentic-recovery",
                "recovery",
                "vocabulary",
                "identifiers",
            ]
        ) {
            let customKind = Recovery.Kind(
                rawValue: "domain_specific_failure"
            )
            let customAction = Recovery.Action(
                rawValue: "domain_specific_recovery"
            )

            try Expect.equal(
                Recovery.Kind.transport_transient.rawValue,
                "transport_transient",
                "common recovery kind retains snake-case identifier"
            )
            try Expect.equal(
                Recovery.Kind.structured_output_invalid.rawValue,
                "structured_output_invalid",
                "structured-output failure kind is available"
            )
            try Expect.equal(
                customKind.rawValue,
                "domain_specific_failure",
                "recovery kinds remain extensible by consumers"
            )
            try Expect.equal(
                Recovery.Action.retry_same_operation.rawValue,
                "retry_same_operation",
                "same-operation retry action is explicit"
            )
            try Expect.equal(
                Recovery.Action.reconcile.rawValue,
                "reconcile",
                "reconciliation action is explicit"
            )
            try Expect.equal(
                customAction.rawValue,
                "domain_specific_recovery",
                "recovery actions remain extensible by consumers"
            )
            try Expect.equal(
                Recovery.Stage.decoding.rawValue,
                "decoding",
                "recovery stage is an IO-aligned closed enum"
            )
            try Expect.equal(
                Recovery.EffectState.not_applied.rawValue,
                "not_applied",
                "effect state distinguishes definitely-not-applied work"
            )
            try Expect.equal(
                Recovery.RetrySafety.requires_reconciliation.rawValue,
                "requires_reconciliation",
                "retry safety can require reconciliation"
            )

            return [
                .field(
                    "kind",
                    Recovery.Kind.transport_transient.rawValue
                ),
                .field(
                    "action",
                    Recovery.Action.retry_same_operation.rawValue
                ),
                .field(
                    "effect",
                    Recovery.EffectState.not_applied.rawValue
                ),
                .field(
                    "retry_safety",
                    Recovery.RetrySafety.requires_reconciliation.rawValue
                ),
            ]
        },
        TestFlow(
            "recovery-codable-foundation",
            tags: [
                "agentic-recovery",
                "recovery",
                "codable",
                "io",
            ]
        ) {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let stage = try decoder.decode(
                Recovery.Stage.self,
                from: encoder.encode(
                    Recovery.Stage.reconciliation
                )
            )
            let effectState = try decoder.decode(
                Recovery.EffectState.self,
                from: encoder.encode(
                    Recovery.EffectState.unknown
                )
            )
            let retrySafety = try decoder.decode(
                Recovery.RetrySafety.self,
                from: encoder.encode(
                    Recovery.RetrySafety.unsafe
                )
            )
            let kind = try decoder.decode(
                Recovery.Kind.self,
                from: encoder.encode(
                    Recovery.Kind.route_unavailable
                )
            )
            let action = try decoder.decode(
                Recovery.Action.self,
                from: encoder.encode(
                    Recovery.Action.fallback_equivalent
                )
            )

            try Expect.equal(
                stage,
                .reconciliation,
                "recovery stage round-trips through Codable"
            )
            try Expect.equal(
                effectState,
                .unknown,
                "effect certainty round-trips through Codable"
            )
            try Expect.equal(
                retrySafety,
                .unsafe,
                "retry safety round-trips through Codable"
            )
            try Expect.equal(
                kind,
                .route_unavailable,
                "open recovery kind round-trips through Codable"
            )
            try Expect.equal(
                action,
                .fallback_equivalent,
                "open recovery action round-trips through Codable"
            )

            return [
                .field(
                    "stage",
                    stage.rawValue
                ),
                .field(
                    "effect",
                    effectState.rawValue
                ),
                .field(
                    "retry_safety",
                    retrySafety.rawValue
                ),
                .field(
                    "kind",
                    kind.rawValue
                ),
                .field(
                    "action",
                    action.rawValue
                ),
            ]
        },
    ] + recoverySemanticFlows + recoveryTighteningFlows
}

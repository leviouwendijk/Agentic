import Agentic
import Tokens

public extension ContextWindow.Allocator {
    /// Prepare one model-facing request. The entire request is measured before
    /// resolving evidence; the remaining budget bounds optional allocations.
    /// Canonical session messages are never mutated or summarized here.
    func prepareDynamic(
        request: AgentRequest,
        for workingSetID: String,
        using resolver: any ContextWindow.RecordResolving,
        modelContextLimit: Int,
        compactions: [ContextWindow.Compaction] = [],
        calibration: ContextWindow.InputCalibration? = nil
    ) async throws -> ContextWindow.InferencePreparation {
        let maximum = max(0, min(
            policy.maximumInputTokens,
            modelContextLimit - policy.reservedOutputTokens
        ))
        let empty = ContextWindow.Frame(
            workingSetID: workingSetID,
            items: [],
            skippedAllocationIDs: [],
            inputBudget: 0,
            estimatedInputTokens: 0
        )
        let baseline = try ContextWindow.InferencePreparer.prepare(
            request: request,
            frame: empty,
            delivery: .dynamic,
            maximumInputTokens: maximum,
            historyPolicy: policy.history,
            compactions: compactions,
            calibration: calibration
        )
        let availableForEvidence = max(
            0, maximum - baseline.measurement.inputTokens
        )
        let frame = try await prepareFrame(
            for: workingSetID,
            using: resolver,
            modelContextLimit: policy.reservedOutputTokens + availableForEvidence
        )
        return try ContextWindow.InferencePreparer.prepare(
            request: request,
            frame: frame,
            delivery: .dynamic,
            maximumInputTokens: maximum,
            historyPolicy: policy.history,
            compactions: compactions,
            calibration: calibration
        )
    }
}

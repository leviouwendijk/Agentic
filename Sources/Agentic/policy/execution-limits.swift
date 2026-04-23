import Foundation

public struct ExecutionLimits: Sendable, Codable, Hashable {
    public var maxTargetPathCount: Int?
    public var maxWriteCount: Int?
    public var maxBytes: Int?
    public var maxRuntimeSeconds: TimeInterval?

    public init(
        maxTargetPathCount: Int? = nil,
        maxWriteCount: Int? = nil,
        maxBytes: Int? = nil,
        maxRuntimeSeconds: TimeInterval? = nil
    ) {
        self.maxTargetPathCount = maxTargetPathCount
        self.maxWriteCount = maxWriteCount
        self.maxBytes = maxBytes
        self.maxRuntimeSeconds = maxRuntimeSeconds
    }

    public static let unlimited = Self()
}

public extension ExecutionLimits {
    var isUnlimited: Bool {
        maxTargetPathCount == nil
            && maxWriteCount == nil
            && maxBytes == nil
            && maxRuntimeSeconds == nil
    }

    func merged(
        with override: ExecutionLimits?
    ) -> ExecutionLimits {
        guard let override else {
            return self
        }

        return .init(
            maxTargetPathCount: override.maxTargetPathCount ?? maxTargetPathCount,
            maxWriteCount: override.maxWriteCount ?? maxWriteCount,
            maxBytes: override.maxBytes ?? maxBytes,
            maxRuntimeSeconds: override.maxRuntimeSeconds ?? maxRuntimeSeconds
        )
    }

    func requiresHumanReview(
        for preflight: ToolPreflight
    ) -> Bool {
        if let maxTargetPathCount,
           preflight.targetPaths.count > maxTargetPathCount {
            return true
        }

        if let maxWriteCount,
           preflight.estimatedWriteCount > maxWriteCount {
            return true
        }

        if let maxBytes,
           let estimatedByteCount = preflight.estimatedByteCount,
           estimatedByteCount > maxBytes {
            return true
        }

        if let maxRuntimeSeconds,
           let estimatedRuntimeSeconds = preflight.estimatedRuntimeSeconds,
           estimatedRuntimeSeconds > maxRuntimeSeconds {
            return true
        }

        return false
    }
}

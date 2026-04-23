import Foundation

public struct ToolPreflight: Sendable, Codable, Hashable, CustomStringConvertible {
    public let toolName: String
    public let risk: ActionRisk
    public let workspaceRoot: String?
    public let targetPaths: [String]
    public let summary: String
    public let commandPreview: String?
    public let estimatedWriteCount: Int
    public let estimatedByteCount: Int?
    public let estimatedRuntimeSeconds: TimeInterval?
    public let sideEffects: [String]
    public let limits: ExecutionLimits?

    public init(
        toolName: String,
        risk: ActionRisk,
        workspaceRoot: String? = nil,
        targetPaths: [String] = [],
        summary: String,
        commandPreview: String? = nil,
        estimatedWriteCount: Int = 0,
        estimatedByteCount: Int? = nil,
        estimatedRuntimeSeconds: TimeInterval? = nil,
        sideEffects: [String] = [],
        limits: ExecutionLimits? = nil
    ) {
        self.toolName = toolName
        self.risk = risk
        self.workspaceRoot = workspaceRoot
        self.targetPaths = targetPaths
        self.summary = summary
        self.commandPreview = commandPreview
        self.estimatedWriteCount = estimatedWriteCount
        self.estimatedByteCount = estimatedByteCount
        self.estimatedRuntimeSeconds = estimatedRuntimeSeconds
        self.sideEffects = sideEffects
        self.limits = limits
    }

    public var description: String {
        var lines: [String] = [
            "tool: \(toolName)",
            "risk: \(risk.rawValue)",
            "summary: \(summary)"
        ]

        if let workspaceRoot {
            lines.append("workspace: \(workspaceRoot)")
        }

        if !targetPaths.isEmpty {
            lines.append("targets: \(targetPaths.joined(separator: ", "))")
        }

        if let commandPreview {
            lines.append("command: \(commandPreview)")
        }

        if estimatedWriteCount > 0 {
            lines.append("estimated writes: \(estimatedWriteCount)")
        }

        if let estimatedByteCount {
            lines.append("estimated bytes: \(estimatedByteCount)")
        }

        if let estimatedRuntimeSeconds {
            lines.append("estimated runtime: \(estimatedRuntimeSeconds)s")
        }

        if !sideEffects.isEmpty {
            lines.append("side effects: \(sideEffects.joined(separator: ", "))")
        }

        return lines.joined(separator: "\n")
    }
}

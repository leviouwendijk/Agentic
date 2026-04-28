import Foundation

public enum ModeCatalogError: Error, Sendable, LocalizedError {
    case duplicateMode(String)
    case missingMode(String)

    public var errorDescription: String? {
        switch self {
        case .duplicateMode(let id):
            return "Mode catalog already contains mode '\(id)'."

        case .missingMode(let id):
            return "Mode catalog contains no mode '\(id)'."
        }
    }
}

public struct ModeCatalog: Sendable, Codable, Hashable {
    private var modes: [AgenticModeIdentifier: AgenticMode]

    public init(
        modes: [AgenticMode] = []
    ) throws {
        self.modes = [:]

        for mode in modes {
            try register(
                mode
            )
        }
    }

    public var all: [AgenticMode] {
        modes.values.sorted {
            $0.id.rawValue < $1.id.rawValue
        }
    }

    public mutating func register(
        _ mode: AgenticMode
    ) throws {
        guard modes[mode.id] == nil else {
            throw ModeCatalogError.duplicateMode(
                mode.id.rawValue
            )
        }

        modes[mode.id] = mode
    }

    public func mode(
        _ id: AgenticModeIdentifier
    ) throws -> AgenticMode {
        guard let mode = modes[id] else {
            throw ModeCatalogError.missingMode(
                id.rawValue
            )
        }

        return mode
    }

    public func selection(
        _ id: AgenticModeIdentifier,
        baseConfiguration: AgentRunnerConfiguration = .default,
        overlay: ModeOverlay = .init()
    ) throws -> ModeSelection {
        try .init(
            mode: mode(
                id
            ),
            baseConfiguration: baseConfiguration,
            overlay: overlay
        )
    }

    public static var standard: Self {
        get throws {
            try .init(
                modes: [
                    .planning,
                    .research,
                    .coder,
                    .review,
                    .debugging,
                    .cheap_utility,
                    .private
                ]
            )
        }
    }
}

public extension Agentic {
    struct ModeAPI: Sendable {
        public init() {}

        public func catalog() throws -> ModeCatalog {
            try .standard
        }

        public func selection(
            _ id: AgenticModeIdentifier,
            baseConfiguration: AgentRunnerConfiguration = .default,
            overlay: ModeOverlay = .init()
        ) throws -> ModeSelection {
            try catalog().selection(
                id,
                baseConfiguration: baseConfiguration,
                overlay: overlay
            )
        }
    }

    static let mode: ModeAPI = .init()
}

import Foundation

public enum SkillRegistryError: Error, Sendable, LocalizedError {
    case duplicateSkill(String)
    case unknownSkill(String)

    public var errorDescription: String? {
        switch self {
        case .duplicateSkill(let id):
            return "A skill with id '\(id)' is already registered."

        case .unknownSkill(let id):
            return "Unknown skill: \(id)"
        }
    }
}

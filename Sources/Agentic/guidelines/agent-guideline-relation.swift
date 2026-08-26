import Guidelines

public enum AgentGuidelineRelationship:
    String,
    Sendable,
    Codable,
    Hashable,
    CaseIterable
{
    case addresses
    case upholds
    case verifies
    case deviates
}

public struct AgentGuidelineRelation:
    Sendable,
    Codable,
    Hashable
{
    public let reference: GuidelineReference
    public let relationship: AgentGuidelineRelationship
    public let reasoning: String?

    public init(
        reference: GuidelineReference,
        relationship: AgentGuidelineRelationship,
        reasoning: String? = nil
    ) {
        self.reference = reference
        self.relationship = relationship
        self.reasoning = reasoning
    }

    public init(
        _ relationship: AgentGuidelineRelationship,
        guideline: some GuidelineReferencing,
        reasoning: String? = nil
    ) {
        self.init(
            reference: GuidelineReference(
                guideline
            ),
            relationship: relationship,
            reasoning: reasoning
        )
    }
}

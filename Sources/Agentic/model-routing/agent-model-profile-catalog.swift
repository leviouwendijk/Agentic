public protocol AgentModelProfileProvider: Sendable {
    func profiles() throws -> [AgentModelProfile]
}

public struct AgentModelProfileCatalog: Sendable {
    public let profilesByIdentifier: [AgentModelProfileIdentifier: AgentModelProfile]

    public init(
        profiles: [AgentModelProfile] = []
    ) throws {
        var profilesByIdentifier: [AgentModelProfileIdentifier: AgentModelProfile] = [:]

        for profile in profiles {
            guard !profile.identifier.rawValue.isEmpty else {
                throw AgentModelRoutingError.emptyIdentifier(
                    "profile"
                )
            }

            guard !profile.adapterIdentifier.rawValue.isEmpty else {
                throw AgentModelRoutingError.emptyIdentifier(
                    "adapter"
                )
            }

            guard !profile.model.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty else {
                throw AgentModelRoutingError.emptyModel(
                    profile.identifier
                )
            }

            profilesByIdentifier[profile.identifier] = profile
        }

        self.profilesByIdentifier = profilesByIdentifier
    }

    public init(
        providers: [any AgentModelProfileProvider]
    ) throws {
        var profiles: [AgentModelProfile] = []

        for provider in providers {
            profiles.append(
                contentsOf: try provider.profiles()
            )
        }

        try self.init(
            profiles: profiles
        )
    }

    public func profile(
        _ identifier: AgentModelProfileIdentifier
    ) throws -> AgentModelProfile {
        guard let profile = profilesByIdentifier[identifier] else {
            throw AgentModelRoutingError.profileNotFound(
                identifier
            )
        }

        return profile
    }

    public func profiles(
        for purpose: AgentModelRoutePurpose
    ) -> [AgentModelProfile] {
        profilesByIdentifier.values
            .filter {
                $0.purposes.contains(
                    purpose
                )
            }
            .sorted(
                by: AgentModelProfileOrdering.preferred
            )
    }
}

private enum AgentModelProfileOrdering {
    static func preferred(
        lhs: AgentModelProfile,
        rhs: AgentModelProfile
    ) -> Bool {
        if lhs.cost.rank != rhs.cost.rank {
            return lhs.cost.rank < rhs.cost.rank
        }

        if lhs.latency.rank != rhs.latency.rank {
            return lhs.latency.rank < rhs.latency.rank
        }

        if lhs.privacy.rank != rhs.privacy.rank {
            return lhs.privacy.rank > rhs.privacy.rank
        }

        return lhs.identifier.rawValue < rhs.identifier.rawValue
    }
}

import Agentic
import Schema

public extension Standard.Agents {
    /// An unspecialized Agent over whatever the application installs. Domains
    /// beyond Standard are named by namespace because core cannot import
    /// them; any that are not installed simply contribute nothing.
    @Agent
    enum GeneralPurpose {
        public typealias Input = String
        public typealias Output = String

        public static let purpose = """
        General-purpose Agent that follows the user's request using the capabilities the application installs.
        """

        public static let instructions = """
        Follow the user's request.

        Few tools are visible at first. Use \(Standard.Tools.FindCapabilities.identifier.rawValue) \
        to find an installed capability you need, and \(Standard.Tools.InspectCapability.identifier.rawValue) \
        to read its contract before using it.

        Ask with \(Standard.Tools.ClarifyWithUser.identifier.rawValue) only when the request cannot \
        reasonably be completed from the available context.

        Respect approval requirements for consequential actions, and report \
        what actually happened rather than what was intended.
        """

        public static let capabilities = AgentCapabilities(
            available: .init(
                namespaces: [
                    Standard.definition.namespace,
                    "harness",
                    "math",
                    "assertions",
                    "tasks",
                    "system_io",
                    "git",
                    "shell",
                    "sessions",
                ]
            ),
            visible: .init(
                tools: .init(
                    members: [
                        Standard.Tools.ClarifyWithUser.identifier,
                        Standard.Tools.FindCapabilities.identifier,
                        Standard.Tools.InspectCapability.identifier,
                    ]
                )
            )
        )
    }
}

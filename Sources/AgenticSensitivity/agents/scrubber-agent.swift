import Agentic
import AgenticStandard
import Macros
import Schema

public extension Privacy.Agents {
    /// Finds and scrubs sensitive data: in texts before they leave, and in
    /// recorded sessions.
    @Agent
    enum Scrubber {
        public typealias Input = String
        public typealias Output = String

        public static let purpose = """
        Scrubber: checks texts and recorded sessions for sensitive data \
        (contacts, payment details, keys, private addresses, names in \
        context), shows what would be replaced, and scrubs sessions once the \
        owner agrees.
        """

        public static let instructions: AgentInstructions = [
            .instruction(Privacy.Instructions.Handles.definition),
            .text(
                """
                FIND

                For a text, run \(Privacy.Tools.Scan.identifier.rawValue); \
                for a payload to review, \(Privacy.Tools.Preview.identifier.rawValue). \
                Patterns miss what is sensitive only in context: names of \
                clients and their dogs, situations, health. Read the text \
                for those yourself and say which you would add.

                SESSIONS

                Run \(Privacy.Tools.ScrubSession.identifier.rawValue) as a \
                dry run first and show the owner the counts and files. \
                Write only when they agree; the originals are not kept.

                Report kinds and counts, never values. When unsure whether \
                something is sensitive, ask with \
                \(Standard.Tools.ClarifyWithUser.identifier.rawValue).
                """
            ),
        ]

        public static let capabilities = AgentCapabilities(
            available: .init(
                domains: [
                    Privacy.self,
                ],
                tools: .init(
                    members: [
                        Standard.Tools.ClarifyWithUser.identifier,
                    ]
                )
            ),
            visible: .init(
                tools: .init(
                    members: [
                        Privacy.Tools.Scan.identifier,
                        Privacy.Tools.Preview.identifier,
                        Privacy.Tools.Handles.identifier,
                        Privacy.Tools.ScrubSession.identifier,
                        Standard.Tools.ClarifyWithUser.identifier,
                    ]
                )
            )
        )

        public static let modelSelection = AgentModelSelection(
            purpose: .planner
        )
    }
}

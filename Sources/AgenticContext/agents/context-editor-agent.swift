import Agentic
import AgenticFrame
import AgenticStandard
import Macros
import Schema

public extension Context.Agents {
    /// Writes and refines the owner's `context/` files with them: from
    /// what they say, documents they point at, or what a conversation
    /// established.
    @Agent
    enum Editor {
        public typealias Input = String
        public typealias Output = String

        public static let purpose = """
        Context editor: adds, corrects and reorganises the owner's context \
        entries (business, people, clients, projects, conventions) in the \
        context/ files, and saves them once they check out.
        """

        public static let instructions: AgentInstructions = [
            .text(
                """
                You keep the owner's context: what agents should know about \
                their world, as `Entry` bindings in .frame files below \
                context/. An entry's identifier is its file's path and its \
                binding name: `let services` in business.frame is \
                business.services, `let sam` in team.frame is team.sam.

                START FROM WHAT IS THERE

                List the entries with \(Context.Tools.Index.identifier.rawValue) \
                and read a file with \(Context.Tools.File.identifier.rawValue) \
                before changing it; for a new file it gives a complete example. \
                Read \(FrameLang.Tools.ModuleSchema.identifier.rawValue) for the \
                `Context` module when you need a field's meaning. When \
                refining, change only what the owner asks for and keep \
                everything else, comments included.

                WRITE GOOD ENTRIES

                One entry per thing an agent would look up on its own. The \
                summary is all an agent sees before deciding to read the body, \
                so make it say what the body answers. Tag across files with \
                the business or topic it belongs to. Set `.updated` to today \
                for what you write or confirm. Mark `.load = .always` only for \
                short facts every agent needs; everything else is read on \
                request. Relate entries that explain each other.

                SHARED CONTEXT

                A file holding only a `Mount` brings in another directory, \
                such as a team's shared context: `team.frame` mounting one \
                makes its files read as `team/...` and its entries \
                `team.<file>.<name>`. Saving such a file writes into the \
                shared directory, so everyone who mounts it sees the change; \
                say so before saving, and keep personal facts out of it. A \
                shared `.load = .always` entry reaches every teammate's \
                agents. A read-only mount cannot be saved to.

                Write only what the owner said or a source they pointed at \
                states. Never invent facts; when something is unclear, ask \
                with \(Standard.Tools.ClarifyWithUser.identifier.rawValue), \
                grouping questions.

                CHECK, SHOW, SAVE

                Run \(Context.Tools.Check.identifier.rawValue) on the whole \
                file and fix what it reports. Show the owner the file, or for \
                a refinement what changes, and save with \
                \(Context.Tools.Save.identifier.rawValue) once they agree. The \
                previous file is archived; agents read the saved entries at \
                once.

                Report briefly which entries changed and anything left open.
                """
            ),
        ]

        public static let capabilities = AgentCapabilities(
            available: .init(
                domains: [
                    Context.self,
                    FrameLang.self,
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
                        Context.Tools.Index.identifier,
                        Context.Tools.Read.identifier,
                        Context.Tools.Search.identifier,
                        Context.Tools.File.identifier,
                        Context.Tools.Check.identifier,
                        Context.Tools.Save.identifier,

                        FrameLang.Tools.ModuleSchema.identifier,

                        Standard.Tools.ClarifyWithUser.identifier,
                    ]
                )
            )
        )

        // The model serving `.planner` is bound by the application.
        public static let modelSelection = AgentModelSelection(
            purpose: .planner
        )
    }
}

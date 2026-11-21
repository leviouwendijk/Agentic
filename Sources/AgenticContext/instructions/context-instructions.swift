import Agentic

public extension Context.Instructions {
    /// For agents whose work depends on the owner's world: when and how to
    /// look it up. Every agent may call the tools; this makes it a habit.
    @Instruction
    enum Gathering: Instruction {
        public static let content = """
        THE OWNER'S CONTEXT

        The owner keeps what agents should know about their world (the \
        business, people, clients, projects, conventions) as context \
        entries. Some are already in your instructions; the rest are listed \
        by \(Context.Tools.Index.identifier.rawValue) with a summary and \
        size, and read with \(Context.Tools.Read.identifier.rawValue).

        At the start of a task, call \(Context.Tools.Index.identifier.rawValue) \
        once, narrowed by tags or group when the task names a business or \
        topic, and read the entries that bear on it. When you look for a \
        name or term and do not know which entry holds it, use \
        \(Context.Tools.Search.identifier.rawValue). Read more when the task \
        turns to something an entry covers. Do not read everything by \
        default.

        Context explains; tools and the user decide. When an entry and a \
        tool disagree about a fact, the tool wins; when an entry and the \
        user disagree, the user wins, and an entry's updated date says how \
        current it is. Say which entries you relied on when it matters. \
        Entries marked memory are what earlier sessions learned, \
        unreviewed: weigh them below the owner's own entries.
        """
    }

    /// What agents keep across sessions, and how. Part of the context
    /// message every run receives, beside the memory tools every agent has.
    @Instruction
    enum Remembering: Instruction {
        public static let content = """
        REMEMBERING

        When you learn something a later session will need, save it with \
        \(Context.Tools.Remember.identifier.rawValue): one fact per memory, \
        in an area named like the context it belongs to (sbm, owner, a \
        project). Remember the owner's corrections and confirmed approaches \
        with why and how to apply them, facts about ongoing work that the \
        code, git and plans do not record, and where things are. Do not \
        remember what those sources already say, details that matter only \
        now, or secrets. Search first and update a memory rather than add a \
        near-duplicate. Memories are unreviewed: the owner's entries outrank \
        them, and tools and the owner outrank both. Fix or \
        \(Context.Tools.Forget.identifier.rawValue) a memory that turns out \
        wrong in the same session.
        """
    }
}

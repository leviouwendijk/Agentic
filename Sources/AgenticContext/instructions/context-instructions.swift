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
        current it is. Say which entries you relied on when it matters.
        """
    }
}

import Agentic
import Macros

public extension Privacy.Instructions {
    /// How to work with handles. For agents in sessions with a privacy
    /// guard.
    @Instruction
    enum Handles: Instruction {
        public static let content = """
        Sensitive values (mail addresses, phone numbers, IBANs, keys, private \
        addresses) reach you as handles such as ⟦contact:7f3a91c2⟧. A handle \
        is the value for every purpose but reading it: pass it to tools \
        exactly as written, in any field or inside text, and the tool works \
        with the real value.

        - Never guess, reconstruct or ask for the value behind a handle.
        - \(Privacy.Tools.Handles.identifier.rawValue) tells what a handle \
        is: kind, masked preview, where it was seen, which tools may use it.
        - Tools of the domain a value came from may use it; others refuse it. \
        When a tool refuses one, ask the owner with \
        \(Privacy.Tools.Grant.identifier.rawValue), saying which tool needs it \
        and why.
        - An unknown or expired handle: read the value again from its source.
        - Write handles into drafts and files as they are; the tool resolves \
        them, so the right value lands there.
        """
    }
}

public extension SensitivityFrame {
    /// A complete `domains/sensitivity.frame`, every field at its default
    /// unless noted.
    static let example = """
        import Sensitivity;

        // Sensitive values reach models and session records as handles
        // (⟦kind:id⟧ tokens); the values stay in this vault.
        let vault: Vault = .{
            .store = .keychain,          // or .memory: values end with the process
            .expire = .unreferenced,     // or .onSessionClose, or .afterDays with .days = 14
            .references = .history,      // or .sessions
        };

        let policy: Policy = .{
            .handleAt = 80,              // findings scoring this or more become handles
            .softAt = 60,                // soft handles any tool may use; lower ones are flagged
            .never = ["info@example.com"],     // public values, never replaced
            .families = [["notes_read", "drafts_write"]],   // tools sharing values besides a name prefix
        };
        """
}

public extension SensitivityFrame {
    /// What the first run writes to `domains/sensitivity.frame`: every
    /// field at its default, ready to edit.
    static let template = """
        import Sensitivity;

        // Sensitive values reach models and session records as handles
        // (⟦kind:id⟧ tokens); the values stay in this vault. Everything here is
        // the default; the file may also be left out.
        let vault: Vault = .{
            .store = .keychain,          // one Keychain item, deleted when it empties; or .memory
            .expire = .unreferenced,     // kept while anything in history references the handle;
                                         // or .onSessionClose, or .afterDays with .days = 14
            .references = .history,      // history: the whole agentic home; or .sessions only
            .roots = [],                 // more history directories, such as a provenance store
        };

        let policy: Policy = .{
            .handleAt = 80,              // findings scoring this or more become handles
            .softAt = 60,                // soft handles any tool may use; lower ones are flagged
            .never = [],                 // public values never replaced, such as the business's public address
        };

        """
}

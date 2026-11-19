public extension SensitivityFrame {
    /// A complete `domains/sensitivity.frame`, every field at its default
    /// unless noted.
    static let example = """
        import Sensitivity;

        // Sensitive values reach models and session records as handles
        // (⟦contact:7f3a91c2⟧); the values stay in this vault.
        let vault: Vault = .{
            .store = .keychain,          // or .memory: values end with the process
            .expire = .unreferenced,     // or .onSessionClose, or .afterDays with .days = 14
        };

        let policy: Policy = .{
            .handleAt = 80,              // findings scoring this or more become handles
            .softAt = 60,                // soft handles any tool may use; lower ones are flagged
            .never = ["info@example.com"],     // public values, never replaced
            .families = [["notes_read", "drafts_write"]],   // tools sharing values besides a name prefix
        };
        """
}

import Path

public extension PathAccessPolicy {
    static let agenticWorkspaceDefault = Self(
        rules: [
            .denyComponent(
                ".build",
                reason: "SwiftPM build output is excluded by default."
            ),
            .denyComponent(
                ".index-build",
                reason: "Index build output is excluded by default."
            ),
            .denyComponent(
                ".git",
                reason: "Git internals are excluded by default."
            ),
            .denyComponent(
                ".agentic",
                reason: "Agentic runtime state is excluded by default."
            ),
            .denyBasename(
                ".env",
                reason: "Environment files are excluded by default."
            ),
            .denyExpression(
                AgenticWorkspaceDefaultAccessPatterns.envVariant,
                reason: "Environment file variants are excluded by default."
            ),
            .denySuffix(
                ".pem",
                reason: "Private certificate material is excluded by default."
            ),
            .denySuffix(
                ".key",
                reason: "Key material is excluded by default."
            ),
            .denySuffix(
                ".p12",
                reason: "Keychain export material is excluded by default."
            ),
            .denySuffix(
                ".p8",
                reason: "Signing keys are excluded by default."
            ),
            .denySuffix(
                ".cer",
                reason: "Certificate material is excluded by default."
            ),
            .denySuffix(
                ".crt",
                reason: "Certificate material is excluded by default."
            ),
            .denySuffix(
                ".der",
                reason: "Certificate material is excluded by default."
            ),
            .denySuffix(
                ".mobileprovision",
                reason: "Provisioning profiles are excluded by default."
            )
        ],
        defaultDecision: .allow
    )
}

private enum AgenticWorkspaceDefaultAccessPatterns {
    static let envVariant = PathExpression(
        anchor: .relative,
        pattern: PathPattern(
            [
                .recursive,
                .componentPattern(".env.*")
            ],
            terminalHint: .file
        )
    )
}

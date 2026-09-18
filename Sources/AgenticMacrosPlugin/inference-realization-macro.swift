import MacroEngine
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InferenceRealizationMacro:
    MemberMacro,
    ExtensionMacro
{
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try DeclarationMacroEngine<
            InferenceRealizationMacroSpecification
        >.members(
            of: declaration,
            macroName: "InferenceRealization",
            lexicalContext: context.lexicalContext
        )
    }

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try DeclarationMacroEngine<
            InferenceRealizationMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            macroName: "InferenceRealization",
            lexicalContext: context.lexicalContext
        )
    }
}

private enum InferenceRealizationMacroSpecification:
    DeclarationMacroSpecification
{
    static let supportedKinds: Set<DeclarationMacroKind> = [
        .struct,
        .enum,
    ]

    static let conformance: String? =
        "InferenceRealization"

    static func members(
        in context: DeclarationMacroContext
    ) throws -> [DeclSyntax] {
        let access = context.accessPrefix
        let identifier = semanticIdentifier(
            context.lexicalPath
        )

        return [
            DeclSyntax(
                stringLiteral:
                    "\(access)static let definition: InferenceRealizationDefinition<InferenceType> = .init(identifier: .init(rawValue: \"\(identifier)\"), configuration: .init(strategy: Self.strategy, instructions: Self.instructions, budget: Self.budget, recovery: Self.recovery, adapter: Self.adapter, demonstrations: Self.demonstrations, generation: Self.generation, metadata: Self.metadata))"
            ),
        ]
    }
}

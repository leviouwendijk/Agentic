import MacroEngine
import Primitives
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DomainMacro:
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
            DomainMacroSpecification
        >.members(
            of: declaration,
            macroName: "Domain",
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
            DomainMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            macroName: "Domain",
            lexicalContext: context.lexicalContext
        )
    }
}

private enum DomainMacroSpecification:
    DeclarationMacroSpecification
{
    static let supportedKinds: Set<DeclarationMacroKind> = [
        .enum,
    ]

    static let conformance: String? = "Domain"

    static func members(
        in context: DeclarationMacroContext
    ) throws -> [DeclSyntax] {
        let access = semanticMemberAccessPrefix(context)
        let namespace = Case.convert(
            context.name,
            to: .snake
        )

        return [
            DeclSyntax(
                stringLiteral:
                    "\(access)static let definition: DomainDefinition = .init(namespace: .init(rawValue: \"\(namespace)\"))"
            ),
            DeclSyntax(
                stringLiteral: "\(access)enum Agents {}"
            ),
            DeclSyntax(
                stringLiteral: "\(access)enum Inferences {}"
            ),
            DeclSyntax(
                stringLiteral: "\(access)enum Programs {}"
            ),
            DeclSyntax(
                stringLiteral: "\(access)enum Tools {}"
            ),
            DeclSyntax(
                stringLiteral: "\(access)enum Realizations {}"
            ),
            DeclSyntax(
                stringLiteral: "\(access)enum Optimizations {}"
            ),
        ]
    }
}

import MacroEngine
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// An Instruction emits metadata only. It has no DomainInstallation installer
/// and cannot add capabilities to a running Agent.
public struct InstructionMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try DeclarationMacroEngine<InstructionMacroSpecification>.members(
            of: declaration,
            macroName: "Instruction",
            lexicalContext: context.lexicalContext
        ) { semantic in
            let access = semanticMemberAccessPrefix(semantic)
            let identifier = semanticIdentifier(semantic.lexicalPath)
            return [
                DeclSyntax(stringLiteral:
                    "\(access)static let definition: InstructionDefinition = .init(identifier: .init(rawValue: \"\(identifier)\"), content: Self.content, source: Self.source)"),
                catalogFactoryDeclaration(
                    in: semantic,
                    category: "Instructions",
                    declaration: ".instruction(Self.definition)"
                ),
            ]
        }
    }

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try DeclarationMacroEngine<InstructionMacroSpecification>.extensions(
            of: declaration,
            type: type,
            conformingTo: protocols,
            macroName: "Instruction",
            lexicalContext: context.lexicalContext
        )
    }
}

private enum InstructionMacroSpecification: DeclarationMacroSpecification {
    static let supportedKinds: Set<DeclarationMacroKind> = [.enum, .struct]
    static let conformance: String? = "Instruction"
    static func members(in _: DeclarationMacroContext) throws -> [DeclSyntax] { [] }
}

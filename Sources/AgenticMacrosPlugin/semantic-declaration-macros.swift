import MacroEngine
import Primitives
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AgentMacro:
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
            AgentMacroSpecification
        >.members(
            of: declaration,
            macroName: "Agent",
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
            AgentMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            macroName: "Agent",
            lexicalContext: context.lexicalContext
        )
    }
}

public struct InferenceMacro:
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
            InferenceMacroSpecification
        >.members(
            of: declaration,
            macroName: "Inference",
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
            InferenceMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            macroName: "Inference",
            lexicalContext: context.lexicalContext
        )
    }
}

public struct ProgramMacro:
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
            ProgramMacroSpecification
        >.members(
            of: declaration,
            macroName: "Program",
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
            ProgramMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            macroName: "Program",
            lexicalContext: context.lexicalContext
        )
    }
}

public struct ToolMacro:
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
            ToolMacroSpecification
        >.members(
            of: declaration,
            macroName: "Tool",
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
            ToolMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            macroName: "Tool",
            lexicalContext: context.lexicalContext
        )
    }
}

private enum AgentMacroSpecification:
    DeclarationMacroSpecification
{
    static let supportedKinds: Set<DeclarationMacroKind> = [
        .struct,
        .enum,
    ]

    static let conformance: String? = "Agent"

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
                    "\(access)static let definition: AgentDefinition = .init(identifier: .init(rawValue: \"\(identifier)\"), purpose: Self.purpose)"
            ),
        ]
    }
}

private enum InferenceMacroSpecification:
    DeclarationMacroSpecification
{
    static let supportedKinds: Set<DeclarationMacroKind> = [
        .struct,
        .enum,
    ]

    static let conformance: String? = "Inference"

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
                    "\(access)static let definition: InferenceDefinition = .init(identifier: .init(rawValue: \"\(identifier)\"), purpose: Self.purpose)"
            ),
        ]
    }
}

private enum ProgramMacroSpecification:
    DeclarationMacroSpecification
{
    static let supportedKinds: Set<DeclarationMacroKind> = [
        .struct,
    ]

    static let conformance: String? = "Program"

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
                    "\(access)static let definition: ProgramDefinition = .init(identifier: .init(rawValue: \"\(identifier)\"), purpose: Self.purpose)"
            ),
        ]
    }
}

private enum ToolMacroSpecification:
    DeclarationMacroSpecification
{
    static let supportedKinds: Set<DeclarationMacroKind> = [
        .struct,
    ]

    static let conformance: String? = "Tool"

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
                    "\(access)static let definition: ToolDefinition = .init(identifier: .init(rawValue: \"\(identifier)\"), purpose: Self.purpose, risk: Self.risk)"
            ),
        ]
    }
}

func semanticIdentifier(
    _ lexicalPath: [String]
) -> String {
    lexicalPath
        .map {
            Case.convert(
                $0,
                to: .snake
            )
        }
        .joined(separator: ".")
}

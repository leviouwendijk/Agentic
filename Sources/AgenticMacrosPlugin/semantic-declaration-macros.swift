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
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try DeclarationMacroEngine<
            AgentMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            conformingTo: protocols,
            macroName: "Agent",
            lexicalContext: context.lexicalContext
        )
    }
}

public struct InferenceMacro:
    MemberMacro,
    // MemberAttributeMacro,
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
        attachedTo _: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        contractMemberAttributes(
            for: member,
            inputMacro: "_SemanticInput",
            inputConformance: "SemanticInput",
            outputMacro: "_InferredOutput",
            outputConformance: "InferredOutput"
        )
    }

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try DeclarationMacroEngine<
            InferenceMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            conformingTo: protocols,
            macroName: "Inference",
            lexicalContext: context.lexicalContext
        )
    }
}

public struct ProgramMacro:
    MemberMacro,
    // MemberAttributeMacro,
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
        attachedTo _: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        contractMemberAttributes(
            for: member,
            inputMacro: "_SemanticInput",
            inputConformance: "SemanticInput",
            outputMacro: "_SemanticOutput",
            outputConformance: "SemanticOutput"
        )
    }

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try DeclarationMacroEngine<
            ProgramMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            conformingTo: protocols,
            macroName: "Program",
            lexicalContext: context.lexicalContext
        )
    }
}

public struct ToolMacro:
    MemberMacro,
    // MemberAttributeMacro,
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
        attachedTo _: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        contractMemberAttributes(
            for: member,
            inputMacro: "_ToolInput",
            inputConformance: "ToolInput",
            outputMacro: "_ToolOutput",
            outputConformance: "ToolOutput"
        )
    }

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try DeclarationMacroEngine<
            ToolMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            conformingTo: protocols,
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
        let access = semanticMemberAccessPrefix(context)
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
        let access = semanticMemberAccessPrefix(context)
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
        let access = semanticMemberAccessPrefix(context)
        let identifier = semanticIdentifier(
            context.lexicalPath
        )

        return [
            DeclSyntax(
                stringLiteral:
                    "\(access)static let definition: ProgramDefinition = .init(identifier: .init(rawValue: \"\(identifier)\"), purpose: Self.purpose)"
            ),
            DeclSyntax(
                stringLiteral:
                    "\(access)typealias Site<InferenceType: Inference> = InferenceSite<\(context.name), InferenceType>"
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
        let access = semanticMemberAccessPrefix(context)
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

func semanticMemberAccessPrefix(
    _ context: DeclarationMacroContext
) -> String {
    if context.access == "private" {
        return "fileprivate "
    }

    return context.accessPrefix
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

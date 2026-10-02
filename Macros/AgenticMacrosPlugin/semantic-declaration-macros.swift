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
    ExtensionMacro
{
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        _ = try inferenceMacroKind(
            from: attribute
        )

        return try DeclarationMacroEngine<
            InferenceMacroSpecification
        >.members(
            of: declaration,
            macroName: "Inference",
            lexicalContext: context.lexicalContext
        )
    }

    public static func expansion(
        of attribute: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        switch try inferenceMacroKind(
            from: attribute
        ) {
        case .generative:
            return try DeclarationMacroEngine<
                InferenceMacroSpecification
            >.extensions(
                of: declaration,
                type: type,
                conformingTo: protocols,
                macroName: "Inference",
                lexicalContext: context.lexicalContext
            )

        case .decision:
            let inferenceExtensions = try DeclarationMacroEngine<
                InferenceMacroSpecification
            >.extensions(
                of: declaration,
                type: type,
                conformingTo: protocols,
                macroName: "Inference",
                lexicalContext: context.lexicalContext
            )

            let decisionExtensions = try DeclarationMacroEngine<
                DecisionInferenceMacroSpecification
            >.extensions(
                of: declaration,
                type: type,
                conformingTo: protocols,
                macroName: "Inference",
                lexicalContext: context.lexicalContext
            )

            return inferenceExtensions
                + decisionExtensions
        }
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
    ExtensionMacro
{
    public static func expansion(
        of attribute: AttributeSyntax,
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
        ) { declarationContext in
            let identifier = try toolIdentifier(
                from: attribute,
                declarationName: declarationContext.name
            )
            let access = semanticMemberAccessPrefix(
                declarationContext
            )
            return [
                DeclSyntax(
                    stringLiteral:
                        "\(access)static let identifier: ToolIdentifier = .init(rawValue: \"\(identifier)\")"
                ),
                DeclSyntax(
                    stringLiteral:
                        "\(access)static let definition: ToolDefinition = .init(identifier: Self.identifier, purpose: Self.purpose, risk: Self.risk)"
                ),
                catalogFactoryDeclaration(
                    in: declarationContext,
                    category: "Tools",
                    declaration: ".tool(Self.definition)"
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
                    "\(access)static let definition: AgentDefinition = .init(identifier: .init(rawValue: \"\(identifier)\"), purpose: Self.purpose, instructions: Self.instructions, capabilities: Self.capabilities, delegation: Self.delegation)"
            ),
            catalogFactoryDeclaration(
                in: context,
                category: "Agents",
                declaration: ".agent(Self.definition)"
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
            catalogFactoryDeclaration(
                in: context,
                category: "Inferences",
                declaration: ".inference(Self.definition)"
            ),
        ]
    }
}

private enum DecisionInferenceMacroSpecification:
    DeclarationMacroSpecification
{
    static let supportedKinds =
        InferenceMacroSpecification.supportedKinds

    static let conformance: String? =
        "DecisionInference"

    static func members(
        in context: DeclarationMacroContext
    ) throws -> [DeclSyntax] {
        try InferenceMacroSpecification.members(
            in: context
        )
    }
}

private enum InferenceMacroKind {
    case generative
    case decision
}

private func inferenceMacroKind(
    from attribute: AttributeSyntax
) throws -> InferenceMacroKind {
    guard let arguments = attribute.arguments else {
        return .generative
    }

    guard case let .argumentList(argumentList) = arguments,
          argumentList.count == 1,
          let argument = argumentList.first,
          argument.label == nil,
          let member = argument.expression.as(
            MemberAccessExprSyntax.self
          ),
          member.base == nil
    else {
        throw MacroExpansionErrorMessage(
            "@Inference accepts zero arguments or one static kind: .generative or .decision."
        )
    }

    switch member.declName.baseName.text {
    case "generative":
        return .generative

    case "decision":
        return .decision

    default:
        throw MacroExpansionErrorMessage(
            "@Inference kind must be .generative or .decision."
        )
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
            catalogFactoryDeclaration(
                in: context,
                category: "Programs",
                declaration: ".program(Self.definition)"
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
        in _: DeclarationMacroContext
    ) throws -> [DeclSyntax] {
        []
    }
}

func toolIdentifier(
    from attribute: AttributeSyntax,
    declarationName: String
) throws -> String {
    guard let arguments = attribute.arguments else {
        return semanticIdentifier(
            [declarationName]
        )
    }

    guard case let .argumentList(argumentList) = arguments,
          argumentList.count == 1,
          let argument = argumentList.first,
          argument.label == nil,
          let literal = argument.expression.as(
              StringLiteralExprSyntax.self
          ),
          literal.segments.count == 1,
          let segment = literal.segments.first?.as(
              StringSegmentSyntax.self
          )
    else {
        throw MacroExpansionErrorMessage(
            "@Tool accepts zero arguments or one static string identifier override."
        )
    }

    let identifier = segment.content.text

    guard !identifier.isEmpty else {
        throw MacroExpansionErrorMessage(
            "@Tool identifier override must not be empty."
        )
    }

    return identifier
}

func catalogFactoryDeclaration(
    in context: DeclarationMacroContext,
    category: String,
    declaration: String
) -> DeclSyntax {
    let lexicalPath = context.lexicalPath

    let namespaceExpression: String

    if lexicalPath.count >= 3,
       lexicalPath[1] == category
    {
        let domainNamespace = Case.convert(
            lexicalPath[0],
            to: .snake
        )

        namespaceExpression =
            "\"\(domainNamespace)\""
    } else {
        namespaceExpression = "nil"
    }

    return DeclSyntax(
        stringLiteral:
            """
            #if objectFormat(MachO)
            @section("__DATA,__agentic")
            @used
            #endif
            static let _agentic_catalog_factory: @convention(c) () -> UnsafeMutableRawPointer = {
                _agentic_catalog_entry(
                    namespace: \(namespaceExpression),
                    declaration: \(declaration)
                )
            }
            """
    )
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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ContractConformanceMacro:
    ExtensionMacro
{
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo _: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try protocols.map { protocolType in
            try ExtensionDeclSyntax(
                "extension \(type.trimmed): \(protocolType.trimmed) {}"
            )
        }
    }
}

func contractMemberAttributes(
    for member: some DeclSyntaxProtocol,
    inputMacro: String,
    inputConformance: String,
    outputMacro: String,
    outputConformance: String
) -> [AttributeSyntax] {
    guard let declaration = contractMemberDeclaration(
        member
    ) else {
        return []
    }

    switch declaration.name {
    case "Input":
        return contractConformanceAttribute(
            macro: inputMacro,
            conformance: inputConformance,
            inheritanceClause: declaration.inheritanceClause
        )

    case "Output":
        return contractConformanceAttribute(
            macro: outputMacro,
            conformance: outputConformance,
            inheritanceClause: declaration.inheritanceClause
        )

    default:
        return []
    }
}

private struct ContractMemberDeclaration {
    let name: String
    let inheritanceClause: InheritanceClauseSyntax?
}

private func contractMemberDeclaration(
    _ member: some DeclSyntaxProtocol
) -> ContractMemberDeclaration? {
    if let declaration = member.as(
        StructDeclSyntax.self
    ) {
        return .init(
            name: declaration.name.text,
            inheritanceClause: declaration.inheritanceClause
        )
    }

    if let declaration = member.as(
        EnumDeclSyntax.self
    ) {
        return .init(
            name: declaration.name.text,
            inheritanceClause: declaration.inheritanceClause
        )
    }

    return nil
}

private func contractConformanceAttribute(
    macro: String,
    conformance: String,
    inheritanceClause: InheritanceClauseSyntax?
) -> [AttributeSyntax] {
    guard !explicitlyConforms(
        inheritanceClause,
        to: conformance
    ) else {
        return []
    }

    return [
        AttributeSyntax(
            stringLiteral: "@\(macro)"
        ),
    ]
}

private func explicitlyConforms(
    _ inheritanceClause: InheritanceClauseSyntax?,
    to conformance: String
) -> Bool {
    inheritanceClause?.inheritedTypes.contains { inheritedType in
        inheritedType.type.trimmedDescription == conformance
    } ?? false
}

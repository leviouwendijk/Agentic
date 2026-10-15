import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Registers a top-level legacy declaration in a typed Domain without changing
/// its public Swift name or creating a second authored identity.
public struct DomainMemberMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.as(StructDeclSyntax.self) != nil else {
            throw MacroExpansionErrorMessage(
                "@DomainMember requires a Tool or @Program struct."
            )
        }
        guard case .argumentList(let arguments) = attribute.arguments,
              arguments.count == 1,
              let expression = arguments.first?.expression.trimmedDescription,
              expression.hasSuffix(".self")
        else {
            throw MacroExpansionErrorMessage(
                "@DomainMember expects a typed Domain metatype, such as SwiftLang.self."
            )
        }
        let domainType = String(expression.dropLast(".self".count))
        guard !domainType.isEmpty,
              domainType.split(separator: ".").allSatisfy({ part in
                  !part.isEmpty && part.allSatisfy { character in
                      character.isLetter || character.isNumber || character == "_"
                  }
              })
        else {
            throw MacroExpansionErrorMessage(
                "@DomainMember expects a statically named Domain type."
            )
        }

        let isProgram = declaration.attributes.contains { item in
            guard let attribute = item.as(AttributeSyntax.self) else {
                return false
            }
            return attribute.attributeName.trimmedDescription == "Program"
        }
        if !isProgram {
            guard let structure = declaration.as(StructDeclSyntax.self),
                  structure.inheritanceClause?.inheritedTypes.contains(where: { type in
                      type.type.trimmedDescription == "Tool"
                  }) == true
            else {
                throw MacroExpansionErrorMessage(
                    "@DomainMember supports Tool structs or @Program structs."
                )
            }
        }

        let member = isProgram ? ".program(Self.definition)" : ".tool(Self.definition)"
        let installer = defaultConstructionInstaller(
            for: declaration,
            expression: isProgram
                ? "{ sink in sink.install(Self(), realization: nil) }"
                : "{ sink in sink.install(Self()) }"
        )
        let installerExpression = installer ?? "nil"
        return [DeclSyntax(stringLiteral: """
            #if objectFormat(MachO)
            @section("__DATA,__agentic")
            @used
            #elseif objectFormat(ELF)
            @section("agentic_catalog")
            @used
            #endif
            static let _agentic_catalog_factory: @convention(c) () -> UnsafeMutableRawPointer = {
                _agentic_catalog_entry(
                    namespace: \(domainType).definition.namespace.rawValue,
                    declaration: \(member),
                    installer: \(installerExpression)
                )
            }
            """)]

    }
}

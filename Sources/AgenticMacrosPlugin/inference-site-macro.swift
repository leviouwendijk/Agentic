import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct InferenceSiteMacro:
    AccessorMacro
{
    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let variable = declaration.as(
            VariableDeclSyntax.self
        ) else {
            throw MacroExpansionErrorMessage(
                "@InferenceSite can only attach to a variable declaration."
            )
        }

        guard variable.modifiers.contains(
            where: { modifier in
                modifier.name.tokenKind == .keyword(.static)
            }
        ) else {
            throw MacroExpansionErrorMessage(
                "@InferenceSite requires a static variable."
            )
        }

        guard variable.bindings.count == 1,
            let binding = variable.bindings.first,
            let pattern = binding.pattern.as(
                IdentifierPatternSyntax.self
            )
        else {
            throw MacroExpansionErrorMessage(
                "@InferenceSite requires exactly one named variable binding."
            )
        }

        guard binding.typeAnnotation != nil else {
            throw MacroExpansionErrorMessage(
                "@InferenceSite requires an explicit Site<Inference> type."
            )
        }

        guard binding.initializer == nil,
            binding.accessorBlock == nil
        else {
            throw MacroExpansionErrorMessage(
                "@InferenceSite supplies the property accessor and does not accept an initializer or existing accessor."
            )
        }

        let propertyName = pattern.identifier.text
        let siteName = semanticIdentifier(
            [propertyName]
        )

        return [
            """
            get {
                .init(
                    identifier: .init(
                        rawValue: "\\(Self.definition.identifier.rawValue).sites.\(raw: siteName)"
                    )
                )
            }
            """,
        ]
    }
}

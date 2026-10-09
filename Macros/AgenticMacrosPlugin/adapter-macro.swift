import MacroEngine
import Primitives
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AdapterMacro: MemberMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try DeclarationMacroEngine<AdapterMacroSpecification>.members(
            of: declaration, macroName: "Adapter",
            lexicalContext: context.lexicalContext
        ) { semantic in
            let access = semanticMemberAccessPrefix(semantic)
            let id = semanticIdentifier(semantic.lexicalPath)
            return [
                DeclSyntax(stringLiteral:
                    "\(access)static let definition: InferenceAdapterDefinition = .init(identifier: .init(rawValue: \"\(id)\"))"),
                DeclSyntax(stringLiteral:
                    "\(access)var identifier: InferenceAdapterIdentifier { Self.definition.identifier }"),
                catalogFactoryDeclaration(
                    in: semantic,
                    category: "Adapters",
                    declaration: ".adapter(Self.definition)",
                    installer: defaultConstructionInstaller(
                        for: declaration,
                        expression: "{ sink in sink.install(Self()) }"
                    )
                ),
            ]
        }
    }
}

private enum AdapterMacroSpecification: DeclarationMacroSpecification {
    static let supportedKinds: Set<DeclarationMacroKind> = [.struct]
    static let conformance: String? = nil
    static func members(in _: DeclarationMacroContext) throws -> [DeclSyntax] { [] }
}

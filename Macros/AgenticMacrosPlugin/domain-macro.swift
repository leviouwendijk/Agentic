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
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let names = try DomainNames(attribute)
        return try DeclarationMacroEngine<
            DomainMacroSpecification
        >.members(
            of: declaration,
            macroName: "Domain",
            lexicalContext: context.lexicalContext
        ) { declarationContext in
            try DomainMacroSpecification.members(
                in: declarationContext,
                names: names
            )
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
            DomainMacroSpecification
        >.extensions(
            of: declaration,
            type: type,
            conformingTo: protocols,
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
        try members(in: context, names: .init())
    }

    static func members(
        in context: DeclarationMacroContext,
        names: DomainNames
    ) throws -> [DeclSyntax] {
        let access = semanticMemberAccessPrefix(context)
        let namespace = Case.convert(
            context.name,
            to: .snake
        )
        let name = names.primary.map { "try! DomainName(\"\($0)\")" } ?? "nil"
        let aliases = names.aliases.map { "try! DomainName(\"\($0)\")" }.joined(separator: ", ")

        return [
            DeclSyntax(
                stringLiteral:
                    "\(access)static let definition: DomainDefinition = .init(namespace: .init(rawValue: \"\(namespace)\"), name: \(name), aliases: [\(aliases)])"
            ),
            DeclSyntax(
                stringLiteral: "\(access)enum Agents {}"
            ),
            DeclSyntax(
                stringLiteral: "\(access)enum Instructions {}"
            ),
            DeclSyntax(
                stringLiteral: "\(access)enum Adapters {}"
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

/// `@Domain`'s arguments: `@Domain("swift", aliases: ["sbm", "swiftlang"])`.
/// The first string is the primary name; aliases are accepted only by the
/// runtime's `CapabilityResolver`. Without arguments the domain keeps its
/// authored capability identifiers (the transition to computed names).
/// Names are checked here; uniqueness across domains is checked when the
/// catalogs load, since a macro cannot see other declarations.
struct DomainNames {
    var primary: String?
    var aliases: [String] = []

    init() {}

    init(_ attribute: AttributeSyntax) throws {
        guard let arguments = attribute.arguments else {
            return
        }
        guard case .argumentList(let list) = arguments else {
            throw MacroExpansionErrorMessage(Self.usage)
        }
        for argument in list {
            switch argument.label?.text {
            case nil:
                guard primary == nil, let value = Self.literal(argument.expression) else {
                    throw MacroExpansionErrorMessage(Self.usage)
                }
                primary = value
            case "aliases":
                guard let array = argument.expression.as(ArrayExprSyntax.self) else {
                    throw MacroExpansionErrorMessage(Self.usage)
                }
                aliases = try array.elements.map { element in
                    guard let value = Self.literal(element.expression) else {
                        throw MacroExpansionErrorMessage(Self.usage)
                    }
                    return value
                }
            default:
                throw MacroExpansionErrorMessage(Self.usage)
            }
        }
        guard primary != nil || aliases.isEmpty else {
            throw MacroExpansionErrorMessage("@Domain aliases need a primary name first: @Domain(\"swift\", aliases: [\"sbm\"]).")
        }
        var seen: Set<String> = []
        for name in (primary.map { [$0] } ?? []) + aliases {
            guard Self.isDomainName(name) else {
                throw MacroExpansionErrorMessage(
                    "'\(name)' is not a domain name: lowercase letters and digits, starting with a letter, no underscore (it would not split back out of <domain>_<kind>_<name>)."
                )
            }
            guard seen.insert(name).inserted else {
                throw MacroExpansionErrorMessage("@Domain names '\(name)' twice.")
            }
        }
    }

    static let usage = "@Domain takes no arguments, or a primary name and optional aliases: @Domain(\"swift\", aliases: [\"sbm\", \"swiftlang\"])."

    private static func literal(_ expression: ExprSyntax) -> String? {
        guard let literal = expression.as(StringLiteralExprSyntax.self),
              literal.segments.count == 1,
              let segment = literal.segments.first?.as(StringSegmentSyntax.self)
        else {
            return nil
        }
        return segment.content.text
    }

    /// Mirrors `DomainName`: `[a-z][a-z0-9]*`.
    static func isDomainName(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first, ("a"..."z").contains(first) else {
            return false
        }
        return name.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) }
    }
}

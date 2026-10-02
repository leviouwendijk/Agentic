import Foundation
import SwiftParser
import SwiftSyntax

private enum SemanticKind:
    String,
    CaseIterable,
    Hashable
{
    case tool = "Tool"
    case program = "Program"
    case inference = "Inference"
    case agent = "Agent"

    var catalogCase: String {
        rawValue.lowercased()
    }
}

private struct SemanticMember:
    Hashable
{
    let domain: String
    let kind: SemanticKind
    let qualifiedName: String
}

private final class CatalogVisitor:
    SyntaxVisitor
{
    private(set) var domains: Set<String> = []
    private(set) var members: Set<SemanticMember> = []

    override func visit(
        _ node: EnumDeclSyntax
    ) -> SyntaxVisitorContinueKind {
        if hasAttribute(
            named: "Domain",
            in: node.attributes
        ) {
            domains.insert(
                node.name.text
            )
        }

        return .visitChildren
    }

    override func visit(
        _ node: ExtensionDeclSyntax
    ) -> SyntaxVisitorContinueKind {
        let extendedType =
            node.extendedType.trimmedDescription

        guard let scope = semanticScope(
            extendedType
        ) else {
            return .visitChildren
        }

        for member in node.memberBlock.members {
            guard let declaration = semanticDeclaration(
                member.decl
            ) else {
                continue
            }

            guard declaration.kind == scope.kind else {
                continue
            }

            members.insert(
                SemanticMember(
                    domain: scope.domain,
                    kind: declaration.kind,
                    qualifiedName:
                        extendedType
                        + "."
                        + declaration.name
                )
            )
        }

        return .visitChildren
    }

    private func semanticScope(
        _ extendedType: String
    ) -> (
        domain: String,
        kind: SemanticKind
    )? {
        let components = extendedType.split(
            separator: "."
        ).map(String.init)

        guard components.count >= 2,
              let namespace = components.last,
              let kind = SemanticKind.allCases.first(
                where: { candidate in
                    namespace == candidate.rawValue + "s"
                }
              ),
              let domain = components.first
        else {
            return nil
        }

        return (
            domain,
            kind
        )
    }

    private func semanticDeclaration(
        _ declaration: DeclSyntax
    ) -> (
        kind: SemanticKind,
        name: String
    )? {
        if let structure = declaration.as(
            StructDeclSyntax.self
        ) {
            return semanticDeclaration(
                name: structure.name.text,
                attributes: structure.attributes
            )
        }

        if let enumeration = declaration.as(
            EnumDeclSyntax.self
        ) {
            return semanticDeclaration(
                name: enumeration.name.text,
                attributes: enumeration.attributes
            )
        }

        return nil
    }

    private func semanticDeclaration(
        name: String,
        attributes: AttributeListSyntax
    ) -> (
        kind: SemanticKind,
        name: String
    )? {
        for kind in SemanticKind.allCases
        where hasAttribute(
            named: kind.rawValue,
            in: attributes
        ) {
            return (
                kind,
                name
            )
        }

        return nil
    }

    private func hasAttribute(
        named expected: String,
        in attributes: AttributeListSyntax
    ) -> Bool {
        attributes.contains { element in
            guard case .attribute(let attribute) = element else {
                return false
            }

            let name =
                attribute
                .attributeName
                .trimmedDescription
                .split(separator: ".")
                .last
                .map(String.init)

            return name == expected
        }
    }
}

private struct AgenticIndexer {
    let outputPath: String
    let sourcePaths: [String]

    func run() throws {
        let visitor = CatalogVisitor(
            viewMode: .sourceAccurate
        )

        for sourcePath in sourcePaths.sorted() {
            let data = try Data(
                contentsOf: URL(
                    fileURLWithPath: sourcePath
                )
            )
            let source = String(
                decoding: data,
                as: UTF8.self
            )

            visitor.walk(
                Parser.parse(
                    source: source
                )
            )
        }

        let output = render(
            domains: visitor.domains,
            members: visitor.members
        )

        let outputURL = URL(
            fileURLWithPath: outputPath
        )

        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try Data(
            output.utf8
        ).write(
            to: outputURL,
            options: .atomic
        )
    }

    private func render(
        domains: Set<String>,
        members: Set<SemanticMember>
    ) -> String {
        var lines: [String] = [
            "// Generated by AgenticIndexer. Do not edit.",
            "import Agentic",
            "",
        ]

        for domain in domains.sorted() {
            let domainMembers = members
                .filter { member in
                    member.domain == domain
                }
                .sorted { lhs, rhs in
                    if lhs.kind.rawValue != rhs.kind.rawValue {
                        return lhs.kind.rawValue < rhs.kind.rawValue
                    }

                    return lhs.qualifiedName < rhs.qualifiedName
                }

            lines.append(
                "public extension \(domain) {"
            )
            lines.append(
                "    static let catalog = Catalog("
            )
            lines.append(
                "        domains: [Self.definition],"
            )
            lines.append(
                "        declarations: ["
            )

            for member in domainMembers {
                lines.append(
                    "            .\(member.kind.catalogCase)(\(member.qualifiedName).definition),"
                )
            }

            lines.append(
                "        ]"
            )
            lines.append(
                "    )"
            )
            lines.append(
                "}"
            )
            lines.append(
                ""
            )
        }

        return lines.joined(
            separator: "\n"
        )
    }
}

@main
private enum Main {
    static func main() throws {
        let arguments = Array(
            CommandLine.arguments.dropFirst()
        )

        guard arguments.count >= 2 else {
            throw IndexerError.invalidArguments
        }

        try AgenticIndexer(
            outputPath: arguments[0],
            sourcePaths: Array(
                arguments.dropFirst()
            )
        ).run()
    }
}

private enum IndexerError:
    Error
{
    case invalidArguments
}

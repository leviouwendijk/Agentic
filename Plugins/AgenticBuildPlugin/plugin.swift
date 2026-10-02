import Foundation
import PackagePlugin

@main
struct AgenticBuildPlugin:
    BuildToolPlugin
{
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        let sourceFiles = sourceTarget
            .sourceFiles
            .filter { file in
                file.url.pathExtension == "swift"
            }
            .map(\.url)
            .sorted { lhs, rhs in
                lhs.path < rhs.path
            }

        guard !sourceFiles.isEmpty else {
            return []
        }

        let indexer = try context.tool(
            named: "AgenticIndexer"
        ).url
        let output = context
            .pluginWorkDirectoryURL
            .appending(
                path: "GeneratedSources"
            )
            .appending(
                path: "AgenticModuleCatalog.generated.swift"
            )

        return [
            .buildCommand(
                displayName:
                    "Generate Agentic semantic catalog for \(target.name)",
                executable: indexer,
                arguments:
                    [
                        output.path,
                    ]
                    + sourceFiles.map(\.path),
                inputFiles: sourceFiles,
                outputFiles: [
                    output,
                ]
            ),
        ]
    }
}

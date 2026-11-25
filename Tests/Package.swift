// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "AgenticTests",
    platforms: [
        .macOS(.v13),
    ],
    products: [

        // testing
        .executable(
            name: "t_agentic",
            targets: [
                "AgenticTesting",
            ]
        ),
        .executable(
            name: "t_agentic_context_window",
            targets: [
                "AgenticContextWindowTesting",
            ]
        ),
        .executable(
            name: "t_agentic_context",
            targets: [
                "AgenticContextTesting",
            ]
        ),
        .executable(
            name: "t_agentic_sensitivity",
            targets: [
                "AgenticSensitivityTests",
            ]
        ),
        .executable(
            name: "t_agentic_frame",
            targets: [
                "AgenticFrameTests",
            ]
        ),
        .executable(
            name: "t_agentic_math",
            targets: [
                "AgenticMathTesting",
            ]
        ),
        .executable(
            name: "t_agentic_assertions",
            targets: ["AgenticAssertionsTesting"]
        ),
        .executable(
            name: "t_agentic_structures",
            targets: ["AgenticStructuresTesting"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Primitives.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Schema.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Macros.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/leviouwendijk/Workspace.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/leviouwendijk/Difference.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/leviouwendijk/Errors.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Search.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/leviouwendijk/Testing.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Reporting.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/lco-langs/Frame.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Milieu.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/IO.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Writers.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Sensitivity.git",
            branch: "master"
        ),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "AgenticStructuresTesting",
            dependencies: [
                .product(name: "Agentic", package: "Agentic"),
                .product(name: "AgenticStandard", package: "Agentic"),
                .product(name: "Difference", package: "Difference"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Reporting", package: "Reporting"),
                .product(name: "Schema", package: "Schema"),
                .product(name: "Search", package: "Search"),
            ]
        ),
        .executableTarget(
            name: "AgenticFrameTests",
            dependencies: [
                .product(name: "Agentic", package: "Agentic"),
                .product(name: "AgenticFrame", package: "Agentic"),
                .product(name: "Frame", package: "Frame"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
        .executableTarget(
            name: "AgenticSensitivityTests",
            dependencies: [
                .product(name: "Agentic", package: "Agentic"),
                .product(name: "AgenticConfiguration", package: "Agentic"),
                .product(name: "AgenticSensitivity", package: "Agentic"),
                .product(name: "Macros", package: "Macros"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Schema", package: "Schema"),
                .product(name: "Sensitivity", package: "Sensitivity"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
        .executableTarget(
            name: "AgenticContextTesting",
            dependencies: [
                .product(name: "Agentic", package: "Agentic"),
                .product(name: "AgenticContext", package: "Agentic"),
                .product(name: "Errors", package: "Errors"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
        .executableTarget(
            name: "AgenticContextWindowTesting",
            dependencies: [
                .product(name: "Agentic", package: "Agentic"),
                .product(name: "AgenticContextWindow", package: "Agentic"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
        .executableTarget(
            name: "AgenticAssertionsTesting",
            dependencies: [
                .product(name: "Agentic", package: "Agentic"),
                .product(name: "AgenticAssertions", package: "Agentic"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
        .executableTarget(
            name: "AgenticMathTesting",
            dependencies: [
                .product(name: "AgenticMath", package: "Agentic"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
        .target(
            name: "AgenticLinkerCatalogFixture",
            dependencies: [
                .product(name: "Agentic", package: "Agentic"),
                .product(
                    name: "Macros",
                    package: "Macros"
                ),
                .product(
                    name: "Schema",
                    package: "Schema"
                ),
                .product(
                    name: "Workspace",
                    package: "Workspace"
                ),
            ]
        ),
        .executableTarget(
            name: "AgenticTesting",
            dependencies: [
                .product(name: "Agentic", package: "Agentic"),
                .product(name: "AgenticModels", package: "Agentic"),
                .product(name: "AgenticStandard", package: "Agentic"),
                .product(name: "AgenticTasks", package: "Agentic"),
                .product(name: "AgenticIntents", package: "Agentic"),
                .product(name: "AgenticHarness", package: "Agentic"),
                .product(name: "AgenticSessions", package: "Agentic"),
                "AgenticLinkerCatalogFixture",
                .product(
                    name: "Errors",
                    package: "Errors"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
                ),
                .product(
                    name: "Macros",
                    package: "Macros"
                ),
                .product(
                    name: "Schema",
                    package: "Schema"
                ),
                .product(
                    name: "Workspace",
                    package: "Workspace"
                ),
                .product(
                    name: "Milieu",
                    package: "Milieu"
                ),
                .product(
                    name: "IO",
                    package: "IO"
                ),
                .product(
                    name: "Writers",
                    package: "Writers"
                ),
                .product(
                    name: "Testing",
                    package: "Testing"
                ),
            ]
        ),
    ]
)

for target in package.targets {
    switch target.type {
    case .regular, .executable, .test, .macro:
        var settings = target.swiftSettings ?? []

        settings.append(
            .treatAllWarnings(as: .error)
        )

        settings.append(
            .unsafeFlags(
                [
                    "-continue-building-after-errors"
                ]
            )
        )

        target.swiftSettings = settings

    case .plugin, .system, .binary:
        break

    @unknown default:
        break
    }
}

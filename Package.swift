// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Agentic",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "Agentic",
            targets: [
                "Agentic",
            ]
        ),

        // available domains
        .library(
            name: "AgenticStandard",
            targets: [
                "AgenticStandard",
            ]
        ),
        .library(
            name: "AgenticHarness",
            targets: [
                "AgenticHarness",
            ]
        ),
        .library(
            name: "AgenticContextWindow",
            targets: [
                "AgenticContextWindow",
            ]
        ),

        // the home on disk: layout, settings.frame, domain files
        .library(
            name: "AgenticConfiguration",
            targets: [
                "AgenticConfiguration",
            ]
        ),
        // the Frame configuration language as tools: modules, schemas, checks
        .library(
            name: "AgenticFrame",
            targets: [
                "AgenticFrame",
            ]
        ),
        // what the owner tells agents about their world: context/*.frame
        .library(
            name: "AgenticContext",
            targets: [
                "AgenticContext",
            ]
        ),

        // sensitive values as handles: guard, vault, privacy_* tools
        .library(
            name: "AgenticSensitivity",
            targets: [
                "AgenticSensitivity",
            ]
        ),

        // session introspection: history, log, catalog, approvals, artifacts
        .library(
            name: "AgenticSessions",
            targets: [
                "AgenticSessions",
            ]
        ),

        // opt-in declarative assertions
        .library(
            name: "AgenticAssertions",
            targets: ["AgenticAssertions"]
        ),

        // opt-in deterministic calculations
        .library(
            name: "AgenticMath",
            targets: ["AgenticMath"]
        ),

        // opt-in durable task graph and typed assignments
        .library(
            name: "AgenticTasks",
            targets: ["AgenticTasks"]
        ),

        // known model library
        .library(
            name: "AgenticModels",
            targets: [
                "AgenticModels",
            ]
        ),

        // research bibliography
        .library(
            name: "AgenticReferences",
            targets: [
                "AgenticReferences",
            ]
        ),

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
            url: "https://github.com/leviouwendijk/Guidelines.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/GuidelinesSearch.git",
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
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: "603.0.0"
        ),

        .package(
            url: "https://github.com/leviouwendijk/Version.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Tokens.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Math.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Reporting.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Parsers.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/DSL.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/References.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Frame.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Path.git",
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
            url: "https://github.com/leviouwendijk/Readers.git",
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
    ],
    targets: [
        .target(
            name: "Agentic",
            dependencies: [
                .product(
                    name: "Guidelines",
                    package: "Guidelines"
                ),
                .product(
                    name: "Macros",
                    package: "Macros"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
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
                    name: "Difference",
                    package: "Difference"
                ),
                .product(
                    name: "Errors",
                    package: "Errors"
                ),
                .product(
                    name: "Reporting",
                    package: "Reporting"
                ),
                "AgenticLinkerSupport",
                "AgenticMacrosPlugin",
                .product(
                    name: "Version",
                    package: "Version"
                ),
            ]
        ),
        .target(
            name: "AgenticModels",
            dependencies: [
                "Agentic",
            ]
        ),
        .target(
            name: "AgenticReferences",
            dependencies: [
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "References", package: "References"),
            ]
        ),
        .target(
            name: "AgenticAssertions",
            dependencies: [
                "Agentic",
                .product(name: "Testing", package: "Testing"),
                .product(name: "Macros", package: "Macros"),
                .product(name: "Schema", package: "Schema"),
                .product(name: "Workspace", package: "Workspace"),
            ]
        ),
        .target(
            name: "AgenticMath",
            dependencies: [
                "Agentic",
                .product(name: "Math", package: "Math"),
                .product(name: "Macros", package: "Macros"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Schema", package: "Schema"),
            ]
        ),
        .target(
            name: "AgenticTasks",
            dependencies: [
                "Agentic",
                .product(name: "Macros", package: "Macros"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Schema", package: "Schema"),
            ]
        ),
        .target(
            name: "AgenticStandard",
            dependencies: [
                "Agentic",
                .product(name: "Math", package: "Math"),
                .product(name: "Milieu", package: "Milieu"),
                .product(name: "Reporting", package: "Reporting"),
                .product(name: "ParsersStructuredContent", package: "Parsers"),
                .product(name: "DSL", package: "DSL"),
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
                    name: "Guidelines",
                    package: "Guidelines"
                ),
                .product(
                    name: "GuidelinesSearch",
                    package: "GuidelinesSearch"
                ),
                .product(
                    name: "Search",
                    package: "Search"
                ),
            ]
        ),
        .executableTarget(
            name: "AgenticStructuresTesting",
            dependencies: [
                "Agentic",
                "AgenticStandard",
                .product(name: "Difference", package: "Difference"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Reporting", package: "Reporting"),
                .product(name: "Schema", package: "Schema"),
                .product(name: "Search", package: "Search"),
            ],
            path: "Testing/AgenticStructuresTesting"
        ),
        .target(
            name: "AgenticHarness",
            dependencies: [
                "Agentic",
                "AgenticConfiguration",
                "AgenticSessions",
                .product(name: "Frame", package: "Frame"),
                .product(name: "IO", package: "IO"),
                .product(name: "Readers", package: "Readers"),
                .product(name: "Writers", package: "Writers"),
                .product(
                    name: "Macros",
                    package: "Macros"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
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
        .target(
            name: "AgenticSessions",
            dependencies: [
                "Agentic",
                .product(name: "Macros", package: "Macros"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Schema", package: "Schema"),
            ]
        ),
        .target(
            name: "AgenticContextWindow",
            dependencies: [
                "Agentic",
                "AgenticSessions",
                .product(name: "Schema", package: "Schema"),
                .product(name: "Tokens", package: "Tokens"),
            ]
        ),
        .target(
            name: "AgenticConfiguration",
            dependencies: [
                .product(name: "Frame", package: "Frame"),
                .product(name: "IO", package: "IO"),
                .product(name: "Milieu", package: "Milieu"),
                .product(name: "Path", package: "Path"),
                .product(name: "Readers", package: "Readers"),
                .product(name: "Version", package: "Version"),
                .product(name: "Workspace", package: "Workspace"),
                .product(name: "Writers", package: "Writers"),
            ]
        ),
        .target(
            name: "AgenticFrame",
            dependencies: [
                "Agentic",
                .product(name: "Frame", package: "Frame"),
                .product(name: "Macros", package: "Macros"),
                .product(name: "Readers", package: "Readers"),
                .product(name: "Schema", package: "Schema"),
            ]
        ),
        .executableTarget(
            name: "AgenticFrameTests",
            dependencies: [
                "Agentic",
                "AgenticFrame",
                .product(name: "Frame", package: "Frame"),
                .product(name: "Testing", package: "Testing"),
            ],
            path: "Testing/AgenticFrameTests"
        ),
        .target(
            name: "AgenticContext",
            dependencies: [
                "Agentic",
                "AgenticConfiguration",
                "AgenticFrame",
                "AgenticStandard",
                .product(name: "Frame", package: "Frame"),
                .product(name: "IO", package: "IO"),
                .product(name: "Macros", package: "Macros"),
                .product(name: "Readers", package: "Readers"),
                .product(name: "Schema", package: "Schema"),
                .product(name: "Search", package: "Search"),
                .product(name: "Tokens", package: "Tokens"),
                .product(name: "Writers", package: "Writers"),
            ]
        ),
        .target(
            name: "AgenticSensitivity",
            dependencies: [
                "Agentic",
                "AgenticConfiguration",
                "AgenticStandard",
                .product(name: "Frame", package: "Frame"),
                .product(name: "IO", package: "IO"),
                .product(name: "Macros", package: "Macros"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Readers", package: "Readers"),
                .product(name: "Schema", package: "Schema"),
                .product(name: "Sensitivity", package: "Sensitivity"),
                .product(name: "Writers", package: "Writers"),
            ]
        ),
        .executableTarget(
            name: "AgenticSensitivityTests",
            dependencies: [
                "Agentic",
                "AgenticConfiguration",
                "AgenticSensitivity",
                .product(name: "Macros", package: "Macros"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Schema", package: "Schema"),
                .product(name: "Sensitivity", package: "Sensitivity"),
                .product(name: "Testing", package: "Testing"),
            ],
            path: "Testing/AgenticSensitivityTests"
        ),
        .executableTarget(
            name: "AgenticContextTesting",
            dependencies: [
                "Agentic",
                "AgenticContext",
                .product(name: "Testing", package: "Testing"),
            ],
            path: "Testing/AgenticContextTesting"
        ),
        .executableTarget(
            name: "AgenticContextWindowTesting",
            dependencies: [
                "Agentic",
                "AgenticContextWindow",
                .product(name: "Testing", package: "Testing"),
            ],
            path: "Testing/AgenticContextWindowTesting"
        ),
        .executableTarget(
            name: "AgenticAssertionsTesting",
            dependencies: [
                "Agentic",
                "AgenticAssertions",
                .product(name: "Testing", package: "Testing"),
            ],
            path: "Testing/AgenticAssertionsTesting"
        ),
        .executableTarget(
            name: "AgenticMathTesting",
            dependencies: [
                "AgenticMath",
                .product(name: "Testing", package: "Testing"),
            ],
            path: "Testing/AgenticMathTesting"
        ),
        .target(
            name: "AgenticLinkerCatalogFixture",
            dependencies: [
                "Agentic",
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
            ],
            path: "Testing/AgenticLinkerCatalogFixture"
        ),
        .executableTarget(
            name: "AgenticTesting",
            dependencies: [
                "Agentic",
                "AgenticModels",
                "AgenticStandard",
                "AgenticTasks",
                "AgenticHarness",
                "AgenticSessions",
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
            ],
            path: "Testing/AgenticTesting"
        ),
        .target(
            name: "AgenticLinkerSupport",
            path: "Support/AgenticLinkerSupport",
            publicHeadersPath: "include"
        ),
        .macro(
            name: "AgenticMacrosPlugin",
            dependencies: [
                .product(
                    name: "MacroEngine",
                    package: "Macros"
                ),
                .product(
                    name: "Primitives",
                    package: "Primitives"
                ),
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftSyntax",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftSyntaxBuilder",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftSyntaxMacros",
                    package: "swift-syntax"
                ),
            ],
            path: "Macros/AgenticMacrosPlugin"
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

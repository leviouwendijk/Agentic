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

        // opt-in deferred tool calls: stored for review, run later
        .library(
            name: "AgenticIntents",
            targets: ["AgenticIntents"]
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
        .library(name: "AgenticAssertions", targets: ["AgenticAssertions"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-lco/Primitives.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Schema.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Macros.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Surface.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/swift-tooling/Guidelines.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-tooling/GuidelinesSearch.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/swift-lco/Workspace.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/swift-lco/Difference.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/swift-lco/Errors.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Search.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Matching.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: "603.0.0"
        ),

        .package(
            url: "https://github.com/swift-lco/Version.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-langs/Tokens.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Math.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Reporting.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-langs/Parsers.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-dsl/DSL.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/References.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/lco-langs/Frame.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Path.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Milieu.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/IO.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Readers.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Writers.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Sensitivity.git",
            branch: "master"
        ),
        .package(url: "https://github.com/swift-tooling/Testing.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Agentic",
            dependencies: [
                .product(
                    name: "Surface",
                    package: "Surface"
                ),
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
            name: "AgenticIntents",
            dependencies: [
                "Agentic",
                .product(name: "IO", package: "IO"),
                .product(name: "Macros", package: "Macros"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Readers", package: "Readers"),
                .product(name: "Schema", package: "Schema"),
                .product(name: "Writers", package: "Writers"),
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
                .product(name: "Surface", package: "Surface"),
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
                .product(
                    name: "Matching",
                    package: "Matching"
                ),
            ]
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
        .target(
            name: "AgenticContext",
            dependencies: [
                "Agentic",
                "AgenticConfiguration",
                "AgenticFrame",
                "AgenticStandard",
                .product(name: "Errors", package: "Errors"),
                .product(name: "Frame", package: "Frame"),
                .product(name: "IO", package: "IO"),
                .product(name: "Macros", package: "Macros"),
                .product(name: "Readers", package: "Readers"),
                .product(name: "Roots", package: "Frame"),
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

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
            name: "AgenticContext",
            targets: [
                "AgenticContext",
            ]
        ),

        // known model library 
        .library(
            name: "AgenticModels",
            targets: [
                "AgenticModels",
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
            name: "t_agentic_ctx",
            targets: [
                "AgenticContextTesting",
            ]
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
            name: "AgenticStandard",
            dependencies: [
                "Agentic",
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
        .target(
            name: "AgenticHarness",
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
            ]
        ),
        .target(
            name: "AgenticContext",
            dependencies: [
                "Agentic",
                .product(name: "Tokens", package: "Tokens"),
            ]
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
                "AgenticHarness",
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

// swift-tools-version: 6.2

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
        .executable(
            name: "agentictest",
            targets: [
                "AgenticTest",
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
            url: "https://github.com/leviouwendijk/Workspace.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/leviouwendijk/Difference.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/leviouwendijk/AgenticRecovery.git",
            branch: "master"
        ),

        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: "603.0.0"
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
                    name: "AgenticRecovery",
                    package: "AgenticRecovery"
                ),
                "AgenticMacrosPlugin",
            ]
        ),
        .executableTarget(
            name: "AgenticTest",
            dependencies: [
                "Agentic",
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
            ]
        ),
    ]
)

// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Agentic",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Agentic",
            targets: ["Agentic"]
        ),

        .executable(
            name: "agtest",
            targets: ["AgenticTestFlows"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Primitives.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Writers.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Readers.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Path.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/FileTypes.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Selection.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Concatenation.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Interfaces.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Tokens.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Matching.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Ranking.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Fuzzy.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Milieu.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Difference.git", branch: "master"),

        // .package(url: "https://github.com/leviouwendijk/ANSI.git", branch: "master"),
        // .package(url: "https://github.com/leviouwendijk/Terminal.git", branch: "master"),

        .package(url: "https://github.com/leviouwendijk/TestFlows.git", branch: "master"),

        // .package(url: "https://github.com/leviouwendijk/Executable.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Agentic",
            dependencies: [
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Writers", package: "Writers"),
                .product(name: "Readers", package: "Readers"),
                .product(name: "FileTypes", package: "FileTypes"),
                .product(name: "Path", package: "Path"),
                .product(name: "PathParsing", package: "Path"),
                .product(name: "Selection", package: "Selection"),
                .product(name: "SelectionParsing", package: "Selection"),
                .product(name: "Concatenation", package: "Concatenation"),
                .product(name: "Interfaces", package: "Interfaces"),
                .product(name: "Tokens", package: "Tokens"),
                .product(name: "Matching", package: "Matching"),
                .product(name: "Ranking", package: "Ranking"),
                .product(name: "Fuzzy", package: "Fuzzy"),
                .product(name: "Milieu", package: "Milieu"),
                .product(name: "Difference", package: "Difference"),

                // .product(name: "Executable", package: "Executable"),
            ],
        ),
        .executableTarget(
            name: "AgenticTestFlows",
            dependencies: [
                "Agentic",
                .product(name: "TestFlows", package: "TestFlows"),
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Writers", package: "Writers"),
                // .product(name: "ANSI", package: "ANSI"),
                // .product(name: "Terminal", package: "Terminal"),
            ]
        ),
    ]
)

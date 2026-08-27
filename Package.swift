// swift-tools-version: 6.2

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
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Guidelines.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Primitives.git",
            branch: "master"
        ),
        // .package(
        //     url: "https://github.com/leviouwendijk/Path.git",
        //     branch: "master"
        // ),
        // .package(
        //     url: "https://github.com/leviouwendijk/Tokens.git",
        //     branch: "master"
        // ),
        // .package(
        //     url: "https://github.com/leviouwendijk/Matching.git",
        //     branch: "master"
        // ),
        // .package(
        //     url: "https://github.com/leviouwendijk/Ranking.git",
        //     branch: "master"
        // ),
        // .package(
        //     url: "https://github.com/leviouwendijk/Fuzzy.git",
        //     branch: "master"
        // ),
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
                    name: "Primitives",
                    package: "Primitives"
                ),
                // .product(
                //     name: "Path",
                //     package: "Path"
                // ),
                // .product(
                //     name: "Tokens",
                //     package: "Tokens"
                // ),
                // .product(
                //     name: "Matching",
                //     package: "Matching"
                // ),
                // .product(
                //     name: "Ranking",
                //     package: "Ranking"
                // ),
                // .product(
                //     name: "Fuzzy",
                //     package: "Fuzzy"
                // ),
            ]
        ),
    ]
)

// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "AgenticBenchmarks",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "b_agentic",
            targets: ["AgenticBenchmarksCLI"]
        ),
    ],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .target(
            name: "AgenticBenchmarks",
            dependencies: [
                .product(name: "Agentic", package: "Agentic"),
                .product(name: "AgenticContextWindow", package: "Agentic"),
            ]
        ),
        .executableTarget(
            name: "AgenticBenchmarksCLI",
            dependencies: [
                "AgenticBenchmarks",
                .product(name: "Agentic", package: "Agentic"),
                .product(name: "AgenticContextWindow", package: "Agentic"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
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

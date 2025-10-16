// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MacMLBenchmark",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "macmlbench",
            targets: ["MacMLBench"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "MacMLBench",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "src"
        ),
        .testTarget(
            name: "MacMLBenchTests",
            dependencies: ["MacMLBench"],
            path: "tests"
        )
    ]
)

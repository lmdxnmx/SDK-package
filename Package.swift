// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "IoMT.SDK",
    products: [
        .library(
            name: "IoMT.SDK",
            targets: ["IoMT.SDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "Decoder",
            path: "Sources/Decoder",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("USE_DECODER")
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedLibrary("LMTPDecoder"),
            ]
        ),
        .target(
            name: "IoMT.SDK",
            dependencies: [
                .product(name: "Reachability", package: "Reachability.swift"),
                "Decoder"
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)

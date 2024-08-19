// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IoMT.SDK",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "IoMT.SDK",
            targets: ["IoMT.SDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name:"Decoder",
            publicHeadersPath: "include"
        ),
        .target(
            name: "IoMT.SDK",
            dependencies: [.product(name: "Reachability", package: "Reachability.swift"),"Decoder"]
            
        ),
  
    ]
)

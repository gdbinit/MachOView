// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MachOView",
    platforms: [
      .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MachOView",
            targets: ["MachOView"]),
    ],
    dependencies: [
      .package(path: "../FileHandleExt"),
      .package(url: "https://github.com/apple/swift-atomics.git", .upToNextMajor(from: "1.1.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MachOView",
            dependencies: ["FileHandleExt"]),
        .testTarget(
            name: "MachOViewTests",
            dependencies: ["MachOView"]),
    ]
)

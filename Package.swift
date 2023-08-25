// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ControlCenter",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(url: "https://github.com/vapor/mysql-kit.git", .upToNextMajor(from: "4.7.1")),
        .package(url: "https://github.com/sushichop/Puppy.git", .upToNextMajor(from: "0.7.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.5.3")),
        .package(url: "https://github.com/grpc/grpc-swift.git", .upToNextMajor(from: "1.19.1")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.3")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "ControlCenter",
            dependencies: [
                .product(name: "MySQLKit", package: "mysql-kit"),
                .product(name: "Puppy", package: "Puppy"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources"
        ),
    ]
)

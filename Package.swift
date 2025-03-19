// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "NetworkManager",
    platforms: [.macOS(.v10_15), .iOS(.v12), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "NetworkManager",
            targets: ["NetworkManager"]
        ),
        .executable(
            name: "NetworkManagerClient",
            targets: ["NetworkManagerClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.7.0"),
    ],
    targets: [
        .macro(
            name: "NetworkManagerMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "AlamofileClient",
            dependencies: [
                "NetworkManager",
                .product(name: "Alamofire", package: "Alamofire")
            ]
        ),
        .target(name: "NetworkManager", dependencies: ["NetworkManagerMacros"]),
        .executableTarget(
            name: "NetworkManagerClient",
            dependencies: [
                "NetworkManager",
                "AlamofileClient"
            ]
        ),
        .testTarget(
            name: "NetworkManagerTests",
            dependencies: [
                "NetworkManagerMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)

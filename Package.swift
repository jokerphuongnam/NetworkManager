// swift-tools-version: 6.0
 // The swift-tools-version declares the minimum version of Swift required to build this package.
 
 import PackageDescription
 import CompilerPluginSupport
 
 let package = Package(
     name: "NetworkManager",
     platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
     ],
     products: [
         .library(
             name: "NetworkManager",
             targets: [
                "NetworkManager",
                "SharedModels"
             ]
         ),
     ],
     dependencies: [
         .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
     ],
     targets: [
         .macro(
             name: "NetworkManagerMacros",
             dependencies: [
                "SharedModels",
                 .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                 .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
             ]
         ),
         .target(
            name: "NetworkManager",
            dependencies: [
                "NetworkManagerMacros",
                "SharedModels",
            ]
         ),
         .target(name: "SharedModels", dependencies: []),
         .executableTarget(
             name: "NetworkManagerClient",
             dependencies: [
                 "NetworkManager",
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

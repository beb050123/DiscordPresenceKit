// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DiscordPresenceKit",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "DiscordPresenceKit",
            type: .static,
            targets: ["DiscordPresenceKit"]
        )
    ],
    targets: [
        // Discord SDK as a binary target
        .binaryTarget(
            name: "DiscordSDK",
            path: "DiscordSDK/discord_sdk.xcframework"
        ),
        // C++ Bridge Target
        .target(
            name: "DiscordCXXBridge",
            dependencies: ["DiscordSDK"],
            path: "Sources/DiscordCXXBridge",
            exclude: [],
            sources: ["DiscordSDKBridge.mm"],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("../.build/checkouts/DiscordSDK-xcframework/macos-arm64_x86_64/Headers"),
                .define("DISCORDCORD_OSX", to: "1"),
                .unsafeFlags(["-fno-exceptions", "-fno-rtti", "-std=c++17"])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath", "-Xlinker", "@loader_path/../Frameworks",
                    "-framework", "CoreFoundation",
                    "-framework", "Foundation"
                ])
            ]
        ),
        // Swift Target
        .target(
            name: "DiscordPresenceKit",
            dependencies: ["DiscordCXXBridge"],
            path: "Sources/DiscordPresenceKit",
            exclude: ["Internal/SDKBindings/README.md"],
            sources: [
                ".",
                "Models",
                "Internal"
            ]
        ),
        .testTarget(
            name: "DiscordPresenceKitTests",
            dependencies: ["DiscordPresenceKit"],
            path: "Tests/DiscordPresenceKitTests"
        )
    ]
)

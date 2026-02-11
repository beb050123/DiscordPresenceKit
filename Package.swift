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
    dependencies: [],
    targets: [
        // C++ Bridge Target
        .target(
            name: "DiscordCXXBridge",
            path: "Sources/DiscordCXXBridge",
            exclude: [],
            sources: ["DiscordSDKBridge.mm"],
            publicHeadersPath: ".",
            cxxSettings: [
                .headerSearchPath("../../DiscordSDK/include"),
                .define("DISCORDCORD_OSX", to: "1"),
                .unsafeFlags(["-fno-exceptions", "-fno-rtti", "-std=c++17"])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-L../../DiscordSDK/lib/release",
                    "-ldiscord_partner_sdk",
                    "-Xlinker", "-rpath", "-Xlinker", "../../DiscordSDK/lib/release",
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
            path: "Tests/DiscordPresenceKitTests",
            linkerSettings: [
                .unsafeFlags([
                    "-LDiscordSDK/lib/release",
                    "-ldiscord_partner_sdk",
                    "-Xlinker", "-rpath", "-Xlinker", "DiscordSDK/lib/release",
                    "-framework", "CoreFoundation",
                    "-framework", "Foundation"
                ])
            ]
        )
    ]
)

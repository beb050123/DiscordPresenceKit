# DiscordPresenceKit

A Swift-first, macOS-only wrapper around the Discord Social SDK focused exclusively on Rich Presence.

## Overview

DiscordPresenceKit provides a clean, Swift-native API for setting Discord Rich Presence from macOS applications. It communicates with the local Discord desktop client over IPC.

## Requirements

- macOS 12.0+
- Swift 5.9+
- Discord desktop client must be installed and running

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/DiscordPresenceKit.git", from: "0.1.0")
]
```

## Quick Start

```swift
import DiscordPresenceKit

// Initialize with your Discord application ID
let client = try DiscordClientImpl(applicationID: "123456789012345678")

// Set up a timer to call tick() regularly (every 1-2 seconds)
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    Task {
        try await client.tick()
    }
}

// Update presence
let presence = RichPresence(
    details: "In a match",
    state: "Ranked – Solo Queue",
    type: .competing
)
try await client.update(presence: presence)

// Clean up on exit
await client.shutdown()
```

## Features

- **Swift-first API** - No C/C++ types in the public interface
- **Type-safe** - Structs and enums for all presence fields
- **Rate limiting** - Built-in enforcement of Discord's 15-second limit
- **Testable** - Protocol-based design with full mocking support
- **No global state** - Explicit lifecycle control
- **No hidden concurrency** - Work happens when you call it

## Rich Presence Fields

- `details` - Primary activity description
- `state` - Secondary status
- `timestamps` - Elapsed or remaining time
- `assets` - Images and hover text
- `buttons` - Up to 2 clickable buttons
- `type` - Playing, Listening, Watching, or Competing
- `name` - Application name override

## Documentation

See [CLAUDE.md](./CLAUDE.md) for detailed contributor guidelines and project philosophy.

## License

MIT License. See LICENSE file for details.

The Discord Social SDK retains its original Discord license and is not relicensed by this project.

## Discord SDK

Download the Discord Social SDK from:
https://discord.com/developers/docs/social-sdk

Place SDK files in the `DiscordSDK/` directory:
- Headers in `DiscordSDK/include/`
- Libraries in `DiscordSDK/lib/`
# DiscordPresenceKit

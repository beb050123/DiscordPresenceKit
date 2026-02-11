# DiscordPresenceKit

A Swift-first Discord Rich Presence library for macOS.

## ⚠️ Important Notes

- **Initialization**: Use `DefaultDiscordClient(applicationID: "YOUR_ID")` — not `DiscordClient()`
- **Async/await**: All methods are `async` — use `Task { await client.update(...) }`
- **Tick required**: Call `await client.tick()` every 1-2 seconds for IPC to work
- **Discord must be running**: The library communicates with the local Discord desktop app over IPC

## Features

- **Type-safe Swift API** - No raw Discord SDK types leak through
- **Automatic rate limiting** - 15-second minimum enforced automatically
- **Simple lifecycle** - Initialize, update, tick, shutdown
- **Full Rich Presence support** - Details, state, timestamps, assets, buttons, activity types
- **Crash-safe** - Handles Discord SDK edge cases gracefully

## Requirements

- macOS 12.0+
- Xcode 15.0+ or Swift 5.9+
- Discord desktop app running locally

## Installation

### Swift Package Manager

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/beb050123/DiscordPresenceKit.git", from: "1.0.0")
]
```

### In Xcode

1. File → Add Package Dependencies
2. Enter: `https://github.com/beb050123/DiscordPresenceKit.git`

## Discord Application Setup

Before using this library, set up a Discord application:

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application
3. Copy your **Application ID** (you'll need this in your code)
4. Go to **Rich Presence** → **Art Assets**
5. Upload images (these will be referenced by `largeImage`/`smallImage` keys)

## Quick Start

```swift
import DiscordPresenceKit

@MainActor
class PresenceManager: ObservableObject {
    private let client: DiscordClient
    private var timer: Timer?

    init() {
        // Replace with your Discord Application ID
        guard let client = try? DefaultDiscordClient(applicationID: "YOUR_APP_ID") else {
            fatalError("Failed to initialize Discord client")
        }
        self.client = client
    }

    func start() {
        startTickTimer()
        updatePresence()
    }

    func updatePresence() {
        Task {
            try? await client.update(presence: RichPresence(
                details: "Playing Awesome Game",
                state: "Level 42",
                assets: PresenceAssets(
                    largeImage: "logo",
                    largeText: "Awesome Game"
                ),
                timestamps: .elapsed(since: Date()),
                type: .playing
            ))
        }
    }

    private func startTickTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { [weak self] in
                try? await self?.client.tick()
            }
        }
    }

    deinit {
        timer?.invalidate()
        Task { await client.shutdown() }
    }
}
```

## Usage Examples

### Setting Presence

```swift
Task {
    try? await client.update(presence: RichPresence(
        details: "In a match",
        state: "Ranked - Solo Queue",
        timestamps: .elapsed(since: Date()),
        assets: PresenceAssets(
            largeImage: "map_logo",
            largeText: "Summoner's Rift",
            smallImage: "champion_icon",
            smallText: "Yasuo"
        ),
        buttons: [
            PresenceButton(label: "View Profile", url: "https://example.com")
        ],
        type: .playing
    ))
}
```

### Activity Types

```swift
type: .playing      // "Playing ..."
type: .listening   // "Listening to ..."
type: .watching    // "Watching ..."
type: .competing   // "Competing in ..."
```

### Timestamps

```swift
// Elapsed time (shows "00:00 elapsed")
timestamps: .elapsed(since: Date())

// Remaining time (shows "15:00 left")
timestamps: .remaining(until: Date().addingTimeInterval(900))
```

### Clearing Presence

```swift
Task {
    try? await client.update(presence: .clear)
}
```

### Error Handling

```swift
do {
    let client: DiscordClient = try DefaultDiscordClient(applicationID: "YOUR_APP_ID")
    try await client.update(presence: presence)
    try await client.tick()
} catch DiscordError.invalidApplicationID {
    print("Invalid app ID")
} catch DiscordError.rateLimitExceeded(let seconds) {
    print("Wait \(seconds) seconds")
} catch {
    print("Error: \(error)")
}
```

## SwiftUI Example

```swift
import SwiftUI
import DiscordPresenceKit

@main
struct MyApp: App {
    @StateObject private var presence = DiscordPresenceManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onAppear {
            presence.start()
        }
    }
}

@MainActor
class DiscordPresenceManager: ObservableObject {
    private let client: DiscordClient
    private var timer: Timer?

    init() {
        guard let client = try? DefaultDiscordClient(applicationID: "YOUR_APP_ID") else {
            fatalError("Failed to initialize Discord client")
        }
        self.client = client
    }

    func start() {
        startTickTimer()
        updatePresence("In Menu", state: nil)
    }

    func updatePresence(_ details: String, state: String?) {
        Task {
            try? await client.update(presence: RichPresence(
                details: details,
                state: state,
                assets: PresenceAssets(largeImage: "app_icon"),
                timestamps: .elapsed(since: Date()),
                type: .playing
            ))
        }
    }

    private func startTickTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { [weak self] in
                try? await self?.client.tick()
            }
        }
    }
}
```

## Verifying It Works

1. Open Discord and go to **User Settings** → **Activity Privacy**
2. Ensure **"Display current activity as a status message"** is ON
3. Run your app
4. Look at your Discord profile (bottom-left corner) — you should see your presence
5. You can also check in a DM or ask a friend to view your profile

## License

MIT

## Acknowledgments

Built with the [Discord Social SDK](https://discord.com/developers/docs/rich-presence/getting-started).

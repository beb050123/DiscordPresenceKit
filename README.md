# DiscordPresenceKit

A Swift-first Discord Rich Presence library for macOS.

## ⚠️ Important Notes

- **Initialization**: Use `DefaultDiscordClient(applicationID: "YOUR_ID")` — not `DiscordClient()`
- **Async/await**: All methods are `async` — use `Task { await client.update(...) }`
- **Tick required**: Call `await client.tick()` every 1-2 seconds for IPC to work

## Features

- **Type-safe Swift API** - No raw Discord SDK types leak through
- **Automatic rate limiting** - 15-second minimum enforced automatically
- **Simple lifecycle** - Initialize, update, tick, shutdown
- **Full Rich Presence support** - Details, state, timestamps, assets, buttons, activity types

## Requirements

- macOS 12.0+
- Xcode 15.0+ or Swift 5.9+
- Discord desktop app running locally

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/beb050123/DiscordPresenceKit.git", from: "1.0.0")
]
```

### In Xcode

1. File → Add Package Dependencies
2. Enter: `https://github.com/beb050123/DiscordPresenceKit.git`

## Discord SDK Setup

Before using this library, you need to download the Discord SDK:

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application
3. Navigate to **Rich Presence** → **Social SDK**
4. Download the macOS SDK
5. Extract it into the `DiscordSDK/` directory

See `DiscordSDK/README.md` for detailed instructions.

## Quick Start

```swift
import DiscordPresenceKit

class PresenceManager {
    private let client: DiscordClient
    private var timer: Timer?

    init() throws {
        // Initialize with your Discord Application ID
        self.client = try DefaultDiscordClient(applicationID: "1234567890123456789")
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

## Usage

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
presence.type = .playing      // "Playing ..."
presence.type = .listening   // "Listening to ..."
presence.type = .watching    // "Watching ..."
presence.type = .competing   // "Competing in ..."
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

## Discord Application Setup

1. Create an application at [Discord Developers](https://discord.com/developers/applications)
2. Copy your **Application ID**
3. Go to **Rich Presence** → **Art Assets**
4. Upload images (these will be referenced by `largeImage`/`smallImage` keys)

## Important Notes

- **Discord must be running** - The library communicates with the local Discord client over IPC
- **Call `tick()` regularly** - Every 1-2 seconds (use a Timer or DispatchQueue)
- **Rate limiting** - Updates are rate-limited to once per 15 seconds (enforced automatically)
- **Clean shutdown** - Call `shutdown()` when your app exits

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
        // Replace with your actual Discord Application ID
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

## License

MIT

## Acknowledgments

Built with the [Discord Social SDK](https://discord.com/developers/docs/rich-presence/getting-started).

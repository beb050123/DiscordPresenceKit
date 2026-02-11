# DiscordPresenceKit

A Swift-first Discord Rich Presence library for macOS.

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
    private let client = DiscordClient()
    private var timer: Timer?

    func start() {
        // Initialize with your Discord Application ID
        switch client.initialize(applicationID: "1234567890123456789") {
        case .success:
            startTickTimer()
            updatePresence()
        case .failure(let error):
            print("Failed to initialize: \(error)")
        }
    }

    func updatePresence() {
        let presence = RichPresence(
            details: "Playing Awesome Game",
            state: "Level 42",
            assets: PresenceAssets(
                largeImage: "logo",
                largeText: "Awesome Game"
            ),
            timestamps: .start(Date()),
            type: .playing
        )
        client.update(presence)
    }

    private func startTickTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.client.tick()
        }
    }

    deinit {
        timer?.invalidate()
        client.shutdown()
    }
}
```

## Usage

### Setting Presence

```swift
let presence = RichPresence(
    details: "In a match",
    state: "Ranked - Solo Queue",
    assets: PresenceAssets(
        largeImage: "map_logo",
        largeText: "Summoner's Rift",
        smallImage: "champion_icon",
        smallText: "Yasuo"
    ),
    timestamps: .start(Date()),
    buttons: [
        PresenceButton(label: "View Profile", url: "https://example.com")
    ],
    type: .playing
)

client.update(presence)
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
.timestamps(.start(Date()))

// Remaining time (shows "15:00 left")
.timestamps(.end(Date().addingTimeInterval(900)))
```

### Clearing Presence

```swift
client.clearPresence()
```

### Error Handling

```swift
switch client.initialize(applicationID: appID) {
case .success:
    print("Initialized!")
case .failure(.invalidApplicationID):
    print("Invalid app ID")
case .failure(.rateLimited(let seconds)):
    print("Wait \(seconds) seconds")
case .failure(let error):
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

class DiscordPresenceManager: ObservableObject {
    private let client = DiscordClient()
    private var timer: Timer?

    func start() {
        _ = client.initialize(applicationID: "YOUR_APP_ID")
        startTickTimer()
        updatePresence("In Menu", state: nil)
    }

    func updatePresence(_ details: String, state: String?) {
        client.update(RichPresence(
            details: details,
            state: state,
            assets: PresenceAssets(largeImage: "app_icon"),
            timestamps: .start(Date()),
            type: .playing
        ))
    }

    private func startTickTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.client.tick()
        }
    }
}
```

## License

MIT

## Acknowledgments

Built with the [Discord Social SDK](https://discord.com/developers/docs/rich-presence/getting-started).

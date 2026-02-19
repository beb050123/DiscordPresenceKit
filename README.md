# DiscordPresenceKit

A Swift-first Discord Rich Presence library for macOS.

## Features

- **Fire-and-forget API** - Just call `update()` - no manual tick management
- **Automatic heartbeat** - SDK callbacks handled internally on a background thread
- **Automatic rate limiting** - 15-second minimum between updates, queued automatically
- **Type-safe Swift API** - No raw Discord SDK types leak through
- **Full Rich Presence support** - Details, state, timestamps, assets, buttons, activity types
- **Crash-safe** - Handles Discord SDK edge cases gracefully

## Requirements

- macOS 12.0+
- Xcode 15.0+ or Swift 5.9+
- Discord desktop app running locally
- **Apple Developer account** required for distribution (codesigning)

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

### Verifying It Works

1. Open Discord and go to **User Settings** → **Activity Privacy**
2. Ensure **"Display current activity as a status message"** is ON
3. Run your app
4. Look at your Discord profile (bottom-left corner) — you should see your presence

## Quick Start

```swift
import DiscordPresenceKit

@MainActor
class PresenceManager: ObservableObject {
    private let client: DiscordClient

    init() {
        // Replace with your Discord Application ID
        guard let client = try? DefaultDiscordClient(applicationID: "YOUR_APP_ID") else {
            fatalError("Failed to initialize Discord client")
        }
        self.client = client
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

    deinit {
        Task { await client.shutdown() }
    }
}
```

That's it! The library handles:
- **Heartbeat/tick** - Called automatically on a background thread
- **Rate limiting** - Updates faster than 15 seconds are queued and sent when allowed

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
} catch DiscordError.invalidApplicationID {
    print("Invalid app ID")
} catch DiscordError.clientUnavailable {
    print("Discord is not running")
} catch {
    print("Error: \(error)")
}
```

## Troubleshooting

### Code Signing Issues During Archive

The bundled Discord SDK dylib is now signed with an ad-hoc signature, allowing it to be properly re-signed during your app's archive process. If you still encounter code signing hangs when building with hardened runtime (required for notarized macOS app distribution), add a Run Script build phase:

1. In Xcode, select your target → Build Phases → + → New Run Script Phase
2. Position it **before** the "Embed Frameworks" phase
3. Add this script:

```bash
DISCORD_DYLIB="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/Frameworks/libdiscord_partner_sdk.dylib"

if [ -f "$DISCORD_DYLIB" ]; then
    codesign --remove-signature "$DISCORD_DYLIB" 2>/dev/null || true
    codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
        --options runtime \
        --timestamp \
        "$DISCORD_DYLIB"
fi
```

### Discord Not Showing Presence

1. Ensure Discord desktop app is running (not just the web version)
2. Check **User Settings** → **Activity Privacy** → **"Display current activity as a status message"** is enabled
3. Verify your Application ID is correct

### Build Errors

- **"No such module 'DiscordPresenceKit'"**: Clean build folder (Cmd+Shift+K) and rebuild
- **Linker errors**: Ensure you're building for macOS 12.0+

## License

MIT

## Acknowledgments

Built with the [Discord Social SDK](https://discord.com/developers/docs/rich-presence/getting-started).

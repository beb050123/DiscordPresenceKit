# Discord SDK Setup

This directory should contain the Discord Social SDK. The SDK is not included in this repository due to its size and licensing terms.

## How to Download

1. Go to https://discord.com/developers/applications
2. Create a new application (or use an existing one)
3. Navigate to **Rich Presence** → **Social SDK**
4. Download the macOS SDK

## Extract Here

Extract the downloaded SDK directly into this `DiscordSDK/` directory. The structure should look like:

```
DiscordSDK/
├── include/
│   └── cdiscord.h
└── lib/
    ├── release/
    │   ├── discord_partner_sdk.xcframework
    │   └── libdiscord_partner_sdk.dylib
    └── debug/
        └── ...
```

## Verify

After extraction, you should have:
- `DiscordSDK/include/cdiscord.h`
- `DiscordSDK/lib/release/libdiscord_partner_sdk.dylib`

Then build the project normally:
```bash
swift build
```

## Note for Tests

When running tests, you may need to create a symlink:
```bash
ln -s "$(pwd)/DiscordSDK" .build/DiscordSDK
```

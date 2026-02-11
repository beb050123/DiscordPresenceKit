# DiscordPresenceKit – Contributor Guide

## What This Project Is

DiscordPresenceKit is a **Swift-first, macOS-only wrapper** around the **Discord Social SDK**, focused exclusively on **Rich Presence**. It exists to make Discord Rich Presence easy to use from Swift, safe to embed in production macOS apps, and maintainable over time.

This is not a full Discord SDK wrapper and never will be. The scope is narrow by design.

---

## SDK Choice

This project wraps the **Discord Social SDK** — not the legacy Game SDK, which Discord has marked deprecated and no longer recommends for new development. The Game SDK docs are preserved only for reference; the Social SDK is Discord's current supported path.

The Social SDK uses a C++ namespace (`discordpp::`) and exposes Rich Presence via `Client::UpdateRichPresence`. Only that surface area is relevant to this project. Features added in Social SDK releases — including newer activity types (`Competing`, `Listening`, `Watching` added in v1.5), clickable URL fields, and invite cover images (added in v1.6) — may be considered for inclusion if they fall within Rich Presence scope. Features outside that scope — lobbies, voice, DMs, linked channels — will not be wrapped.

Any contribution based on the Game SDK will be rejected without review.

---

## Supported Platforms

**Supported:**
- macOS 12+  
- Swift 5.9+  
- Discord Desktop client must be installed and running locally

**Not supported:**
- iOS / iPadOS  
- Linux / Windows  
- Headless or web-only environments

The library communicates with the Discord desktop client over local IPC. There is no fallback path if the client is absent.

---

## Rich Presence Scope

The following fields map to the Social SDK's `Activity` object and are in scope:

| Field | Description |
|---|---|
| `details` | Primary activity description (e.g. "In a match") |
| `state` | Secondary status (e.g. "Ranked – Solo Queue") |
| `timestamps` | `startTimestamp` shows elapsed time; `endTimestamp` shows remaining time. Only one should be set at a time. |
| `assets` | Large image, small image, hover text, and (SDK v1.6+) `inviteCoverImage` |
| `buttons` | Up to 2 buttons. Discord enforces this maximum. |
| `type` | Activity type: Playing, Listening, Watching, Competing (SDK v1.5+) |
| `name` | Overrides the application name shown in presence (SDK v1.6+) |
| Clearing | Setting an empty activity removes presence entirely |

**Out of scope — will not be accepted:**
- Friends list / relationships
- Game invites and join secrets
- Lobbies and party management
- Voice and audio
- Direct messages
- OAuth and account linking
- Any Discord UI component

If it is not a field in the Rich Presence `Activity` payload, it does not belong here.

---

## Design Philosophy

The public API should read as natural Swift. Raw Discord C/C++ types must not leak through. Every design decision should answer yes to: *"Can a consumer understand exactly what this does and when it runs?"*

Specific principles:

- **Swift-first public API.** No `discordpp::` types, no C strings, no raw pointers in any public interface.
- **Minimal surface area.** Prefer fewer methods that compose well over many methods that do one thing.
- **Explicit lifecycle control.** The consuming app initializes, ticks, and shuts down the SDK. The library does not do any of this on its own.
- **No global state.** No singletons, no static clients, no shared mutable state.
- **No hidden concurrency.** No background threads, no timers, no internal run loops. Work happens when the consumer calls into the library.
- **No assumptions about app architecture.** The library must work in a menu bar app, an NSApplication delegate, a SwiftUI lifecycle, or anywhere else.

If a feature can live cleanly in the consuming app without the library providing it, it should not live in the library.

---

## Architecture

### Public API Rules

- Do not expose any Discord C/C++ types — wrap them in Swift value types before they cross the boundary.
- Prefer `struct` over `class` for presence models.
- No singletons. No static factory methods that hide a shared instance.
- New public API surface requires written justification in the PR.

### Internal Boundaries

- All Social SDK bindings must be isolated in a single internal module layer. The rest of the library should not import or reference `discordpp` directly.
- The Swift ↔ C++ translation layer must be explicit and one-directional: Swift models go in, SDK calls come out.
- Errors must be typed. Do not propagate raw SDK error codes into the public API without wrapping them in a documented Swift error type.

---

## Lifecycle and Threading

The consumer is responsible for:

1. Creating a client instance with a valid application ID
2. Calling the SDK's tick/update callback on a regular interval (Discord documents this as required for SDK event processing)
3. Calling shutdown cleanly on app exit

The library must never perform any of these steps automatically. No `DispatchQueue.main.async` loops, no `Timer`, no background `Task`. If the consumer does not tick the SDK, presence simply does not update — the library must behave deterministically in that case.

If the Discord desktop client is unavailable at initialization time, the library must fail with a typed error, not a crash.

---

## Rate Limits and Reliability

Discord enforces a presence update rate limit of **once per 15 seconds**. Sending updates faster than this will result in queued or dropped updates — and depending on client behavior, may cause presence to clear unexpectedly. The library must not allow the consumer to violate this limit inadvertently.

Acceptable approach: track the timestamp of the last update and either silently drop updates that arrive too soon, or return a typed result indicating the call was rate-limited.

Presence is best-effort. The Discord client may be unavailable, the IPC channel may drop, or an update may be silently ignored. The library must handle these cases gracefully. Silent failures are acceptable. Crashes are not.

---

## SDK Versioning

The Discord Social SDK is an external binary dependency. The pinned version must be documented in the repository (version number and download source). The download location as of this writing is the Discord Developer Portal under your application's "Discord Social SDK" section.

Upgrading the SDK version must not require changes to the public API. The internal binding layer exists precisely to absorb SDK changes.

The Discord SDK license is not modified and must be preserved intact.

---

## Testing

- Core logic — payload construction, field validation, rate limit tracking — must be unit-testable without a running Discord client.
- Protocol-based abstractions should allow the SDK client to be mocked in tests.
- No test should require IPC, a local Discord installation, or network access.
- Tests that verify presence payload structure (correct fields set, correct field omission) are the highest-value tests to write.

---

## What Will Not Be Accepted

| Category | Examples |
|---|---|
| Game SDK usage | Any import of the archived Game SDK |
| Platform expansion | iOS, iPadOS, Linux, Windows support |
| Scope creep | Friends list, invites, lobbies, OAuth |
| Hidden automation | Auto-init, auto-tick, background polling |
| Non-determinism | Internal timers, run loops, background threads |
| Analytics | Telemetry, tracking, usage metrics of any kind |
| App-specific logic | Anything specific to a particular consuming application |
| Convenience magic | Helpers that hide or abstract lifecycle steps |

---

## Licensing

This wrapper is MIT licensed. The Discord Social SDK retains its original Discord license and is not relicensed by this project. By submitting a contribution, you agree that your code may be modified, redistributed, or rejected under the terms of the MIT license.

---

## Contributing

Before opening a PR:

1. Check that your change falls within the Rich Presence scope defined above.
2. Verify that no Discord C/C++ types appear in the public API.
3. Confirm that all new logic is testable without a running Discord client.
4. Write a brief justification if you are adding new public API surface.

PRs that expand scope, introduce hidden lifecycle behavior, or expose SDK internals will be closed regardless of implementation quality.

---

## Final Note

This project optimizes for **clarity, restraint, and long-term viability**. A smaller, well-understood library is worth more than a larger one with unclear boundaries. When in doubt, do less.
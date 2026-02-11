/// DiscordPresenceKit is a Swift-first wrapper around the Discord Social SDK
/// focused exclusively on Rich Presence.
///
/// ## Overview
///
/// DiscordPresenceKit provides a clean, Swift-native API for setting Discord
/// Rich Presence from macOS applications. It communicates with the local Discord
/// desktop client over IPC and requires the client to be installed and running.
///
/// ## Usage
///
/// ```swift
/// import DiscordPresenceKit
///
/// // Initialize with your Discord application ID
/// let client = try DiscordClient(applicationID: "123456789012345678")
///
/// // Update presence
/// let presence = RichPresence(
///     details: "In a match",
///     state: "Ranked – Solo Queue",
///     type: .competing
/// )
/// try await client.update(presence: presence)
///
/// // Call tick() regularly (every 1-2 seconds recommended)
/// Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
///     client.tick()
/// }
///
/// // Clean up on exit
/// await client.shutdown()
/// ```
///
/// ## Threading
///
/// All DiscordClient methods must be called from the same thread/queue.
/// The library does not perform any internal synchronization or dispatch
/// to background threads.
///
/// ## Rate Limiting
///
/// Discord enforces a rate limit of one presence update per 15 seconds.
/// Updates sent faster than this will throw ``DiscordError/rateLimitExceeded(_:)``.
///
/// ## Platform Requirements
///
/// - macOS 12.0+
/// - Discord desktop client must be installed and running
/// - Swift 5.9+
public enum DiscordPresenceKit {
    /// The current version of DiscordPresenceKit.
    public static var version: String { "0.1.0" }
}

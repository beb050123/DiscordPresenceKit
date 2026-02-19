import Foundation

// MARK: - Discord Client Protocol

/// A protocol that defines the interface for Discord Rich Presence.
///
/// Conforming types manage the lifecycle of the Discord Social SDK,
/// including initialization, presence updates, and automatic heartbeat.
///
/// # Lifecycle
///
/// 1. Initialize with a valid application ID from the Discord Developer Portal.
/// 2. Update presence with ``update(presence:)`` as needed - the library handles
///    rate limiting and heartbeat automatically.
/// 3. Call ``shutdown()`` before your app exits.
///
/// # Example
///
/// ```swift
/// let client = try DiscordClient(applicationID: "123456789012345678")
///
/// // Update presence - fire and forget, rate limiting handled automatically
/// try await client.update(presence: RichPresence(
///     details: "In a match",
///     state: "Ranked – Solo Queue"
/// ))
///
/// // Clean up on exit
/// await client.shutdown()
/// ```
public protocol DiscordClient: Sendable {
    /// Initializes a new Discord client with the specified application ID.
    ///
    /// - Parameter applicationID: Your Discord application ID from the Developer Portal.
    /// - Returns: A configured Discord client ready to start updating presence.
    /// - Throws: ``DiscordError/invalidApplicationID`` if the ID is invalid,
    ///           ``DiscordError/clientUnavailable`` if Discord is not running,
    ///           or ``DiscordError/initializationFailed(_:)`` if the SDK fails to initialize.
    init(applicationID: String) throws

    /// Updates the Discord Rich Presence with the provided configuration.
    ///
    /// This method is fire-and-forget. The library automatically handles:
    /// - Rate limiting (15-second minimum between updates)
    /// - Queuing updates that arrive during rate limit periods
    /// - Retrying failed updates
    ///
    /// - Parameter presence: The Rich Presence configuration to display.
    ///                       Pass ``RichPresence/clear`` to remove the current presence.
    /// - Throws: ``DiscordError/updateFailed(_:)`` if the update fails critically.
    func update(presence: RichPresence) async throws

    /// Shuts down the Discord client and cleans up resources.
    ///
    /// This method should be called when your app is about to terminate.
    /// After calling ``shutdown()``, the client cannot be used again.
    func shutdown() async
}

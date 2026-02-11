import Foundation

// MARK: - Discord Client Protocol

/// A protocol that defines the interface for Discord Rich Presence.
///
/// Conforming types manage the lifecycle of the Discord Social SDK,
/// including initialization, presence updates, the tick callback for
/// SDK event processing, and shutdown.
///
/// # Lifecycle
///
/// 1. Initialize with a valid application ID from the Discord Developer Portal.
/// 2. Call ``tick()`` regularly (recommended: every 1-2 seconds) to process SDK events.
/// 3. Update presence with ``update(presence:)`` as needed.
/// 4. Call ``shutdown()`` before your app exits.
///
/// # Threading
///
/// All methods must be called from the same thread/queue. The library does not
/// perform any internal synchronization or dispatch to background threads.
///
/// # Example
///
/// ```swift
/// let client = try DiscordClient(applicationID: "123456789012345678")
///
/// // Set up a timer to call tick() regularly
/// Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
///     client.tick()
/// }
///
/// // Update presence
/// let presence = RichPresence(
///     details: "In a match",
///     state: "Ranked – Solo Queue"
/// )
/// try await client.update(presence: presence)
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
    /// Discord enforces a rate limit of one presence update per 15 seconds.
    /// Updates sent faster than this will throw ``DiscordError/rateLimitExceeded(_:)``.
    ///
    /// - Parameter presence: The Rich Presence configuration to display.
    ///                       Pass ``RichPresence/clear`` to remove the current presence.
    /// - Throws: ``DiscordError/rateLimitExceeded(_:)`` if called too frequently,
    ///           ``DiscordError/updateFailed(_:)`` if the update fails.
    func update(presence: RichPresence) async throws

    /// Processes pending SDK events.
    ///
    /// This method **must** be called regularly for Rich Presence to function correctly.
    /// Discord recommends calling this every 1-2 seconds.
    ///
    /// The library does not call this method automatically. It is the consumer's
    /// responsibility to set up a timer or loop that invokes ``tick()`` on the
    /// appropriate schedule.
    ///
    /// - Important: All methods must be called from the same thread/queue.
    /// - Throws: ``DiscordError/tickFailed(_:)`` if SDK event processing fails.
    func tick() async throws

    /// Shuts down the Discord client and cleans up resources.
    ///
    /// This method should be called when your app is about to terminate.
    /// After calling ``shutdown()``, the client cannot be used again.
    ///
    /// Failing to call ``shutdown()`` may leave the IPC connection in an
    /// undefined state, but will not crash your app.
    func shutdown() async
}

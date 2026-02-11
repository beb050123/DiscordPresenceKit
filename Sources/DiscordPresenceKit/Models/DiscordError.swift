import Foundation

/// Errors that can occur when using DiscordPresenceKit.
public enum DiscordError: Error, Sendable, Equatable {
    /// The Discord desktop client is not installed or not running.
    case clientUnavailable

    /// The provided application ID is invalid (e.g., empty or malformed).
    case invalidApplicationID

    /// Presence updates were sent too quickly and exceeded Discord's rate limit.
    ///
    /// Discord enforces a maximum of one presence update per 15 seconds.
    /// The associated value indicates the number of seconds until the next
    /// update will be allowed.
    case rateLimitExceeded(retryAfter: TimeInterval)

    /// The SDK failed to initialize.
    case initializationFailed(underlying: String?)

    /// An error occurred while updating the presence.
    case updateFailed(underlying: String?)

    /// An error occurred while processing SDK events.
    case tickFailed(underlying: String?)

    // MARK: - Equatable Conformance

    public static func == (lhs: DiscordError, rhs: DiscordError) -> Bool {
        switch (lhs, rhs) {
        case (.clientUnavailable, .clientUnavailable),
             (.invalidApplicationID, .invalidApplicationID):
            return true
        case let (.rateLimitExceeded(lhsRetry), .rateLimitExceeded(rhsRetry)):
            return abs(lhsRetry - rhsRetry) < 0.01
        case let (.initializationFailed(lhsMsg), .initializationFailed(rhsMsg)),
             let (.updateFailed(lhsMsg), .updateFailed(rhsMsg)),
             let (.tickFailed(lhsMsg), .tickFailed(rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

extension DiscordError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .clientUnavailable:
            return "Discord desktop client is not available. Ensure Discord is installed and running."
        case .invalidApplicationID:
            return "The provided Discord application ID is invalid."
        case .rateLimitExceeded(let retryAfter):
            return "Rate limit exceeded. Retry after \(retryAfter) seconds."
        case .initializationFailed(let message):
            return "Failed to initialize Discord SDK: \(message ?? "unknown error")"
        case .updateFailed(let message):
            return "Failed to update presence: \(message ?? "unknown error")"
        case .tickFailed(let message):
            return "Failed to process SDK events: \(message ?? "unknown error")"
        }
    }
}

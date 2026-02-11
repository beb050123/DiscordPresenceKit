import Foundation

// MARK: - Rate Limiter

/// Enforces Discord's 15-second minimum interval between presence updates.
///
/// Discord enforces a rate limit of one presence update per 15 seconds.
/// This rate limiter prevents consumers from accidentally violating this limit.
///
/// ## Usage
///
/// ```swift
/// let rateLimiter = PresenceRateLimiter()
///
/// switch rateLimiter.recordUpdate() {
/// case .success:
///     // Proceed with Discord SDK update
/// case .failure(let error):
///     // Handle rate limit error
///     print("Retry after \(error.secondsUntilNextUpdate) seconds")
/// }
/// ```
public final class PresenceRateLimiter: Sendable {
    // MARK: - Configuration

    /// Discord's enforced minimum interval between presence updates.
    public static let minimumUpdateInterval: TimeInterval = 15.0

    // MARK: - Properties

    private let minimumInterval: TimeInterval
    private let timeSource: any TimeSource
    private let stateLock: NSLock

    // State protected by stateLock
    private var lastUpdateTimestamp: TimeInterval?

    // MARK: - Initialization

    /// Creates a new rate limiter.
    ///
    /// - Parameters:
    ///   - minimumInterval: Minimum seconds between updates (default: 15.0).
    ///   - timeSource: Time source for timestamp generation (default: wall clock).
    public init(
        minimumInterval: TimeInterval = 15.0,
        timeSource: any TimeSource = WallClockTimeSource()
    ) {
        precondition(minimumInterval > 0, "Minimum interval must be positive")

        self.minimumInterval = minimumInterval
        self.timeSource = timeSource
        self.stateLock = NSLock()
    }

    // MARK: - Public API

    /// Attempts to record an update, enforcing rate limits.
    ///
    /// - Returns: `.success` if the update is allowed, `.failure` if rate limited.
    public func recordUpdate() -> Result<Void, PresenceUpdateError> {
        stateLock.withCriticalScope {
            let now = timeSource.currentTimestamp

            if let lastTimestamp = lastUpdateTimestamp {
                let elapsed = now - lastTimestamp

                if elapsed < minimumInterval {
                    let remaining = minimumInterval - elapsed
                    return .failure(.rateLimited(secondsRemaining: remaining))
                }
            }

            lastUpdateTimestamp = now
            return .success(())
        }
    }

    /// Resets the rate limiter state, allowing the next update immediately.
    ///
    /// Use sparingly — typically only after SDK reinitialization.
    public func reset() {
        stateLock.withCriticalScope {
            lastUpdateTimestamp = nil
        }
    }

    /// Checks whether an update would be allowed without modifying state.
    ///
    /// - Returns: `true` if an update would be allowed, `false` if rate limited.
    public func canUpdate() -> Bool {
        stateLock.withCriticalScope {
            guard let lastTimestamp = lastUpdateTimestamp else {
                return true
            }

            let elapsed = timeSource.currentTimestamp - lastTimestamp
            return elapsed >= minimumInterval
        }
    }

    /// Time in seconds until the next update will be allowed.
    ///
    /// Returns `0` if an update can be made now.
    public var secondsUntilNextUpdate: TimeInterval {
        stateLock.withCriticalScope {
            guard let lastTimestamp = lastUpdateTimestamp else {
                return 0
            }

            let elapsed = timeSource.currentTimestamp - lastTimestamp
            let remaining = minimumInterval - elapsed
            return max(0, remaining)
        }
    }
}

// MARK: - Presence Update Error

/// Errors that can occur when attempting to update presence due to rate limiting.
public enum PresenceUpdateError: Error, Sendable {
    /// The update was rate limited.
    ///
    /// The associated value contains the number of seconds until the next
    /// update will be allowed.
    case rateLimited(secondsRemaining: TimeInterval)

    /// The time in seconds until the next update will be accepted.
    public var secondsUntilNextUpdate: TimeInterval {
        switch self {
        case .rateLimited(let seconds):
            return seconds
        }
    }
}

extension PresenceUpdateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .rateLimited(let seconds):
            return "Rate limited. Retry after \(seconds) seconds."
        }
    }
}

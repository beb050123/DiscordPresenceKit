import Foundation

// MARK: - Time Source Protocol

/// Protocol for time-based operations to enable testing.
///
/// This abstraction allows rate limiting logic to be tested
/// without real time passage or sleep calls.
public protocol TimeSource: Sendable {
    /// The current timestamp as a `TimeInterval` (seconds since epoch).
    var currentTimestamp: TimeInterval { get }
}

/// Production time source using wall-clock time.
public struct WallClockTimeSource: TimeSource {
    public init() {}

    public var currentTimestamp: TimeInterval {
        Date().timeIntervalSince1970
    }
}

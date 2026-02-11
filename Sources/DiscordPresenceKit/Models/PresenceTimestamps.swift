import Foundation

/// Timestamps for displaying elapsed or remaining time in Rich Presence.
///
/// Discord displays time as either:
/// - Elapsed time since a start timestamp (e.g., "00:15 elapsed")
/// - Remaining time until an end timestamp (e.g., "01:45 remaining")
///
/// Only one type of timestamp should be set at a time.
public struct PresenceTimestamps: Sendable, Equatable {
    /// The start timestamp - shows elapsed time when set.
    public let start: Date?

    /// The end timestamp - shows remaining time when set.
    public let end: Date?

    /// Creates a new presence timestamps configuration.
    ///
    /// - Important: Only one of `start` or `end` should be set at a time.
    ///              If both are provided, `start` takes precedence.
    ///
    /// - Parameters:
    ///   - start: The start date for elapsed time display.
    ///   - end: The end date for remaining time display.
    public init(start: Date?, end: Date?) {
        // Only one of start or end should be set at a time.
        // If both are provided, prefer start (elapsed time).
        if let start = start, end != nil {
            self.start = start
            self.end = nil
        } else {
            self.start = start
            self.end = end
        }
    }

    /// Creates timestamps showing elapsed time since the given date.
    ///
    /// - Parameter date: The start date for elapsed time display.
    /// - Returns: A timestamp configuration for elapsed time.
    public static func elapsed(since date: Date) -> PresenceTimestamps {
        PresenceTimestamps(start: date, end: nil)
    }

    /// Creates timestamps showing remaining time until the given date.
    ///
    /// - Parameter date: The end date for remaining time display.
    /// - Returns: A timestamp configuration for remaining time.
    public static func remaining(until date: Date) -> PresenceTimestamps {
        PresenceTimestamps(start: nil, end: date)
    }
}

extension PresenceTimestamps: Codable {
    enum CodingKeys: String, CodingKey {
        case start
        case end
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let start = try container.decodeIfPresent(Date.self, forKey: .start)
        let end = try container.decodeIfPresent(Date.self, forKey: .end)

        // Use the init to enforce mutual exclusivity
        self.init(start: start, end: end)
    }
}

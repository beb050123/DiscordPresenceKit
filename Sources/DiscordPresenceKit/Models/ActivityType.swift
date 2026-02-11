/// The type of activity being displayed in Rich Presence.
///
/// These values correspond to the Discord SDK's activity types.
/// Only the types supported by the Discord Social SDK are included.
public enum ActivityType: Int, Sendable {
    /// General "Playing" activity (default)
    case playing = 0

    /// "Listening to" activity (e.g., music, podcasts)
    case listening = 2

    /// "Watching" activity (e.g., videos, streams)
    case watching = 3

    /// "Competing in" activity (e.g., games, tournaments)
    case competing = 5
}

extension ActivityType: Codable {}

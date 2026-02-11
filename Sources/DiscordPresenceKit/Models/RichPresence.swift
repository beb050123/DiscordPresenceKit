import Foundation

/// The main Rich Presence activity model.
///
/// Use this type to describe what should be displayed in Discord Rich Presence.
/// Setting an empty or nil presence clears the current display.
///
/// ## Example
///
/// ```swift
/// let presence = RichPresence(
///     details: "In a match",
///     state: "Ranked – Solo Queue",
///     timestamps: .elapsed(since: Date().addingTimeInterval(-600)),
///     assets: PresenceAssets(
///         largeImage: "map_icon",
///         largeText: "Summoner's Rift",
///         smallImage: "rank_icon",
///         smallText: "Gold II"
///     ),
///     buttons: [
///         PresenceButton(label: "View Profile", url: URL(string: "https://example.com")!)
///     ],
///     type: .competing
/// )
/// ```
public struct RichPresence: Sendable, Equatable {
    /// Primary activity description (e.g., "In a match").
    /// Displayed below the application name.
    public let details: String?

    /// Secondary status (e.g., "Ranked – Solo Queue").
    /// Displayed below the details.
    public let state: String?

    /// Timestamps for elapsed/remaining time display.
    public let timestamps: PresenceTimestamps?

    /// Images and tooltips for the presence card.
    public let assets: PresenceAssets?

    /// Up to 2 clickable buttons.
    /// Discord enforces a maximum of 2 buttons; any extras are silently dropped.
    public let buttons: [PresenceButton]

    /// The type of activity (defaults to `.playing`).
    public let type: ActivityType

    /// Override for the application name shown in presence (SDK v1.6+).
    /// When `nil`, the application's configured name is used.
    public let name: String?

    /// Creates a new RichPresence configuration.
    ///
    /// - Parameters:
    ///   - details: Primary activity description.
    ///   - state: Secondary status.
    ///   - timestamps: Timestamps for elapsed/remaining time.
    ///   - assets: Images and tooltips.
    ///   - buttons: Up to 2 clickable buttons (excess are dropped).
    ///   - type: Activity type (defaults to `.playing`).
    ///   - name: Application name override.
    public init(
        details: String? = nil,
        state: String? = nil,
        timestamps: PresenceTimestamps? = nil,
        assets: PresenceAssets? = nil,
        buttons: [PresenceButton] = [],
        type: ActivityType = .playing,
        name: String? = nil
    ) {
        self.details = details
        self.state = state
        self.timestamps = timestamps
        self.assets = assets
        // Discord enforces a maximum of 2 buttons
        self.buttons = Array(buttons.prefix(2))
        self.type = type
        self.name = name
    }

    /// An empty presence that clears any current Rich Presence display.
    ///
    /// Use this to remove the current presence without setting a new one.
    public static let clear = RichPresence()
}

extension RichPresence: Codable {
    enum CodingKeys: String, CodingKey {
        case details
        case state
        case timestamps
        case assets
        case buttons
        case type
        case name
    }
}

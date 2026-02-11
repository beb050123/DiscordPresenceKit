import Foundation

/// Images and tooltips for the Rich Presence display.
///
/// Image assets must be uploaded to your Discord application in the
/// [Discord Developer Portal](https://discord.com/developers/applications).
/// Use the asset keys (not URLs) when configuring presence.
public struct PresenceAssets: Sendable, Equatable {
    /// Key for the large image asset uploaded in Discord Developer Portal.
    public let largeImage: String?

    /// Tooltip text shown when hovering over the large image.
    public let largeText: String?

    /// Key for the small image asset uploaded in Discord Developer Portal.
    public let smallImage: String?

    /// Tooltip text shown when hovering over the small image.
    public let smallText: String?

    /// Creates a new presence assets configuration.
    ///
    /// - Parameters:
    ///   - largeImage: Asset key for the large image.
    ///   - largeText: Hover text for the large image.
    ///   - smallImage: Asset key for the small image.
    ///   - smallText: Hover text for the small image.
    public init(
        largeImage: String? = nil,
        largeText: String? = nil,
        smallImage: String? = nil,
        smallText: String? = nil
    ) {
        self.largeImage = largeImage
        self.largeText = largeText
        self.smallImage = smallImage
        self.smallText = smallText
    }
}

extension PresenceAssets: Codable {}

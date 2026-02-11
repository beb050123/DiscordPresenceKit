import Foundation

/// A clickable button in Rich Presence.
///
/// Discord allows up to 2 buttons per presence.
/// Buttons are displayed at the bottom of the presence card.
public struct PresenceButton: Sendable, Equatable {
    /// The label text shown on the button.
    /// Maximum length is 32 characters.
    public let label: String

    /// The URL to open when the button is clicked.
    /// Must be a valid HTTPS URL.
    public let url: URL

    /// Creates a new presence button.
    ///
    /// - Parameters:
    ///   - label: The button label text (max 32 characters).
    ///   - url: The URL to open when clicked.
    public init(label: String, url: URL) {
        self.label = label
        self.url = url
    }
}

extension PresenceButton: Codable {
    enum CodingKeys: String, CodingKey {
        case label
        case url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)

        let urlString = try container.decode(String.self, forKey: .url)
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .url,
                in: container,
                debugDescription: "Invalid URL string"
            )
        }
        self.url = url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(url.absoluteString, forKey: .url)
    }
}

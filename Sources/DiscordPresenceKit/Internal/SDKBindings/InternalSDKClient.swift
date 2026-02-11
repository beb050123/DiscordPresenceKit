import Foundation

// MARK: - Internal SDK Client Protocol

/// Protocol abstracting Discord Social SDK operations.
///
/// This protocol allows the public API to be tested without requiring
/// the actual C++ Discord SDK, IPC, or a running Discord client.
internal protocol InternalSDKClient: Sendable {
    /// Initializes the Discord SDK with the given application ID.
    ///
    /// - Parameter applicationID: The Discord application ID.
    /// - Returns: `.success` if initialization succeeded, `.failure` otherwise.
    func initialize(applicationID: String) -> Result<Void, SDKError>

    /// Updates the Rich Presence with the given activity.
    ///
    /// - Parameter activity: The activity to display.
    /// - Returns: `.success` if the update was sent, `.failure` otherwise.
    func updatePresence(_ activity: InternalActivity) -> Result<Void, SDKError>

    /// Processes pending SDK events.
    ///
    /// This should be called regularly (every 1-2 seconds recommended).
    ///
    /// - Returns: `.success` if tick completed, `.failure` if an error occurred.
    func tick() -> Result<Void, SDKError>

    /// Shuts down the SDK and cleans up resources.
    func shutdown()
}

// MARK: - SDK Errors

/// Errors that can occur from the Discord SDK.
internal enum SDKError: Error, Equatable {
    /// The SDK client was not initialized.
    case clientNotInitialized

    /// The Discord desktop client is not available.
    case clientUnavailable

    /// The provided application ID is invalid.
    case invalidApplicationID

    /// SDK initialization failed.
    case initializationFailed(message: String?)

    /// Presence update failed.
    case updateFailed(message: String?)

    /// Tick operation failed.
    case tickFailed(message: String?)

    static func == (lhs: SDKError, rhs: SDKError) -> Bool {
        switch (lhs, rhs) {
        case (.clientNotInitialized, .clientNotInitialized),
             (.clientUnavailable, .clientUnavailable),
             (.invalidApplicationID, .invalidApplicationID):
            return true
        case let (.initializationFailed(lMsg), .initializationFailed(rMsg)),
             let (.updateFailed(lMsg), .updateFailed(rMsg)),
             let (.tickFailed(lMsg), .tickFailed(rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

// MARK: - Internal Activity Model

/// Internal representation of a Discord Rich Presence activity.
///
/// This type is used to translate between the public ``RichPresence``
/// model and the Discord SDK's C++ `Activity` structure.
internal struct InternalActivity: Sendable, Equatable {
    /// Primary activity description.
    var details: String?

    /// Secondary status.
    var state: String?

    /// Start timestamp for elapsed time.
    var startTimestamp: TimeInterval?

    /// End timestamp for remaining time.
    var endTimestamp: TimeInterval?

    /// Large image asset key.
    var largeImage: String?

    /// Large image hover text.
    var largeText: String?

    /// Small image asset key.
    var smallImage: String?

    /// Small image hover text.
    var smallText: String?

    /// Buttons for the presence.
    var buttons: [InternalButton]

    /// Activity type.
    var type: ActivityType

    /// Application name override.
    var name: String?
}

// MARK: - Internal Button Model

/// Internal representation of a presence button.
internal struct InternalButton: Sendable, Equatable {
    /// Button label.
    var label: String

    /// URL to open.
    var url: String
}

// MARK: - Rich Presence Extension

extension RichPresence {
    /// Converts the public ``RichPresence`` model to an internal activity.
    internal func toInternalActivity() -> InternalActivity {
        InternalActivity(
            details: details,
            state: state,
            startTimestamp: timestamps?.start?.timeIntervalSince1970,
            endTimestamp: timestamps?.end?.timeIntervalSince1970,
            largeImage: assets?.largeImage,
            largeText: assets?.largeText,
            smallImage: assets?.smallImage,
            smallText: assets?.smallText,
            buttons: buttons.map { button in
                InternalButton(label: button.label, url: button.url.absoluteString)
            },
            type: type,
            name: name
        )
    }
}

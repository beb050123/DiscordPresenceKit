import Foundation
import DiscordCXXBridge

// MARK: - Discord SDK Client (Production)

/// The concrete implementation of ``InternalSDKClient`` that wraps
/// the Discord Game SDK via the Objective-C++ bridge.
///
/// This implementation communicates with the local Discord desktop client
/// over IPC to set Rich Presence.
///
/// Note: Swift automatically converts Objective-C methods with `NSError **`
/// parameters to throwing methods. The bridge methods are called as `try`
/// rather than checking a Bool return value.
internal final class DiscordSDKClient: InternalSDKClient {
    // MARK: - Properties

    private var bridge: DiscordSDKBridge?
    private let stateLock: NSLock

    // MARK: - Initialization

    internal init() {
        self.bridge = DiscordSDKBridge()
        self.stateLock = NSLock()
    }

    deinit {
        shutdown()
    }

    // MARK: - InternalSDKClient Protocol

    internal func initialize(applicationID: String) -> Result<Void, SDKError> {
        guard let bridge = bridge else {
            return .failure(.clientUnavailable)
        }

        do {
            // Swift converts the NSError** parameter to a throwing method
            try bridge.initialize(withApplicationID: applicationID)
            return .success(())
        } catch let error as NSError {
            let message = error.localizedDescription
            if message.contains("Invalid") || message.contains("application ID") {
                return .failure(.invalidApplicationID)
            }
            return .failure(.initializationFailed(message: message))
        } catch {
            return .failure(.initializationFailed(message: "Unknown error"))
        }
    }

    internal func updatePresence(_ activity: InternalActivity) -> Result<Void, SDKError> {
        guard let bridge = bridge else {
            return .failure(.clientNotInitialized)
        }

        let start = activity.startTimestamp.map { NSNumber(value: $0) }
        let end = activity.endTimestamp.map { NSNumber(value: $0) }

        do {
            // Swift converts the NSError** parameter to a throwing method
            try bridge.updatePresence(
                withDetails: activity.details,
                state: activity.state,
                startTimestamp: start,
                endTimestamp: end,
                largeImageKey: activity.largeImage,
                largeText: activity.largeText,
                smallImageKey: activity.smallImage,
                smallText: activity.smallText,
                button1Label: activity.buttons.count > 0 ? activity.buttons[0].label : nil,
                button1Url: activity.buttons.count > 0 ? activity.buttons[0].url : nil,
                button2Label: activity.buttons.count > 1 ? activity.buttons[1].label : nil,
                button2Url: activity.buttons.count > 1 ? activity.buttons[1].url : nil,
                activityType: activity.type.rawValue,
                applicationName: activity.name
            )
            return .success(())
        } catch let error as NSError {
            let message = error.localizedDescription
            if message.contains("not initialized") {
                return .failure(.clientNotInitialized)
            }
            return .failure(.updateFailed(message: message))
        } catch {
            return .failure(.updateFailed(message: nil))
        }
    }

    internal func tick() -> Result<Void, SDKError> {
        bridge?.runCallbacks()
        return .success(())
    }

    internal func shutdown() {
        bridge?.shutdown()
    }
}

// MARK: - Client State (removed as bridge handles this)

private enum ClientState {
    case uninitialized
    case initialized(applicationID: String)
}

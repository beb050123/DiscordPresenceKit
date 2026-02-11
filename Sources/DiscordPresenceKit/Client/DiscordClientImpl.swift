import Foundation

// MARK: - Discord Client Implementation

/// The concrete implementation of ``DiscordClient`` using the Discord Social SDK.
///
/// This implementation manages the underlying Discord SDK lifecycle,
/// enforces rate limiting, and provides a Swift-first public API.
public final class DiscordClientImpl: DiscordClient {
    // MARK: - Properties

    /// The Discord application ID for this client.
    public let applicationID: String

    private let sdkClient: InternalSDKClient
    private let rateLimiter: PresenceRateLimiter
    private let stateLock: NSLock

    // State protected by stateLock
    private var _isInitialized = false
    private var _isShutdown = false

    /// Whether the client has been successfully initialized.
    public var isInitialized: Bool {
        stateLock.withCriticalScope { _isInitialized }
    }

    /// Whether the client has been shut down.
    public var isShutdown: Bool {
        stateLock.withCriticalScope { _isShutdown }
    }

    // MARK: - Initialization

    /// Creates a new Discord client with the specified application ID.
    ///
    /// - Parameters:
    ///   - applicationID: Your Discord application ID from the Developer Portal.
    /// - Throws: ``DiscordError/invalidApplicationID`` if the ID is invalid,
    ///           ``DiscordError/clientUnavailable`` if Discord is not running,
    ///           or ``DiscordError/initializationFailed(_:)`` if the SDK fails to initialize.
    public init(applicationID: String) throws {
        guard !applicationID.isEmpty else {
            throw DiscordError.invalidApplicationID
        }

        self.applicationID = applicationID
        self.sdkClient = DiscordSDKClient()
        self.rateLimiter = PresenceRateLimiter()
        self.stateLock = NSLock()

        // Initialize the underlying SDK
        switch sdkClient.initialize(applicationID: applicationID) {
        case .success:
            stateLock.withCriticalScope { _isInitialized = true }
        case .failure(let error):
            switch error {
            case .invalidApplicationID:
                throw DiscordError.invalidApplicationID
            case .clientUnavailable:
                throw DiscordError.clientUnavailable
            case .initializationFailed(let message):
                throw DiscordError.initializationFailed(underlying: message)
            case .clientNotInitialized, .updateFailed, .tickFailed:
                throw DiscordError.initializationFailed(underlying: error.localizedDescription)
            }
        }
    }

    /// Internal initializer for dependency injection in tests.
    init(
        applicationID: String,
        sdkClient: InternalSDKClient,
        rateLimiter: PresenceRateLimiter
    ) throws {
        guard !applicationID.isEmpty else {
            throw DiscordError.invalidApplicationID
        }

        self.applicationID = applicationID
        self.sdkClient = sdkClient
        self.rateLimiter = rateLimiter
        self.stateLock = NSLock()

        // Initialize the underlying SDK
        switch sdkClient.initialize(applicationID: applicationID) {
        case .success:
            stateLock.withCriticalScope { _isInitialized = true }
        case .failure(let error):
            switch error {
            case .invalidApplicationID:
                throw DiscordError.invalidApplicationID
            case .clientUnavailable:
                throw DiscordError.clientUnavailable
            case .initializationFailed(let message):
                throw DiscordError.initializationFailed(underlying: message)
            case .clientNotInitialized, .updateFailed, .tickFailed:
                throw DiscordError.initializationFailed(underlying: error.localizedDescription)
            }
        }
    }

    // MARK: - DiscordClient Protocol

    public func update(presence: RichPresence) async throws {
        try checkNotShutdown()

        // Check rate limit first
        let result = rateLimiter.recordUpdate()
        if case .failure(let error) = result {
            throw DiscordError.rateLimitExceeded(retryAfter: error.secondsUntilNextUpdate)
        }

        // Convert to internal activity and update
        let activity = presence.toInternalActivity()

        switch sdkClient.updatePresence(activity) {
        case .success:
            break
        case .failure(let error):
            switch error {
            case .clientNotInitialized:
                throw DiscordError.updateFailed(underlying: "SDK client not initialized")
            case .clientUnavailable:
                throw DiscordError.clientUnavailable
            case .updateFailed(let message):
                throw DiscordError.updateFailed(underlying: message)
            case .invalidApplicationID, .initializationFailed, .tickFailed:
                throw DiscordError.updateFailed(underlying: error.localizedDescription)
            }
        }
    }

    public func tick() async throws {
        try checkNotShutdown()

        switch sdkClient.tick() {
        case .success:
            break
        case .failure(let error):
            throw DiscordError.tickFailed(underlying: error.localizedDescription)
        }
    }

    public func shutdown() async {
        var shouldCallShutdown = false
        stateLock.withCriticalScope {
            guard !_isShutdown else { return }
            _isShutdown = true
            _isInitialized = false
            shouldCallShutdown = true
        }

        if shouldCallShutdown {
            sdkClient.shutdown()
        }
    }

    // MARK: - Private Methods

    private func checkNotShutdown() throws {
        guard !isShutdown else {
            throw DiscordError.updateFailed(underlying: "Client has been shut down")
        }
    }
}

// MARK: - NSLock Convenience

extension NSLock {
    func withCriticalScope<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}

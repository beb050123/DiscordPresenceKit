import Foundation

// MARK: - Discord Client Implementation

/// The concrete implementation of ``DiscordClient`` using the Discord Social SDK.
///
/// This implementation manages the underlying Discord SDK lifecycle,
/// handles automatic heartbeat/tick, and provides fire-and-forget presence updates
/// with automatic rate limiting.
public final class DiscordClientImpl: DiscordClient {
    // MARK: - Properties

    /// The Discord application ID for this client.
    public let applicationID: String

    private let sdkClient: InternalSDKClient
    private let rateLimiter: PresenceRateLimiter
    private let stateLock: NSLock
    
    // Heartbeat management
    private var heartbeatTask: Task<Void, Never>?
    private let heartbeatInterval: TimeInterval
    
    // Pending presence update (queued when rate limited)
    private var pendingPresence: RichPresence?
    
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
        self.heartbeatInterval = 1.5 // Discord recommends 1-2 seconds

        // Initialize the underlying SDK
        switch sdkClient.initialize(applicationID: applicationID) {
        case .success:
            stateLock.withCriticalScope { _isInitialized = true }
            startHeartbeat()
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
        rateLimiter: PresenceRateLimiter,
        heartbeatInterval: TimeInterval = 1.5
    ) throws {
        guard !applicationID.isEmpty else {
            throw DiscordError.invalidApplicationID
        }

        self.applicationID = applicationID
        self.sdkClient = sdkClient
        self.rateLimiter = rateLimiter
        self.stateLock = NSLock()
        self.heartbeatInterval = heartbeatInterval

        // Initialize the underlying SDK
        switch sdkClient.initialize(applicationID: applicationID) {
        case .success:
            stateLock.withCriticalScope { _isInitialized = true }
            startHeartbeat()
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
        
        // Store the pending presence
        stateLock.withCriticalScope {
            pendingPresence = presence
        }
        
        // Try to send immediately if not rate limited
        try await sendPendingPresence()
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
            // Stop heartbeat
            heartbeatTask?.cancel()
            heartbeatTask = nil
            
            // Clear pending
            stateLock.withCriticalScope {
                pendingPresence = nil
            }
            
            sdkClient.shutdown()
        }
    }

    // MARK: - Private Methods

    private func startHeartbeat() {
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self, !self.isShutdown else { break }
                
                // Run SDK callbacks
                _ = self.sdkClient.tick()
                
                // Check if we have a pending presence to send
                if self.rateLimiter.canUpdate() {
                    if let pending = self.stateLock.withCriticalScope({ self.pendingPresence }) {
                        try? self.performUpdate(presence: pending)
                    }
                }
                
                // Sleep for heartbeat interval (nanoseconds API for macOS 12 compatibility)
                try? await Task.sleep(nanoseconds: UInt64(self.heartbeatInterval * 1_000_000_000))
            }
        }
    }
    
    private func sendPendingPresence() async throws {
        guard let presence = stateLock.withCriticalScope({ pendingPresence }) else { return }
        
        // Check rate limit
        if !rateLimiter.canUpdate() {
            // Update is queued - it will be sent by heartbeat when rate limit expires
            return
        }
        
        try performUpdate(presence: presence)
    }
    
    private func performUpdate(presence: RichPresence) throws {
        let result = rateLimiter.recordUpdate()
        guard case .success = result else {
            // Shouldn't happen since we checked canUpdate(), but handle gracefully
            return
        }
        
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

import Foundation
@testable import DiscordPresenceKit

// MARK: - Mock SDK Client

/// Mock implementation of ``InternalSDKClient`` for testing.
///
/// This mock allows tests to verify SDK interactions without requiring
/// the actual C++ Discord SDK, IPC, or a running Discord client.
final class MockSDKClient: InternalSDKClient {
    // MARK: - Call Tracking

    private(set) var initializeWasCalled = false
    private(set) var updatePresenceWasCalled = false
    private(set) var tickWasCalled = false
    private(set) var shutdownWasCalled = false

    private(set) var initializeCallCount = 0
    private(set) var updatePresenceCallCount = 0
    private(set) var tickCallCount = 0
    private(set) var shutdownCallCount = 0

    private(set) var lastActivity: InternalActivity?
    private(set) var lastApplicationID: String?

    // MARK: - Behavior Configuration

    private var shouldFailInitialization = false
    private var shouldFailUpdate = false
    private var shouldFailTick = false
    private var initializationError: SDKError?
    private var updateError: SDKError?
    private var tickError: SDKError?

    // MARK: - Initialization

    init() {}

    // MARK: - InternalSDKClient Protocol

    func initialize(applicationID: String) -> Result<Void, SDKError> {
        initializeWasCalled = true
        initializeCallCount += 1
        lastApplicationID = applicationID

        if shouldFailInitialization, let error = initializationError {
            return .failure(error)
        }

        return .success(())
    }

    func updatePresence(_ activity: InternalActivity) -> Result<Void, SDKError> {
        updatePresenceWasCalled = true
        updatePresenceCallCount += 1
        lastActivity = activity

        if shouldFailUpdate, let error = updateError {
            return .failure(error)
        }

        return .success(())
    }

    func tick() -> Result<Void, SDKError> {
        tickWasCalled = true
        tickCallCount += 1

        if shouldFailTick, let error = tickError {
            return .failure(error)
        }

        return .success(())
    }

    func shutdown() {
        shutdownWasCalled = true
        shutdownCallCount += 1
    }

    // MARK: - Test Configuration

    /// Sets whether initialization should fail.
    func failInitialization(_ shouldFail: Bool, error: SDKError? = nil) {
        shouldFailInitialization = shouldFail
        initializationError = error
    }

    /// Sets whether update presence should fail.
    func failUpdate(_ shouldFail: Bool, error: SDKError? = nil) {
        shouldFailUpdate = shouldFail
        updateError = error
    }

    /// Sets whether tick should fail.
    func failTick(_ shouldFail: Bool, error: SDKError? = nil) {
        shouldFailTick = shouldFail
        tickError = error
    }

    /// Resets all call tracking and behavior configuration.
    func reset() {
        initializeWasCalled = false
        updatePresenceWasCalled = false
        tickWasCalled = false
        shutdownWasCalled = false

        initializeCallCount = 0
        updatePresenceCallCount = 0
        tickCallCount = 0
        shutdownCallCount = 0

        lastActivity = nil
        lastApplicationID = nil

        shouldFailInitialization = false
        shouldFailUpdate = false
        shouldFailTick = false

        initializationError = nil
        updateError = nil
        tickError = nil
    }
}

// MARK: - Mock Time Source

/// Mock implementation of ``TimeSource`` for testing rate limiting.
final class MockTimeSource: TimeSource {
    var currentTime: TimeInterval = 0

    init(currentTime: TimeInterval = 0) {
        self.currentTime = currentTime
    }

    var currentTimestamp: TimeInterval {
        currentTime
    }

    func advance(by seconds: TimeInterval) {
        currentTime += seconds
    }
}

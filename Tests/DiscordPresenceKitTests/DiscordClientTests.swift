import XCTest
@testable import DiscordPresenceKit

/// Tests for DiscordClient lifecycle and operations.
final class DiscordClientTests: XCTestCase {
    var mockSDK: MockSDKClient!
    var mockRateLimiter: PresenceRateLimiter!
    var mockTime: MockTimeSource!

    override func setUp() {
        super.setUp()
        mockSDK = MockSDKClient()
        mockTime = MockTimeSource(currentTime: 0)
        mockRateLimiter = PresenceRateLimiter(timeSource: mockTime)
    }

    override func tearDown() {
        mockSDK = nil
        mockRateLimiter = nil
        mockTime = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func testInitializeSuccess() throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app-123",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter,
            heartbeatInterval: 0.1 // Fast for testing
        )

        XCTAssertTrue(mockSDK.initializeWasCalled)
        XCTAssertEqual(mockSDK.lastApplicationID, "test-app-123")
        XCTAssertTrue(client.isInitialized)
        XCTAssertFalse(client.isShutdown)
    }

    func testInitializeWithEmptyApplicationID() {
        XCTAssertThrowsError(
            try DiscordClientImpl(
                applicationID: "",
                sdkClient: mockSDK,
                rateLimiter: mockRateLimiter
            )
        ) { error in
            XCTAssertEqual(error as? DiscordError, .invalidApplicationID)
        }

        XCTAssertFalse(mockSDK.initializeWasCalled, "Should not call SDK with empty app ID")
    }

    func testInitializeWithSDKFailure() {
        mockSDK.failInitialization(true, error: .clientUnavailable)

        XCTAssertThrowsError(
            try DiscordClientImpl(
                applicationID: "test-app",
                sdkClient: mockSDK,
                rateLimiter: mockRateLimiter
            )
        ) { error in
            XCTAssertEqual(error as? DiscordError, .clientUnavailable)
        }
    }

    // MARK: - Update Presence

    func testUpdatePresenceSuccess() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter,
            heartbeatInterval: 0.1
        )

        let presence = RichPresence(
            details: "In Game",
            state: "Playing"
        )

        try await client.update(presence: presence)

        XCTAssertTrue(mockSDK.updatePresenceWasCalled)
        XCTAssertEqual(mockSDK.updatePresenceCallCount, 1)
        XCTAssertNotNil(mockSDK.lastActivity)
        XCTAssertEqual(mockSDK.lastActivity?.details, "In Game")
        XCTAssertEqual(mockSDK.lastActivity?.state, "Playing")
    }

    func testUpdatePresenceWithFullActivity() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter,
            heartbeatInterval: 0.1
        )

        let startDate = Date()
        let presence = RichPresence(
            details: "In a match",
            state: "Ranked",
            timestamps: .elapsed(since: startDate),
            assets: PresenceAssets(
                largeImage: "map",
                largeText: "Map Name",
                smallImage: "rank",
                smallText: "Gold"
            ),
            buttons: [
                PresenceButton(label: "View", url: URL(string: "https://example.com")!)
            ],
            type: .competing,
            name: "My App"
        )

        try await client.update(presence: presence)

        let activity = mockSDK.lastActivity
        XCTAssertEqual(activity?.details, "In a match")
        XCTAssertEqual(activity?.state, "Ranked")
        XCTAssertEqual(activity?.startTimestamp, startDate.timeIntervalSince1970)
        XCTAssertEqual(activity?.largeImage, "map")
        XCTAssertEqual(activity?.largeText, "Map Name")
        XCTAssertEqual(activity?.smallImage, "rank")
        XCTAssertEqual(activity?.smallText, "Gold")
        XCTAssertEqual(activity?.buttons.count, 1)
        XCTAssertEqual(activity?.buttons[0].label, "View")
        XCTAssertEqual(activity?.type, .competing)
        XCTAssertEqual(activity?.name, "My App")
    }

    func testUpdatePresenceRateLimitedQueuesUpdate() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter,
            heartbeatInterval: 0.1
        )

        let presence = RichPresence(details: "Test")

        // First update should succeed
        try await client.update(presence: presence)
        XCTAssertEqual(mockSDK.updatePresenceCallCount, 1)

        // Immediate second update should be queued (no error thrown)
        let presence2 = RichPresence(details: "Test 2")
        try await client.update(presence: presence2)
        
        // SDK should not be called again immediately
        XCTAssertEqual(mockSDK.updatePresenceCallCount, 1, "SDK should not be called when rate limited")
        
        // Wait for heartbeat to process the queued update after rate limit expires
        mockTime.advance(by: 15.0) // Advance past rate limit
        try await Task.sleep(nanoseconds: 200_000_000) // Wait for heartbeat cycle
        
        XCTAssertEqual(mockSDK.updatePresenceCallCount, 2, "Queued update should be sent after rate limit")
    }

    func testUpdatePresenceAfterShutdown() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter,
            heartbeatInterval: 0.1
        )

        await client.shutdown()

        let presence = RichPresence(details: "Test")

        do {
            try await client.update(presence: presence)
            XCTFail("Should have thrown error after shutdown")
        } catch let error as DiscordError {
            switch error {
            case .updateFailed(let message):
                XCTAssertNotNil(message)
            default:
                XCTFail("Expected updateFailed error")
            }
        }
    }

    // MARK: - Automatic Heartbeat

    func testHeartbeatCallsTickAutomatically() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter,
            heartbeatInterval: 0.1 // Fast for testing
        )

        // Wait for a few heartbeat cycles
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Tick should have been called multiple times by heartbeat
        XCTAssertTrue(mockSDK.tickWasCalled)
        XCTAssertGreaterThan(mockSDK.tickCallCount, 2)
    }

    // MARK: - Shutdown

    func testShutdown() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter,
            heartbeatInterval: 0.1
        )

        await client.shutdown()

        XCTAssertTrue(mockSDK.shutdownWasCalled)
        XCTAssertTrue(client.isShutdown)
        XCTAssertFalse(client.isInitialized)
    }

    func testShutdownIdempotent() async throws {
        // Create completely fresh dependencies for this test
        let freshMockSDK = MockSDKClient()
        let freshTimeSource = MockTimeSource(currentTime: 0)
        let freshRateLimiter = PresenceRateLimiter(timeSource: freshTimeSource)

        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: freshMockSDK,
            rateLimiter: freshRateLimiter,
            heartbeatInterval: 0.1
        )

        await client.shutdown()
        await client.shutdown()
        await client.shutdown()

        XCTAssertEqual(freshMockSDK.shutdownCallCount, 1, "Shutdown should only be called once")
    }

    // MARK: - Integration Tests

    func testFullLifecycle() async throws {
        // Initialize
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter,
            heartbeatInterval: 0.1
        )

        XCTAssertTrue(client.isInitialized)

        // Update presence
        let presence = RichPresence(details: "Playing")
        try await client.update(presence: presence)

        // Wait for some heartbeat cycles
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Shutdown
        await client.shutdown()

        XCTAssertTrue(client.isShutdown)
        XCTAssertEqual(mockSDK.initializeCallCount, 1)
        XCTAssertEqual(mockSDK.updatePresenceCallCount, 1)
        XCTAssertGreaterThan(mockSDK.tickCallCount, 1, "Heartbeat should have called tick multiple times")
        XCTAssertEqual(mockSDK.shutdownCallCount, 1)
    }
}

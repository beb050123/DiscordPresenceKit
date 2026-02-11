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
            rateLimiter: mockRateLimiter
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
            rateLimiter: mockRateLimiter
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
            rateLimiter: mockRateLimiter
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

    func testUpdatePresenceRateLimited() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter
        )

        let presence = RichPresence(details: "Test")

        // First update should succeed
        try await client.update(presence: presence)
        XCTAssertEqual(mockSDK.updatePresenceCallCount, 1)

        // Immediate second update should be rate limited
        mockTime.advance(by: 0) // No time has passed

        do {
            try await client.update(presence: presence)
            XCTFail("Should have thrown rate limit error")
        } catch let error as DiscordError {
            switch error {
            case .rateLimitExceeded(let retryAfter):
                XCTAssertTrue(retryAfter > 0)
                XCTAssertTrue(retryAfter <= 15.0)
                // SDK should not be called again
                XCTAssertEqual(mockSDK.updatePresenceCallCount, 1, "SDK should not be called when rate limited")
            default:
                XCTFail("Expected rateLimitExceeded error, got: \(error)")
            }
        }
    }

    func testUpdatePresenceAfterShutdown() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter
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

    // MARK: - Tick

    func testTickSuccess() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter
        )

        try await client.tick()

        XCTAssertTrue(mockSDK.tickWasCalled)
        XCTAssertEqual(mockSDK.tickCallCount, 1)
    }

    func testMultipleTicks() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter
        )

        for _ in 0..<5 {
            try await client.tick()
        }

        XCTAssertEqual(mockSDK.tickCallCount, 5)
    }

    func testTickAfterShutdown() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter
        )

        await client.shutdown()

        do {
            try await client.tick()
            XCTFail("Should have thrown error after shutdown")
        } catch let error as DiscordError {
            switch error {
            case .updateFailed(let message):
                XCTAssertTrue(message?.contains("shut down") == true || message?.contains("shutdown") == true)
            default:
                XCTFail("Expected updateFailed error, got: \(error)")
            }
        }
    }

    func testTickWithSDKFailure() async throws {
        mockSDK.failTick(true, error: .tickFailed(message: "Callback error"))

        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter
        )

        do {
            try await client.tick()
            XCTFail("Should have thrown tick error")
        } catch let error as DiscordError {
            switch error {
            case .tickFailed:
                // The error contains the localized description from SDKError
                XCTAssertTrue(true)
            default:
                XCTFail("Expected tickFailed error, got: \(error)")
            }
        }
    }

    // MARK: - Shutdown

    func testShutdown() async throws {
        let client = try DiscordClientImpl(
            applicationID: "test-app",
            sdkClient: mockSDK,
            rateLimiter: mockRateLimiter
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
            rateLimiter: freshRateLimiter
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
            rateLimiter: mockRateLimiter
        )

        XCTAssertTrue(client.isInitialized)

        // Update presence
        let presence = RichPresence(details: "Playing")
        try await client.update(presence: presence)

        // Tick multiple times
        for _ in 0..<3 {
            try await client.tick()
        }

        // Shutdown
        await client.shutdown()

        XCTAssertTrue(client.isShutdown)
        XCTAssertEqual(mockSDK.initializeCallCount, 1)
        XCTAssertEqual(mockSDK.updatePresenceCallCount, 1)
        XCTAssertEqual(mockSDK.tickCallCount, 3)
        XCTAssertEqual(mockSDK.shutdownCallCount, 1)
    }
}

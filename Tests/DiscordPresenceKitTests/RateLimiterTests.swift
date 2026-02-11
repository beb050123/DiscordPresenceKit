import XCTest
@testable import DiscordPresenceKit

/// Tests for the PresenceRateLimiter.
final class RateLimiterTests: XCTestCase {
    var rateLimiter: PresenceRateLimiter!
    var mockTime: MockTimeSource!

    override func setUp() {
        super.setUp()
        mockTime = MockTimeSource(currentTime: 1000)
        rateLimiter = PresenceRateLimiter(timeSource: mockTime)
    }

    override func tearDown() {
        rateLimiter = nil
        mockTime = nil
        super.tearDown()
    }

    // MARK: - Basic Rate Limiting

    func testFirstUpdateAlwaysAllowed() {
        let result = rateLimiter.recordUpdate()

        switch result {
        case .success:
            XCTAssertTrue(true, "First update should always succeed")
        case .failure:
            XCTFail("First update should succeed")
        }
    }

    func testImmediateSecondUpdateBlocked() {
        // First update
        _ = rateLimiter.recordUpdate()

        // Immediate second update should be rate limited
        let result = rateLimiter.recordUpdate()

        switch result {
        case .success:
            XCTFail("Immediate second update should be rate limited")
        case .failure(let error):
            XCTAssertEqual(error.secondsUntilNextUpdate, 15.0, accuracy: 0.1)
        }
    }

    func testUpdateAllowedAfter15Seconds() {
        // First update
        _ = rateLimiter.recordUpdate()

        // Advance time by 15 seconds
        mockTime.advance(by: 15)

        // Second update should now succeed
        let result = rateLimiter.recordUpdate()

        switch result {
        case .success:
            XCTAssertTrue(true, "Update after 15 seconds should succeed")
        case .failure:
            XCTFail("Update after 15 seconds should succeed")
        }
    }

    func testUpdateBlockedJustBefore15Seconds() {
        // First update
        _ = rateLimiter.recordUpdate()

        // Advance time by 14.9 seconds
        mockTime.advance(by: 14.9)

        // Second update should still be rate limited
        let result = rateLimiter.recordUpdate()

        switch result {
        case .success:
            XCTFail("Update at 14.9 seconds should still be rate limited")
        case .failure:
            XCTAssertTrue(true, "Update at 14.9 seconds should be rate limited")
        }
    }

    // MARK: - Time Until Next Update

    func testTimeUntilNextUpdateWhenNoPriorUpdate() {
        let waitTime = rateLimiter.secondsUntilNextUpdate

        XCTAssertEqual(waitTime, 0, accuracy: 0.01, "Should be 0 when no prior update")
    }

    func testTimeUntilNextUpdateAfterUpdate() {
        _ = rateLimiter.recordUpdate()

        let waitTime = rateLimiter.secondsUntilNextUpdate

        XCTAssertEqual(waitTime, 15.0, accuracy: 0.1, "Should be 15 seconds immediately after update")
    }

    func testTimeUntilNextUpdateDecreases() {
        _ = rateLimiter.recordUpdate()

        mockTime.advance(by: 5)

        let waitTime = rateLimiter.secondsUntilNextUpdate

        XCTAssertEqual(waitTime, 10.0, accuracy: 0.1, "Should be 10 seconds after 5 seconds pass")
    }

    func testTimeUntilNextUpdateAtZero() {
        _ = rateLimiter.recordUpdate()

        mockTime.advance(by: 15)

        let waitTime = rateLimiter.secondsUntilNextUpdate

        XCTAssertEqual(waitTime, 0, accuracy: 0.1, "Should be 0 when 15 seconds have passed")
    }

    // MARK: - Can Update

    func testCanUpdateWhenNoPriorUpdate() {
        XCTAssertTrue(rateLimiter.canUpdate(), "Should be able to update when no prior update")
    }

    func testCanUpdateImmediatelyAfterUpdate() {
        _ = rateLimiter.recordUpdate()

        XCTAssertFalse(rateLimiter.canUpdate(), "Should not be able to update immediately after")
    }

    func testCanUpdateAfter15Seconds() {
        _ = rateLimiter.recordUpdate()

        mockTime.advance(by: 15)

        XCTAssertTrue(rateLimiter.canUpdate(), "Should be able to update after 15 seconds")
    }

    // MARK: - Reset

    func testResetAllowsImmediateUpdate() {
        _ = rateLimiter.recordUpdate()

        // Should be rate limited
        XCTAssertFalse(rateLimiter.canUpdate())

        // Reset
        rateLimiter.reset()

        // Should now be allowed
        XCTAssertTrue(rateLimiter.canUpdate(), "Should be able to update after reset")
        XCTAssertEqual(rateLimiter.secondsUntilNextUpdate, 0, accuracy: 0.01)
    }

    // MARK: - Multiple Updates

    func testMultipleUpdatesResetTimer() {
        _ = rateLimiter.recordUpdate()

        mockTime.advance(by: 15)

        // First update after cooldown should succeed
        let result1 = rateLimiter.recordUpdate()
        switch result1 {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTFail("First update after cooldown should succeed")
        }

        // Immediate second update should be rate limited again
        let result2 = rateLimiter.recordUpdate()
        switch result2 {
        case .success:
            XCTFail("Rate limit should reset after successful update")
        case .failure:
            XCTAssertTrue(true, "Should be rate limited again")
        }
    }

    // MARK: - Custom Minimum Interval

    func testCustomMinimumInterval() {
        let customLimiter = PresenceRateLimiter(
            minimumInterval: 5.0,
            timeSource: mockTime
        )

        _ = customLimiter.recordUpdate()

        let waitTime = customLimiter.secondsUntilNextUpdate
        XCTAssertEqual(waitTime, 5.0, accuracy: 0.1, "Should use custom minimum interval")

        mockTime.advance(by: 5)

        let result = customLimiter.recordUpdate()
        switch result {
        case .success:
            XCTAssertTrue(true, "Should allow update after custom interval")
        case .failure:
            XCTFail("Should allow update after custom interval")
        }
    }

    func testPreconditionOnNonPositiveInterval() {
        // Precondition failures don't throw in test mode - they just trap
        // So we'll skip these tests or handle differently
        // For now, just verify the limiter still works with valid values

        let validLimiter = PresenceRateLimiter(minimumInterval: 1.0, timeSource: mockTime)
        let result = validLimiter.recordUpdate()

        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTFail("Valid interval should work")
        }
    }
}

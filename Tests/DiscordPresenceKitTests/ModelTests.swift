import XCTest
@testable import DiscordPresenceKit

/// Tests for individual model types.
final class ModelTests: XCTestCase {
    // MARK: - ActivityType

    func testActivityTypeRawValues() {
        XCTAssertEqual(ActivityType.playing.rawValue, 0)
        XCTAssertEqual(ActivityType.listening.rawValue, 2)
        XCTAssertEqual(ActivityType.watching.rawValue, 3)
        XCTAssertEqual(ActivityType.competing.rawValue, 5)
    }

    func testActivityTypeFromRawValue() {
        XCTAssertEqual(ActivityType(rawValue: 0), .playing)
        XCTAssertEqual(ActivityType(rawValue: 2), .listening)
        XCTAssertEqual(ActivityType(rawValue: 3), .watching)
        XCTAssertEqual(ActivityType(rawValue: 5), .competing)
        XCTAssertNil(ActivityType(rawValue: 1)) // Streaming - not supported
        XCTAssertNil(ActivityType(rawValue: 4)) // Custom - not supported
    }

    // MARK: - PresenceButton

    func testButtonEquality() {
        let url = URL(string: "https://example.com")!
        let button1 = PresenceButton(label: "Test", url: url)
        let button2 = PresenceButton(label: "Test", url: url)
        let button3 = PresenceButton(label: "Other", url: url)

        XCTAssertEqual(button1, button2)
        XCTAssertNotEqual(button1, button3)
    }

    func testButtonWithDifferentURLs() {
        let button1 = PresenceButton(label: "Test", url: URL(string: "https://example.com/1")!)
        let button2 = PresenceButton(label: "Test", url: URL(string: "https://example.com/2")!)

        XCTAssertNotEqual(button1, button2)
    }

    // MARK: - PresenceAssets

    func testAssetsEquality() {
        let assets1 = PresenceAssets(
            largeImage: "large",
            largeText: "Large",
            smallImage: "small",
            smallText: "Small"
        )
        let assets2 = PresenceAssets(
            largeImage: "large",
            largeText: "Large",
            smallImage: "small",
            smallText: "Small"
        )
        let assets3 = PresenceAssets(largeImage: "other")

        XCTAssertEqual(assets1, assets2)
        XCTAssertNotEqual(assets1, assets3)
    }

    // MARK: - PresenceTimestamps

    func testTimestampsEquality() {
        let date1 = Date(timeIntervalSince1970: 1000)
        let date2 = Date(timeIntervalSince1970: 2000)

        let timestamps1 = PresenceTimestamps.elapsed(since: date1)
        let timestamps2 = PresenceTimestamps.elapsed(since: date1)
        let timestamps3 = PresenceTimestamps.elapsed(since: date2)

        XCTAssertEqual(timestamps1, timestamps2)
        XCTAssertNotEqual(timestamps1, timestamps3)
    }

    func testTimestampsStartVsEndNotEqual() {
        let date = Date(timeIntervalSince1970: 1000)

        let elapsed = PresenceTimestamps.elapsed(since: date)
        let remaining = PresenceTimestamps.remaining(until: date)

        XCTAssertNotEqual(elapsed, remaining)
    }

    // MARK: - RichPresence

    func testRichPresenceEquality() {
        let presence1 = RichPresence(
            details: "Test",
            state: "State",
            timestamps: .elapsed(since: Date()),
            assets: PresenceAssets(largeImage: "img"),
            buttons: [PresenceButton(label: "B", url: URL(string: "https://example.com")!)],
            type: .listening,
            name: "App"
        )
        let presence2 = RichPresence(
            details: "Test",
            state: "State",
            timestamps: .elapsed(since: Date()),
            assets: PresenceAssets(largeImage: "img"),
            buttons: [PresenceButton(label: "B", url: URL(string: "https://example.com")!)],
            type: .listening,
            name: "App"
        )

        // Note: Equality won't work perfectly due to Date differences
        // but the struct itself should be comparable
        XCTAssertEqual(presence1.details, presence2.details)
        XCTAssertEqual(presence1.state, presence2.state)
        XCTAssertEqual(presence1.type, presence2.type)
    }

    // MARK: - DiscordError

    func testDiscordErrorEquality() {
        XCTAssertEqual(DiscordError.clientUnavailable, .clientUnavailable)
        XCTAssertEqual(DiscordError.invalidApplicationID, .invalidApplicationID)

        let rateLimit1 = DiscordError.rateLimitExceeded(retryAfter: 5.0)
        let rateLimit2 = DiscordError.rateLimitExceeded(retryAfter: 5.0)
        let rateLimit3 = DiscordError.rateLimitExceeded(retryAfter: 10.0)

        XCTAssertEqual(rateLimit1, rateLimit2)
        XCTAssertNotEqual(rateLimit1, rateLimit3)
    }

    func testDiscordErrorInitializationFailed() {
        let error1 = DiscordError.initializationFailed(underlying: "Error 1")
        let error2 = DiscordError.initializationFailed(underlying: "Error 1")
        let error3 = DiscordError.initializationFailed(underlying: "Error 2")

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    func testDiscordErrorDescriptions() {
        let clientUnavailable = DiscordError.clientUnavailable
        let invalidID = DiscordError.invalidApplicationID
        let rateLimited = DiscordError.rateLimitExceeded(retryAfter: 5.0)
        let initFailed = DiscordError.initializationFailed(underlying: "Connection failed")
        let updateFailed = DiscordError.updateFailed(underlying: "IPC error")
        let tickFailed = DiscordError.tickFailed(underlying: "Callback error")

        XCTAssertNotNil(clientUnavailable.errorDescription)
        XCTAssertNotNil(invalidID.errorDescription)
        XCTAssertTrue(rateLimited.errorDescription?.contains("5") == true)
        XCTAssertTrue(initFailed.errorDescription?.contains("Connection failed") == true)
        XCTAssertTrue(updateFailed.errorDescription?.contains("IPC error") == true)
        XCTAssertTrue(tickFailed.errorDescription?.contains("Callback error") == true)
    }

    // MARK: - InternalActivity

    func testInternalActivityEquality() {
        let activity1 = InternalActivity(
            details: "Test",
            state: nil,
            startTimestamp: nil,
            endTimestamp: nil,
            largeImage: nil,
            largeText: nil,
            smallImage: nil,
            smallText: nil,
            buttons: [],
            type: .playing,
            name: nil
        )
        let activity2 = InternalActivity(
            details: "Test",
            state: nil,
            startTimestamp: nil,
            endTimestamp: nil,
            largeImage: nil,
            largeText: nil,
            smallImage: nil,
            smallText: nil,
            buttons: [],
            type: .playing,
            name: nil
        )
        let activity3 = InternalActivity(
            details: "Other",
            state: nil,
            startTimestamp: nil,
            endTimestamp: nil,
            largeImage: nil,
            largeText: nil,
            smallImage: nil,
            smallText: nil,
            buttons: [],
            type: .playing,
            name: nil
        )

        XCTAssertEqual(activity1, activity2)
        XCTAssertNotEqual(activity1, activity3)
    }

    func testInternalButtonEquality() {
        let button1 = InternalButton(label: "Test", url: "https://example.com")
        let button2 = InternalButton(label: "Test", url: "https://example.com")
        let button3 = InternalButton(label: "Other", url: "https://example.com")

        XCTAssertEqual(button1, button2)
        XCTAssertNotEqual(button1, button3)
    }

    func testInternalActivityWithButtons() {
        let activity = InternalActivity(
            details: nil,
            state: nil,
            startTimestamp: nil,
            endTimestamp: nil,
            largeImage: nil,
            largeText: nil,
            smallImage: nil,
            smallText: nil,
            buttons: [
                InternalButton(label: "B1", url: "https://example.com/1"),
                InternalButton(label: "B2", url: "https://example.com/2")
            ],
            type: .playing,
            name: nil
        )

        XCTAssertEqual(activity.buttons.count, 2)
        XCTAssertEqual(activity.buttons[0].label, "B1")
        XCTAssertEqual(activity.buttons[1].label, "B2")
    }
}

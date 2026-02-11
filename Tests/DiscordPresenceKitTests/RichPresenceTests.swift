import XCTest
@testable import DiscordPresenceKit

/// Tests for RichPresence model construction and field validation.
final class RichPresenceTests: XCTestCase {
    // MARK: - Basic Construction

    func testEmptyPresence() {
        let presence = RichPresence()

        XCTAssertNil(presence.details)
        XCTAssertNil(presence.state)
        XCTAssertNil(presence.timestamps)
        XCTAssertNil(presence.assets)
        XCTAssertTrue(presence.buttons.isEmpty)
        XCTAssertEqual(presence.type, .playing)
        XCTAssertNil(presence.name)
    }

    func testPresenceWithDetails() {
        let presence = RichPresence(details: "In a match")

        XCTAssertEqual(presence.details, "In a match")
        XCTAssertNil(presence.state)
    }

    func testPresenceWithState() {
        let presence = RichPresence(state: "Ranked – Solo Queue")

        XCTAssertEqual(presence.state, "Ranked – Solo Queue")
    }

    func testFullPresence() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600)

        let presence = RichPresence(
            details: "In a match",
            state: "Ranked – Solo Queue",
            timestamps: .elapsed(since: startDate),
            assets: PresenceAssets(
                largeImage: "map_image",
                largeText: "Summoner's Rift",
                smallImage: "rank_icon",
                smallText: "Gold II"
            ),
            buttons: [
                PresenceButton(label: "View Profile", url: URL(string: "https://example.com/profile")!),
                PresenceButton(label: "Join Game", url: URL(string: "https://example.com/join")!)
            ],
            type: .competing,
            name: "My Game"
        )

        XCTAssertEqual(presence.details, "In a match")
        XCTAssertEqual(presence.state, "Ranked – Solo Queue")
        XCTAssertEqual(presence.timestamps?.start, startDate)
        XCTAssertEqual(presence.assets?.largeImage, "map_image")
        XCTAssertEqual(presence.assets?.largeText, "Summoner's Rift")
        XCTAssertEqual(presence.assets?.smallImage, "rank_icon")
        XCTAssertEqual(presence.assets?.smallText, "Gold II")
        XCTAssertEqual(presence.buttons.count, 2)
        XCTAssertEqual(presence.buttons[0].label, "View Profile")
        XCTAssertEqual(presence.buttons[0].url.absoluteString, "https://example.com/profile")
        XCTAssertEqual(presence.buttons[1].label, "Join Game")
        XCTAssertEqual(presence.type, .competing)
        XCTAssertEqual(presence.name, "My Game")
    }

    // MARK: - Button Limits

    func testMaxTwoButtonsEnforced() {
        let buttons = [
            PresenceButton(label: "Button 1", url: URL(string: "https://example.com/1")!),
            PresenceButton(label: "Button 2", url: URL(string: "https://example.com/2")!),
            PresenceButton(label: "Button 3", url: URL(string: "https://example.com/3")!)
        ]

        let presence = RichPresence(buttons: buttons)

        XCTAssertEqual(presence.buttons.count, 2, "Should enforce maximum of 2 buttons")
        XCTAssertEqual(presence.buttons[0].label, "Button 1")
        XCTAssertEqual(presence.buttons[1].label, "Button 2")
    }

    func testEmptyButtonsArray() {
        let presence = RichPresence(buttons: [])

        XCTAssertTrue(presence.buttons.isEmpty)
    }

    func testSingleButton() {
        let button = PresenceButton(label: "View", url: URL(string: "https://example.com")!)
        let presence = RichPresence(buttons: [button])

        XCTAssertEqual(presence.buttons.count, 1)
        XCTAssertEqual(presence.buttons[0].label, "View")
    }

    // MARK: - Timestamps

    func testElapsedTimestamp() {
        let date = Date().addingTimeInterval(-600) // 10 minutes ago
        let presence = RichPresence(timestamps: .elapsed(since: date))

        XCTAssertEqual(presence.timestamps?.start, date)
        XCTAssertNil(presence.timestamps?.end)
    }

    func testRemainingTimestamp() {
        let date = Date().addingTimeInterval(300) // 5 minutes from now
        let presence = RichPresence(timestamps: .remaining(until: date))

        XCTAssertNil(presence.timestamps?.start)
        XCTAssertEqual(presence.timestamps?.end, date)
    }

    func testBothTimestampsPrefersStart() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600)

        // Use internal initializer directly to test mutual exclusivity
        let timestamps = PresenceTimestamps(start: startDate, end: endDate)

        XCTAssertNotNil(timestamps.start)
        XCTAssertNil(timestamps.end, "Should prefer start over end when both are provided")
    }

    // MARK: - Activity Types

    func testDefaultActivityType() {
        let presence = RichPresence()

        XCTAssertEqual(presence.type, .playing)
    }

    func testAllActivityTypes() {
        let types: [ActivityType] = [.playing, .listening, .watching, .competing]

        for type in types {
            let presence = RichPresence(type: type)
            XCTAssertEqual(presence.type, type)
        }
    }

    // MARK: - Assets

    func testAssetsWithOnlyLargeImage() {
        let assets = PresenceAssets(largeImage: "map", largeText: nil, smallImage: nil, smallText: nil)
        let presence = RichPresence(assets: assets)

        XCTAssertEqual(presence.assets?.largeImage, "map")
        XCTAssertNil(presence.assets?.largeText)
        XCTAssertNil(presence.assets?.smallImage)
        XCTAssertNil(presence.assets?.smallText)
    }

    func testAssetsWithAllFields() {
        let assets = PresenceAssets(
            largeImage: "large",
            largeText: "Large hover",
            smallImage: "small",
            smallText: "Small hover"
        )
        let presence = RichPresence(assets: assets)

        XCTAssertEqual(presence.assets?.largeImage, "large")
        XCTAssertEqual(presence.assets?.largeText, "Large hover")
        XCTAssertEqual(presence.assets?.smallImage, "small")
        XCTAssertEqual(presence.assets?.smallText, "Small hover")
    }

    func testNilAssets() {
        let presence = RichPresence(assets: nil)

        XCTAssertNil(presence.assets)
    }

    // MARK: - Clear Presence

    func testClearPresence() {
        let clearPresence = RichPresence.clear

        XCTAssertNil(clearPresence.details)
        XCTAssertNil(clearPresence.state)
        XCTAssertNil(clearPresence.timestamps)
        XCTAssertNil(clearPresence.assets)
        XCTAssertTrue(clearPresence.buttons.isEmpty)
        XCTAssertEqual(clearPresence.type, .playing)
        XCTAssertNil(clearPresence.name)
    }

    // MARK: - Internal Activity Conversion

    func testToInternalActivityConversion() {
        let startDate = Date(timeIntervalSince1970: 1234567890)
        let endDate = Date(timeIntervalSince1970: 1234571490)

        let presence = RichPresence(
            details: "Test details",
            state: "Test state",
            timestamps: .elapsed(since: startDate),
            assets: PresenceAssets(
                largeImage: "large_img",
                largeText: "Large hover",
                smallImage: "small_img",
                smallText: "Small hover"
            ),
            buttons: [
                PresenceButton(label: "Button 1", url: URL(string: "https://example.com")!)
            ],
            type: .listening,
            name: "Custom App"
        )

        let internalActivity = presence.toInternalActivity()

        XCTAssertEqual(internalActivity.details, "Test details")
        XCTAssertEqual(internalActivity.state, "Test state")
        XCTAssertEqual(internalActivity.startTimestamp, 1234567890.0)
        XCTAssertNil(internalActivity.endTimestamp)
        XCTAssertEqual(internalActivity.largeImage, "large_img")
        XCTAssertEqual(internalActivity.largeText, "Large hover")
        XCTAssertEqual(internalActivity.smallImage, "small_img")
        XCTAssertEqual(internalActivity.smallText, "Small hover")
        XCTAssertEqual(internalActivity.buttons.count, 1)
        XCTAssertEqual(internalActivity.buttons[0].label, "Button 1")
        XCTAssertEqual(internalActivity.buttons[0].url, "https://example.com")
        XCTAssertEqual(internalActivity.type, .listening)
        XCTAssertEqual(internalActivity.name, "Custom App")
    }

    func testToInternalActivityWithMinimalPresence() {
        let presence = RichPresence()
        let internalActivity = presence.toInternalActivity()

        XCTAssertNil(internalActivity.details)
        XCTAssertNil(internalActivity.state)
        XCTAssertNil(internalActivity.startTimestamp)
        XCTAssertNil(internalActivity.endTimestamp)
        XCTAssertNil(internalActivity.largeImage)
        XCTAssertNil(internalActivity.largeText)
        XCTAssertNil(internalActivity.smallImage)
        XCTAssertNil(internalActivity.smallText)
        XCTAssertTrue(internalActivity.buttons.isEmpty)
        XCTAssertEqual(internalActivity.type, .playing)
        XCTAssertNil(internalActivity.name)
    }
}

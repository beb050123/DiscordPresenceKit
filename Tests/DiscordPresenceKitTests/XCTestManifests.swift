import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RichPresenceTests.allTests),
        testCase(RateLimiterTests.allTests),
        testCase(DiscordClientTests.allTests),
        testCase(ModelTests.allTests)
    ]
}
#endif

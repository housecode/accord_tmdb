import XCTest
@testable import MovieApp

final class LoadErrorTests: XCTestCase {
    func testMessagesAndRetryRules() {
        let cases: [(APIError, LoadError)] = [
            (.noConnection, LoadError(message: "No internet connection", isRetryable: true)),
            (.timeout, LoadError(message: "The request took too long", isRetryable: true)),
            (.unauthorized, LoadError(message: "Access denied, check the API token", isRetryable: false)),
            (.notFound, LoadError(message: "Data not found", isRetryable: false)),
            (.rateLimited, LoadError(message: "Too many requests, try again later", isRetryable: true)),
            (.server(statusCode: 500), LoadError(message: "The server is having problems", isRetryable: true)),
            (.parsing, LoadError(message: "The data could not be processed", isRetryable: true))
        ]
        for (error, expected) in cases {
            XCTAssertEqual(LoadError(error), expected)
        }
    }

    func testUnknownErrorGetsGenericMessage() {
        XCTAssertEqual(LoadError(URLError(.badURL)).message, "Something went wrong")
    }
}

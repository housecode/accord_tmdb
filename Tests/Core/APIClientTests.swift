import XCTest
@testable import MovieApp

final class APIClientTests: XCTestCase {
    private struct Sample: Decodable, Equatable {
        let movieName: String
    }

    private func makeClient() -> URLSessionAPIClient {
        URLSessionAPIClient(baseURL: URL(string: "https://example.test/3") ?? URL(fileURLWithPath: "/"),
                            token: "secret", session: URLProtocolStub.makeSession())
    }

    private func assertFails(_ expected: APIError, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            let _: Sample = try await makeClient().send(Endpoint(path: "/x"))
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? APIError, expected, file: file, line: line)
        }
    }

    func testDecodesSnakeCaseSuccessResponse() async throws {
        URLProtocolStub.stub = .response(status: 200, data: Data(#"{"movie_name":"Heat"}"#.utf8))
        let sample: Sample = try await makeClient().send(Endpoint(path: "/x"))
        XCTAssertEqual(sample, Sample(movieName: "Heat"))
    }

    func testSendsBearerTokenAndQuery() async throws {
        URLProtocolStub.stub = .response(status: 200, data: Data(#"{"movie_name":"Heat"}"#.utf8))
        let _: Sample = try await makeClient().send(.movies(genreID: 28, page: 2))
        let request = URLProtocolStub.lastRequest
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer secret")
        XCTAssertEqual(request?.url?.path, "/3/discover/movie")
        XCTAssertEqual(request?.url?.query, "with_genres=28&page=2")
        XCTAssertEqual(request?.timeoutInterval, 30)
    }

    func testMapsStatusCodes() async {
        let cases: [(Int, APIError)] = [(401, .unauthorized), (404, .notFound), (429, .rateLimited),
                                        (500, .server(statusCode: 500)), (503, .server(statusCode: 503)),
                                        (418, .unexpectedStatus(418))]
        for (status, expected) in cases {
            URLProtocolStub.stub = .response(status: status, data: Data())
            await assertFails(expected)
        }
    }

    func testBrokenJSONIsParsingError() async {
        URLProtocolStub.stub = .response(status: 200, data: Data("not json".utf8))
        await assertFails(.parsing)
    }

    func testMissingRequiredFieldIsParsingError() async {
        URLProtocolStub.stub = .response(status: 200, data: Data("{}".utf8))
        await assertFails(.parsing)
    }

    func testTransportFailuresAreMapped() async {
        URLProtocolStub.stub = .failure(.notConnectedToInternet)
        await assertFails(.noConnection)
        URLProtocolStub.stub = .failure(.timedOut)
        await assertFails(.timeout)
    }

    func testCancellationIsNotReportedAsAnError() async {
        URLProtocolStub.stub = .failure(.cancelled)
        do {
            let _: Sample = try await makeClient().send(Endpoint(path: "/x"))
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }
}

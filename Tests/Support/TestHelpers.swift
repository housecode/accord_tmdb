import Foundation
@testable import MovieApp

func settle() async {
    try? await Task.sleep(nanoseconds: 30_000_000)
}

final class MockAPIClient: APIClient {
    var handler: (Endpoint) async throws -> Any = { _ in throw APIError.invalidRequest }
    private(set) var requested: [Endpoint] = []

    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        requested.append(endpoint)
        let value = try await handler(endpoint)
        guard let typed = value as? Response else { throw APIError.parsing }
        return typed
    }
}

func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(type, from: Data(json.utf8))
}

func movieDTOs(_ ids: Range<Int>) -> [MovieDTO] {
    ids.map { MovieDTO(id: $0, title: "Movie \($0)", posterPath: nil, voteAverage: 7.5, releaseDate: "2020-01-01") }
}

func reviewDTOs(_ ids: Range<Int>) -> [ReviewDTO] {
    ids.map { ReviewDTO(id: "r\($0)", author: "A\($0)", authorDetails: nil, content: "text", createdAt: nil) }
}

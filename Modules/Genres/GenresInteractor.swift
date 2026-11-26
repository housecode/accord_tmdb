import Foundation

struct GenreListDTO: Decodable {
    let genres: [GenreDTO]
}

@MainActor
final class GenresInteractor: GenresInteractorProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchGenres() async throws -> [Genre] {
        let list: GenreListDTO = try await apiClient.send(.genres)
        return list.genres.map(\.entity)
    }
}

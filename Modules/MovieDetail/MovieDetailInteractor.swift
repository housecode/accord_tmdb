import Foundation

@MainActor
final class MovieDetailInteractor: MovieDetailInteractorProtocol {
    private let movieID: Int
    private let apiClient: APIClient

    init(movieID: Int, apiClient: APIClient) {
        self.movieID = movieID
        self.apiClient = apiClient
    }

    func fetchDetail() async throws -> MovieDetail {
        let dto: MovieDetailDTO = try await apiClient.send(.movieDetail(id: movieID))
        return dto.entity
    }

    func fetchTrailerKey() async throws -> String? {
        let list: VideoListDTO = try await apiClient.send(.videos(movieID: movieID))
        return TrailerSelector.pick(from: list.results.map(\.entity))?.key
    }
}

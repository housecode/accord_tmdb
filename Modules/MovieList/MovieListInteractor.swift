import Foundation

@MainActor
final class MovieListInteractor: MovieListInteractorProtocol {
    private let genreID: Int
    private let apiClient: APIClient
    private var paging = PagingState()
    /// Bumped on every restart so a late response of the previous run is never shown.
    private var generation = 0

    init(genreID: Int, apiClient: APIClient) {
        self.genreID = genreID
        self.apiClient = apiClient
    }

    func restart() {
        generation += 1
        paging.reset()
    }

    func loadNextPage() async throws -> MoviePage? {
        guard let page = paging.beginLoad() else { return nil }
        let requestGeneration = generation
        do {
            let dto: PageDTO<MovieDTO> = try await apiClient.send(.movies(genreID: genreID, page: page))
            guard requestGeneration == generation else { throw CancellationError() }
            paging.finish(page: page, totalPages: dto.totalPages, receivedItems: dto.results.count)
            return MoviePage(movies: dto.results.map(\.entity), hasMore: !paging.reachedEnd)
        } catch {
            if requestGeneration == generation { paging.fail() }
            throw error
        }
    }
}

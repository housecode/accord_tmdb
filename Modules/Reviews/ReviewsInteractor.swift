import Foundation

@MainActor
final class ReviewsInteractor: ReviewsInteractorProtocol {
    private let movieID: Int
    private let apiClient: APIClient
    private var paging = PagingState()
    /// Bumped on every restart so a late response of the previous run is never shown.
    private var generation = 0

    init(movieID: Int, apiClient: APIClient) {
        self.movieID = movieID
        self.apiClient = apiClient
    }

    func restart() {
        generation += 1
        paging.reset()
    }

    func loadNextPage() async throws -> ReviewPage? {
        guard let page = paging.beginLoad() else { return nil }
        let requestGeneration = generation
        do {
            let dto: PageDTO<ReviewDTO> = try await apiClient.send(.reviews(movieID: movieID, page: page))
            guard requestGeneration == generation else { throw CancellationError() }
            paging.finish(page: page, totalPages: dto.totalPages, receivedItems: dto.results.count)
            return ReviewPage(reviews: dto.results.map(\.entity), hasMore: !paging.reachedEnd)
        } catch {
            if requestGeneration == generation { paging.fail() }
            throw error
        }
    }
}

import XCTest
@testable import MovieApp

@MainActor
final class MovieListInteractorTests: XCTestCase {
    private let client = MockAPIClient()

    private func makeInteractor() -> MovieListInteractor {
        MovieListInteractor(genreID: 28, apiClient: client)
    }

    private func serve(totalPages: Int, perPage: Int = 20) {
        client.handler = { endpoint in
            let page = Int(endpoint.queryItems.first { $0.name == "page" }?.value ?? "") ?? 0
            let start = (page - 1) * perPage
            return PageDTO(page: page, totalPages: totalPages, results: movieDTOs(start..<(start + perPage)))
        }
    }

    func testRequestsGenreAndPageNumbers() async throws {
        serve(totalPages: 3)
        let interactor = makeInteractor()
        _ = try await interactor.loadNextPage()
        _ = try await interactor.loadNextPage()
        XCTAssertEqual(client.requested, [.movies(genreID: 28, page: 1), .movies(genreID: 28, page: 2)])
    }

    func testStopsAfterLastPage() async throws {
        serve(totalPages: 2)
        let interactor = makeInteractor()
        let first = try await interactor.loadNextPage()
        let second = try await interactor.loadNextPage()
        let third = try await interactor.loadNextPage()
        XCTAssertEqual(first?.hasMore, true)
        XCTAssertEqual(second?.hasMore, false)
        XCTAssertNil(third)
        XCTAssertEqual(client.requested.count, 2)
    }

    func testOnlyOneRequestInFlight() async throws {
        client.handler = { _ in
            try await Task.sleep(nanoseconds: 50_000_000)
            return PageDTO(page: 1, totalPages: 5, results: movieDTOs(0..<20))
        }
        let interactor = makeInteractor()
        async let first = interactor.loadNextPage()
        async let second = interactor.loadNextPage()
        let results = try await [first, second]
        XCTAssertEqual(results.compactMap { $0 }.count, 1)
        XCTAssertEqual(client.requested.count, 1)
    }

    func testFailedPageIsRetriedNotSkipped() async throws {
        serve(totalPages: 3)
        let interactor = makeInteractor()
        _ = try await interactor.loadNextPage()
        client.handler = { _ in throw APIError.server(statusCode: 500) }
        do {
            _ = try await interactor.loadNextPage()
            XCTFail("Expected failure")
        } catch {
            XCTAssertEqual(error as? APIError, .server(statusCode: 500))
        }
        serve(totalPages: 3)
        _ = try await interactor.loadNextPage()
        XCTAssertEqual(client.requested.map { $0.queryItems.last?.value }, ["1", "2", "2"])
    }

    func testRestartStartsAtPageOneAgain() async throws {
        serve(totalPages: 3)
        let interactor = makeInteractor()
        _ = try await interactor.loadNextPage()
        _ = try await interactor.loadNextPage()
        interactor.restart()
        _ = try await interactor.loadNextPage()
        XCTAssertEqual(client.requested.map { $0.queryItems.last?.value }, ["1", "2", "1"])
    }

    func testLateResponseOfRestartedRunIsDiscarded() async throws {
        client.handler = { _ in
            try await Task.sleep(nanoseconds: 60_000_000)
            return PageDTO(page: 1, totalPages: 5, results: movieDTOs(0..<20))
        }
        let interactor = makeInteractor()
        async let stale: MoviePage? = interactor.loadNextPage()
        try await Task.sleep(nanoseconds: 10_000_000)
        interactor.restart()
        do {
            _ = try await stale
            XCTFail("Expected the old run to be discarded")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        let fresh = try await interactor.loadNextPage()
        XCTAssertEqual(fresh?.movies.count, 20)
    }

    func testMapsDTOToEntityWithMissingFields() throws {
        let dto = try decode(MovieDTO.self, #"{"id":1,"title":"No Extras","poster_path":null,"vote_average":null}"#)
        XCTAssertEqual(dto.entity, Movie(id: 1, title: "No Extras", posterPath: nil, voteAverage: nil, releaseDate: nil))
    }

    func testMissingTitleFailsDecoding() {
        XCTAssertThrowsError(try decode(MovieDTO.self, #"{"id":1}"#))
    }
}

@MainActor
final class MovieListPresenterTests: XCTestCase {
    private final class StubInteractor: MovieListInteractorProtocol {
        var results: [Result<MoviePage?, Error>] = []
        private(set) var calls = 0
        private(set) var restarts = 0
        func restart() { restarts += 1 }
        func loadNextPage() async throws -> MoviePage? {
            calls += 1
            return try results.isEmpty ? nil : results.removeFirst().get()
        }
    }

    private final class SpyView: MovieListViewProtocol {
        var states: [MovieListViewState] = []
        var kinds: [String] {
            states.map {
                switch $0 {
                case .loading: "loading"
                case .content: "content"
                case .empty: "empty"
                case .error: "error"
                }
            }
        }
        var lastContent: (items: [MovieCellViewModel], footer: ListFooter)? {
            for state in states.reversed() {
                if case .content(let items, let footer) = state { return (items, footer) }
            }
            return nil
        }
        var endRefreshingCalls = 0
        func endRefreshing() { endRefreshingCalls += 1 }
        func render(_ state: MovieListViewState) { states.append(state) }
    }

    private final class SpyRouter: MovieListRouterProtocol {
        var movieID: Int?
        func showDetail(movieID: Int) { self.movieID = movieID }
    }

    private let interactor = StubInteractor()
    private let view = SpyView()
    private var retained: AnyObject?
    private let router = SpyRouter()

    private func makePresenter() -> MovieListPresenter {
        let presenter = MovieListPresenter(genre: Genre(id: 28, name: "Action"), interactor: interactor, router: router)
        presenter.view = view
        retained = presenter
        return presenter
    }

    private func page(_ ids: Range<Int>, hasMore: Bool = true) -> MoviePage {
        MoviePage(movies: movieDTOs(ids).map(\.entity), hasMore: hasMore)
    }

    func testRefreshReplacesListWithoutLoadingScreenAndEndsRefreshing() async {
        interactor.results = [.success(page(0..<20)), .success(page(100..<120))]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.refresh()
        await settle()
        XCTAssertEqual(interactor.restarts, 1)
        XCTAssertEqual(view.lastContent?.items.first?.id, 100)
        XCTAssertEqual(view.lastContent?.items.count, 20)
        XCTAssertEqual(view.endRefreshingCalls, 1)
        XCTAssertEqual(view.kinds.filter { $0 == "loading" }.count, 1)
    }

    func testRetryAfterFailedRefreshReplacesTheOldList() async {
        interactor.results = [.success(page(0..<20)), .failure(APIError.timeout), .success(page(100..<120))]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.refresh()
        await settle()
        presenter.retry()
        await settle()
        XCTAssertEqual(view.lastContent?.items.map(\.id), Array(100..<120))
        XCTAssertEqual(view.lastContent?.footer, .loadingMore)
    }

    func testFailedRefreshKeepsListAndShowsRetryRow() async {
        interactor.results = [.success(page(0..<20)), .failure(APIError.timeout)]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.refresh()
        await settle()
        XCTAssertEqual(view.lastContent?.items.count, 20)
        XCTAssertEqual(view.lastContent?.footer, .retry("The request took too long"))
        XCTAssertEqual(view.endRefreshingCalls, 1)
    }

    func testTitleIsGenreName() {
        XCTAssertEqual(makePresenter().title, "Action")
    }

    func testFirstPageShowsContentWithLoadingFooter() async {
        interactor.results = [.success(page(0..<20))]
        makePresenter().viewDidLoad()
        await settle()
        XCTAssertEqual(view.kinds, ["loading", "content"])
        XCTAssertEqual(view.lastContent?.items.count, 20)
        XCTAssertEqual(view.lastContent?.footer, .loadingMore)
        XCTAssertEqual(view.lastContent?.items.first?.subtitle, "★ 7.5 · 2020")
    }

    func testEmptyFirstPageShowsNoMovies() async {
        interactor.results = [.success(page(0..<0, hasMore: false))]
        makePresenter().viewDidLoad()
        await settle()
        XCTAssertEqual(view.kinds, ["loading", "empty"])
    }

    func testFirstPageFailureShowsErrorAndRetryLoads() async {
        interactor.results = [.failure(APIError.noConnection), .success(page(0..<5, hasMore: false))]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        XCTAssertEqual(view.kinds.last, "error")
        presenter.retry()
        await settle()
        XCTAssertEqual(view.kinds.suffix(2), ["loading", "content"])
        XCTAssertEqual(view.lastContent?.footer, ListFooter.none)
    }

    func testScrollingNearEndRequestsNextPageAndDeduplicates() async {
        interactor.results = [.success(page(0..<20)), .success(page(15..<40, hasMore: false))]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.willDisplayItem(at: 5)
        await settle()
        XCTAssertEqual(interactor.calls, 1)
        presenter.willDisplayItem(at: 15)
        await settle()
        XCTAssertEqual(interactor.calls, 2)
        XCTAssertEqual(view.lastContent?.items.count, 40)
        XCTAssertEqual(Set(view.lastContent?.items.map(\.id) ?? []).count, 40)
    }

    func testFollowUpFailureKeepsItemsAndShowsRetryRow() async {
        interactor.results = [.success(page(0..<20)), .failure(APIError.server(statusCode: 500)), .success(page(20..<30, hasMore: false))]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.willDisplayItem(at: 19)
        await settle()
        XCTAssertEqual(view.lastContent?.items.count, 20)
        XCTAssertEqual(view.lastContent?.footer, .retry("The server is having problems"))

        presenter.willDisplayItem(at: 19)
        await settle()
        XCTAssertEqual(interactor.calls, 2, "no automatic request while the retry row is shown")

        presenter.retry()
        await settle()
        XCTAssertEqual(view.lastContent?.items.count, 30)
        XCTAssertEqual(view.lastContent?.footer, ListFooter.none)
    }

    func testSelectingMovieRoutesToDetail() async {
        makePresenter().didSelectMovie(id: 99)
        XCTAssertEqual(router.movieID, 99)
    }
}

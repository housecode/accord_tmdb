import XCTest
@testable import MovieApp

@MainActor
final class GenresTests: XCTestCase {
    private final class StubInteractor: GenresInteractorProtocol {
        var result: Result<[Genre], Error> = .success([])
        func fetchGenres() async throws -> [Genre] { try result.get() }
    }

    private final class SpyView: GenresViewProtocol {
        var states: [String] = []
        var rows: [GenreRowViewModel] = []
        var error: LoadError?
        var endRefreshingCalls = 0
        func endRefreshing() { endRefreshingCalls += 1 }
        func render(_ state: ScreenState<[GenreRowViewModel]>) {
            switch state {
            case .loading: states.append("loading")
            case .content(let items): states.append("content"); rows = items
            case .empty: states.append("empty")
            case .error(let loadError): states.append("error"); error = loadError
            }
        }
    }

    private final class SpyRouter: GenresRouterProtocol {
        var selected: Genre?
        func showMovies(for genre: Genre) { selected = genre }
    }

    private let interactor = StubInteractor()
    private let view = SpyView()
    private var retained: AnyObject?
    private let router = SpyRouter()

    private func makePresenter() -> GenresPresenter {
        let presenter = GenresPresenter(interactor: interactor, router: router)
        presenter.view = view
        retained = presenter
        return presenter
    }

    func testInteractorMapsGenreList() async throws {
        let client = MockAPIClient()
        let list = try decode(GenreListDTO.self, #"{"genres":[{"id":28,"name":"Action"}]}"#)
        client.handler = { _ in list }
        let genres = try await GenresInteractor(apiClient: client).fetchGenres()
        XCTAssertEqual(genres, [Genre(id: 28, name: "Action")])
        XCTAssertEqual(client.requested, [.genres])
    }

    func testLoadsGenresThenShowsContent() async {
        interactor.result = .success([Genre(id: 1, name: "Drama")])
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        XCTAssertEqual(view.states, ["loading", "content"])
        XCTAssertEqual(view.rows, [GenreRowViewModel(id: 1, name: "Drama")])
    }

    func testEmptyListShowsEmptyState() async {
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        XCTAssertEqual(view.states, ["loading", "empty"])
    }

    func testFailureShowsErrorAndRetrySucceeds() async {
        interactor.result = .failure(APIError.noConnection)
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        XCTAssertEqual(view.error?.message, "No internet connection")

        interactor.result = .success([Genre(id: 1, name: "Drama")])
        presenter.retry()
        await settle()
        XCTAssertEqual(view.states.last, "content")
    }

    func testRefreshReloadsWithoutLoadingScreenAndEndsRefreshing() async {
        interactor.result = .success([Genre(id: 1, name: "Drama")])
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        interactor.result = .success([Genre(id: 1, name: "Drama"), Genre(id: 2, name: "Comedy")])
        presenter.refresh()
        await settle()
        XCTAssertEqual(view.states, ["loading", "content", "content"])
        XCTAssertEqual(view.rows.count, 2)
        XCTAssertEqual(view.endRefreshingCalls, 1)
    }

    func testFailedRefreshShowsErrorAndEndsRefreshing() async {
        interactor.result = .success([Genre(id: 1, name: "Drama")])
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        interactor.result = .failure(APIError.noConnection)
        presenter.refresh()
        await settle()
        XCTAssertEqual(view.states.last, "error")
        XCTAssertEqual(view.endRefreshingCalls, 1)
    }

    func testSelectingGenreRoutesToMovies() async {
        interactor.result = .success([Genre(id: 7, name: "Comedy")])
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.didSelectGenre(id: 7)
        XCTAssertEqual(router.selected, Genre(id: 7, name: "Comedy"))
    }
}

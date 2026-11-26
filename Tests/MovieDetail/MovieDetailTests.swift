import XCTest
@testable import MovieApp

final class TrailerSelectorTests: XCTestCase {
    private func video(_ key: String, site: String = "YouTube", type: String = "Trailer", official: Bool = false) -> Video {
        Video(key: key, site: site, type: type, official: official, name: nil)
    }

    func testPrefersOfficialTrailer() {
        let picked = TrailerSelector.pick(from: [video("a"), video("b", official: true)])
        XCTAssertEqual(picked?.key, "b")
    }

    func testFallsBackToAnyYouTubeTrailer() {
        let picked = TrailerSelector.pick(from: [video("clip", type: "Clip"), video("a")])
        XCTAssertEqual(picked?.key, "a")
    }

    func testFallsBackToAnyYouTubeVideo() {
        let picked = TrailerSelector.pick(from: [video("v", site: "Vimeo"), video("clip", type: "Clip")])
        XCTAssertEqual(picked?.key, "clip")
    }

    func testReturnsNilWithoutYouTubeVideo() {
        XCTAssertNil(TrailerSelector.pick(from: [video("v", site: "Vimeo")]))
        XCTAssertNil(TrailerSelector.pick(from: []))
    }

    func testIgnoresEntriesWithEmptyKey() {
        XCTAssertNil(TrailerSelector.pick(from: [video("")]))
    }

    func testDecodesVideoWithoutOfficialFlag() throws {
        let list = try decode(VideoListDTO.self, #"{"results":[{"key":"k","site":"YouTube","type":"Trailer"}]}"#)
        XCTAssertEqual(list.results.first?.entity.official, false)
    }

    func testDecodesDetailWithMissingOptionals() throws {
        let dto = try decode(MovieDetailDTO.self, #"{"id":3,"title":"Bare","genres":null,"runtime":null}"#)
        XCTAssertEqual(dto.entity.genres, [])
        XCTAssertNil(dto.entity.runtime)
    }
}

@MainActor
final class MovieDetailPresenterTests: XCTestCase {
    private final class StubInteractor: MovieDetailInteractorProtocol {
        var detail: Result<MovieDetail, Error> = .failure(APIError.notFound)
        var trailer: Result<String?, Error> = .success(nil)
        func fetchDetail() async throws -> MovieDetail { try detail.get() }
        func fetchTrailerKey() async throws -> String? { try trailer.get() }
    }

    private final class SpyView: MovieDetailViewProtocol {
        var model: MovieDetailViewModel?
        var error: LoadError?
        var trailerStates: [TrailerButtonState] = []
        func render(_ state: ScreenState<MovieDetailViewModel>) {
            if case .content(let value) = state { model = value }
            if case .error(let value) = state { error = value }
        }
        func renderTrailer(_ state: TrailerButtonState) { trailerStates.append(state) }
    }

    private final class SpyRouter: MovieDetailRouterProtocol {
        var reviewsMovieID: Int?
        var trailerKey: String?
        func showReviews(movieID: Int) { reviewsMovieID = movieID }
        func showTrailer(videoKey: String, movieTitle: String) { trailerKey = videoKey }
    }

    private let interactor = StubInteractor()
    private let view = SpyView()
    private var retained: AnyObject?
    private let router = SpyRouter()

    private let sample = MovieDetail(id: 5, title: "Heat", tagline: "", overview: nil, releaseDate: "1995-12-15", runtime: 170,
                                     genres: [Genre(id: 1, name: "Crime"), Genre(id: 2, name: "Drama")],
                                     voteAverage: 8.2, voteCount: 100, backdropPath: nil, posterPath: "/p.jpg")

    private func makePresenter() -> MovieDetailPresenter {
        let presenter = MovieDetailPresenter(movieID: 5, interactor: interactor, router: router)
        presenter.view = view
        retained = presenter
        return presenter
    }

    func testFormatsDetailAndHidesEmptyOptionals() async {
        interactor.detail = .success(sample)
        makePresenter().viewDidLoad()
        await settle()
        XCTAssertEqual(view.model?.metaLine, "★ 8.2 (100) · 2h 50m · 1995-12-15")
        XCTAssertEqual(view.model?.genresLine, "Crime, Drama")
        XCTAssertNil(view.model?.tagline)
        XCTAssertEqual(view.model?.overview, "No overview available")
        XCTAssertNotNil(view.model?.imageURL)
    }

    func testTrailerFailureDoesNotAffectDetail() async {
        interactor.detail = .success(sample)
        interactor.trailer = .failure(APIError.timeout)
        makePresenter().viewDidLoad()
        await settle()
        XCTAssertNotNil(view.model)
        XCTAssertEqual(view.trailerStates.last, .failed("The request took too long"))
    }

    func testDetailFailureDoesNotAffectTrailer() async {
        interactor.detail = .failure(APIError.notFound)
        interactor.trailer = .success("abc")
        makePresenter().viewDidLoad()
        await settle()
        XCTAssertEqual(view.error?.message, "Data not found")
        XCTAssertEqual(view.trailerStates.last, .available)
    }

    func testNoTrailerShowsUnavailable() async {
        interactor.detail = .success(sample)
        makePresenter().viewDidLoad()
        await settle()
        XCTAssertEqual(view.trailerStates.last, .unavailable)
    }

    func testTrailerTapRoutesWithKeyAndReviewsWithMovieID() async {
        interactor.detail = .success(sample)
        interactor.trailer = .success("abc")
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.didTapTrailer()
        presenter.didTapReviews()
        XCTAssertEqual(router.trailerKey, "abc")
        XCTAssertEqual(router.reviewsMovieID, 5)
    }

    func testRetryTrailerReloadsVideos() async {
        interactor.detail = .success(sample)
        interactor.trailer = .failure(APIError.noConnection)
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        interactor.trailer = .success("xyz")
        presenter.retryTrailer()
        await settle()
        XCTAssertEqual(view.trailerStates.last, .available)
    }
}

@MainActor
final class TrailerPresenterTests: XCTestCase {
    private final class SpyView: TrailerViewProtocol {
        var loaded: URL?
        var failure: String?
        func load(embedURL: URL) { loaded = embedURL }
        func showPlaybackFailure(message: String) { failure = message }
    }

    private final class SpyRouter: TrailerRouterProtocol {
        var opened: URL?
        func openExternally(_ url: URL) { opened = url }
    }

    func testLoadsEmbedURL() {
        let view = SpyView()
        let presenter = TrailerPresenter(videoKey: "abc", movieTitle: "Heat", router: SpyRouter())
        presenter.view = view
        presenter.viewDidLoad()
        XCTAssertEqual(view.loaded?.host, "www.youtube.com")
        XCTAssertEqual(view.loaded?.path, "/embed/abc")
    }

    func testPlaybackFailureOpensYouTube() {
        let view = SpyView()
        let router = SpyRouter()
        let presenter = TrailerPresenter(videoKey: "abc", movieTitle: "Heat", router: router)
        presenter.view = view
        presenter.playbackFailed()
        XCTAssertEqual(router.opened?.absoluteString, "https://www.youtube.com/watch?v=abc")
        XCTAssertNotNil(view.failure)
    }
}

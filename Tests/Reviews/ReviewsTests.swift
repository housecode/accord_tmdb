import XCTest
@testable import MovieApp

@MainActor
final class ReviewsInteractorTests: XCTestCase {
    func testPagesAndStops() async throws {
        let client = MockAPIClient()
        client.handler = { endpoint in
            let page = Int(endpoint.queryItems.first { $0.name == "page" }?.value ?? "") ?? 0
            return PageDTO(page: page, totalPages: 2, results: reviewDTOs(0..<3))
        }
        let interactor = ReviewsInteractor(movieID: 9, apiClient: client)
        let first = try await interactor.loadNextPage()
        let second = try await interactor.loadNextPage()
        let third = try await interactor.loadNextPage()
        XCTAssertEqual(first?.hasMore, true)
        XCTAssertEqual(second?.hasMore, false)
        XCTAssertNil(third)
        XCTAssertEqual(client.requested, [.reviews(movieID: 9, page: 1), .reviews(movieID: 9, page: 2)])
    }

    func testReviewWithoutRatingOrAuthorDecodes() throws {
        let dto = try decode(ReviewDTO.self, #"{"id":"x","author":null,"author_details":{"rating":null},"content":"Great"}"#)
        XCTAssertEqual(dto.entity, Review(id: "x", author: "Anonymous", rating: nil, content: "Great", createdAt: nil))
    }

    func testReviewWithoutAuthorDetailsDecodes() throws {
        let dto = try decode(ReviewDTO.self, #"{"id":"x","author":"Sam","content":"Fine"}"#)
        XCTAssertNil(dto.entity.rating)
    }
}

@MainActor
final class ReviewsPresenterTests: XCTestCase {
    private final class StubInteractor: ReviewsInteractorProtocol {
        var results: [Result<ReviewPage?, Error>] = []
        private(set) var restarts = 0
        func restart() { restarts += 1 }
        func loadNextPage() async throws -> ReviewPage? {
            try results.isEmpty ? nil : results.removeFirst().get()
        }
    }

    private final class SpyView: ReviewsViewProtocol {
        var states: [ReviewsViewState] = []
        var content: (items: [ReviewCellViewModel], footer: ListFooter)? {
            for state in states.reversed() {
                if case .content(let items, let footer) = state { return (items, footer) }
            }
            return nil
        }
        var emptyMessage: String? {
            for state in states.reversed() {
                if case .empty(let message) = state { return message }
            }
            return nil
        }
        var endRefreshingCalls = 0
        func endRefreshing() { endRefreshingCalls += 1 }
        func render(_ state: ReviewsViewState) { states.append(state) }
    }

    private let interactor = StubInteractor()
    private let view = SpyView()
    private var retained: AnyObject?

    private func makePresenter() -> ReviewsPresenter {
        let presenter = ReviewsPresenter(interactor: interactor)
        presenter.view = view
        retained = presenter
        return presenter
    }

    private func page(_ reviews: [Review], hasMore: Bool = false) -> ReviewPage {
        ReviewPage(reviews: reviews, hasMore: hasMore)
    }

    func testRefreshReplacesReviewsAndEndsRefreshing() async {
        let old = [Review(id: "old", author: "A", rating: nil, content: "c", createdAt: nil)]
        let fresh = [Review(id: "new", author: "B", rating: nil, content: "c", createdAt: nil)]
        interactor.results = [.success(page(old)), .success(page(fresh))]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.refresh()
        await settle()
        XCTAssertEqual(interactor.restarts, 1)
        XCTAssertEqual(view.content?.items.map(\.id), ["new"])
        XCTAssertEqual(view.endRefreshingCalls, 1)
    }

    func testRetryAfterFailedRefreshReplacesTheOldReviews() async {
        let old = [Review(id: "old", author: "A", rating: nil, content: "c", createdAt: nil)]
        let fresh = [Review(id: "new", author: "B", rating: nil, content: "c", createdAt: nil)]
        interactor.results = [.success(page(old)), .failure(APIError.timeout), .success(page(fresh))]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.refresh()
        await settle()
        presenter.retry()
        await settle()
        XCTAssertEqual(view.content?.items.map(\.id), ["new"])
        XCTAssertEqual(view.content?.footer, ListFooter.none)
    }

    func testFailedRefreshKeepsReviewsAndShowsRetryRow() async {
        let old = [Review(id: "old", author: "A", rating: nil, content: "c", createdAt: nil)]
        interactor.results = [.success(page(old)), .failure(APIError.timeout)]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.refresh()
        await settle()
        XCTAssertEqual(view.content?.items.map(\.id), ["old"])
        XCTAssertEqual(view.content?.footer, .retry("The request took too long"))
        XCTAssertEqual(view.endRefreshingCalls, 1)
    }

    func testNoReviewsShowsEmptyMessage() async {
        interactor.results = [.success(page([]))]
        makePresenter().viewDidLoad()
        await settle()
        XCTAssertEqual(view.emptyMessage, "No reviews yet")
    }

    func testReviewWithoutRatingHasNoRatingText() async {
        interactor.results = [.success(page([Review(id: "1", author: "Sam", rating: nil, content: "ok", createdAt: nil)]))]
        makePresenter().viewDidLoad()
        await settle()
        XCTAssertNil(view.content?.items.first?.ratingText)
        XCTAssertEqual(view.content?.items.first?.isTruncatable, false)
    }

    func testRatingAndDateAreFormatted() async {
        let review = Review(id: "1", author: "Sam", rating: 8, content: "ok", createdAt: "2021-06-23T15:58:36.123Z")
        interactor.results = [.success(page([review]))]
        makePresenter().viewDidLoad()
        await settle()
        XCTAssertEqual(view.content?.items.first?.ratingText, "★ 8.0")
        XCTAssertNotNil(view.content?.items.first?.dateText)
    }

    func testLongReviewIsTruncatableAndExpands() async {
        let long = String(repeating: "word ", count: 80)
        interactor.results = [.success(page([Review(id: "1", author: "Sam", rating: nil, content: long, createdAt: nil)]))]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        XCTAssertEqual(view.content?.items.first?.isTruncatable, true)
        XCTAssertEqual(view.content?.items.first?.isExpanded, false)
        presenter.toggleExpanded(id: "1")
        XCTAssertEqual(view.content?.items.first?.isExpanded, true)
        presenter.toggleExpanded(id: "1")
        XCTAssertEqual(view.content?.items.first?.isExpanded, false)
    }

    func testFollowUpFailureKeepsReviewsAndRetries() async {
        let first = (0..<20).map { Review(id: "\($0)", author: "A", rating: nil, content: "c", createdAt: nil) }
        let second = [Review(id: "20", author: "A", rating: nil, content: "c", createdAt: nil)]
        interactor.results = [.success(page(first, hasMore: true)), .failure(APIError.timeout), .success(page(second))]
        let presenter = makePresenter()
        presenter.viewDidLoad()
        await settle()
        presenter.willDisplayItem(at: 19)
        await settle()
        XCTAssertEqual(view.content?.items.count, 20)
        XCTAssertEqual(view.content?.footer, .retry("The request took too long"))
        presenter.retry()
        await settle()
        XCTAssertEqual(view.content?.items.count, 21)
        XCTAssertEqual(view.content?.footer, ListFooter.none)
    }
}

import Foundation

@MainActor
final class ReviewsPresenter: ReviewsPresenterProtocol {
    static let truncationThreshold = 240

    weak var view: ReviewsViewProtocol?
    private let interactor: ReviewsInteractorProtocol
    private var reviews: [Review] = []
    private var seenIDs = Set<String>()
    private var expandedIDs = Set<String>()
    private var hasMore = true
    private var failedMessage: String?
    /// While refreshing, the shown list stays until the first fresh page arrives.
    private var isRefreshing = false
    private var loadTask: Task<Void, Never>?
    private var loadToken = UUID()

    var title: String { "Reviews" }

    init(interactor: ReviewsInteractorProtocol) {
        self.interactor = interactor
    }

    func viewDidLoad() {
        view?.render(.loading)
        loadNextPage()
    }

    func retry() {
        failedMessage = nil
        if reviews.isEmpty {
            view?.render(.loading)
        } else {
            renderContent()
        }
        loadNextPage()
    }

    func refresh() {
        loadTask?.cancel()
        loadTask = nil
        isRefreshing = true
        failedMessage = nil
        hasMore = true
        interactor.restart()
        loadNextPage()
    }

    func willDisplayItem(at index: Int) {
        guard failedMessage == nil, PagingState.shouldPrefetch(displayedIndex: index, itemCount: reviews.count) else { return }
        loadNextPage()
    }

    func toggleExpanded(id: String) {
        if !expandedIDs.insert(id).inserted { expandedIDs.remove(id) }
        renderContent()
    }

    func viewDidClose() {
        loadTask?.cancel()
    }

    private func loadNextPage() {
        guard loadTask == nil else { return }
        let token = UUID()
        loadToken = token
        loadTask = Task { [weak self] in
            guard let self else { return }
            defer { if loadToken == token { loadTask = nil } }
            do {
                guard let page = try await interactor.loadNextPage(), loadToken == token else { return }
                append(page)
            } catch is CancellationError {
                return
            } catch {
                guard loadToken == token else { return }
                handleFailure(error)
            }
        }
        if !reviews.isEmpty { renderContent() }
    }

    private func append(_ page: ReviewPage) {
        if isRefreshing {
            reviews = []
            seenIDs = []
            finishRefreshing()
        }
        hasMore = page.hasMore
        for review in page.reviews where seenIDs.insert(review.id).inserted {
            reviews.append(review)
        }
        if reviews.isEmpty {
            view?.render(.empty("No reviews yet"))
        } else {
            renderContent()
        }
    }

    private func finishRefreshing() {
        guard isRefreshing else { return }
        isRefreshing = false
        view?.endRefreshing()
    }

    private func handleFailure(_ error: Error) {
        // Stay in refresh mode so Retry replaces the old list instead of merging fresh pages into it.
        if isRefreshing { view?.endRefreshing() }
        let loadError = LoadError(error)
        if reviews.isEmpty {
            view?.render(.error(loadError))
        } else {
            failedMessage = loadError.message
            renderContent()
        }
    }

    private func renderContent() {
        let footer: ListFooter
        if let failedMessage {
            footer = .retry(failedMessage)
        } else if hasMore {
            footer = .loadingMore
        } else {
            footer = .none
        }
        view?.render(.content(items: reviews.map(makeViewModel), footer: footer))
    }

    private func makeViewModel(_ review: Review) -> ReviewCellViewModel {
        ReviewCellViewModel(id: review.id,
                            author: review.author,
                            ratingText: review.rating.flatMap { $0 > 0 ? "★ \(String(format: "%.1f", $0))" : nil },
                            content: review.content,
                            dateText: Self.formatDate(review.createdAt),
                            isTruncatable: review.content.count > Self.truncationThreshold,
                            isExpanded: expandedIDs.contains(review.id))
    }

    private static func formatDate(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        guard let date = withFraction.date(from: raw) ?? plain.date(from: raw) else { return nil }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

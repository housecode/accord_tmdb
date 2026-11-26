import Foundation

@MainActor
final class MovieListPresenter: MovieListPresenterProtocol {
    weak var view: MovieListViewProtocol?
    private let genre: Genre
    private let interactor: MovieListInteractorProtocol
    private let router: MovieListRouterProtocol
    private var items: [MovieCellViewModel] = []
    private var seenIDs = Set<Int>()
    private var hasMore = true
    private var failedMessage: String?
    /// While refreshing, the shown list stays until the first fresh page arrives.
    private var isRefreshing = false
    private var loadTask: Task<Void, Never>?
    private var loadToken = UUID()

    var title: String { genre.name }

    init(genre: Genre, interactor: MovieListInteractorProtocol, router: MovieListRouterProtocol) {
        self.genre = genre
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        view?.render(.loading)
        loadNextPage()
    }

    func retry() {
        failedMessage = nil
        if items.isEmpty {
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
        guard failedMessage == nil, PagingState.shouldPrefetch(displayedIndex: index, itemCount: items.count) else { return }
        loadNextPage()
    }

    func didSelectMovie(id: Int) {
        router.showDetail(movieID: id)
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
        if !items.isEmpty { renderContent() }
    }

    private func append(_ page: MoviePage) {
        if isRefreshing {
            items = []
            seenIDs = []
            finishRefreshing()
        }
        hasMore = page.hasMore
        for movie in page.movies where seenIDs.insert(movie.id).inserted {
            items.append(makeViewModel(movie))
        }
        if items.isEmpty {
            view?.render(.empty("No movies"))
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
        if items.isEmpty {
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
        view?.render(.content(items: items, footer: footer))
    }

    private func makeViewModel(_ movie: Movie) -> MovieCellViewModel {
        MovieCellViewModel(id: movie.id,
                           title: movie.title,
                           subtitle: MovieFormatter.subtitle(rating: movie.voteAverage, releaseDate: movie.releaseDate),
                           posterURL: ImageURL.make(path: movie.posterPath, size: .poster))
    }
}

import Foundation

@MainActor
final class GenresPresenter: GenresPresenterProtocol {
    weak var view: GenresViewProtocol?
    private let interactor: GenresInteractorProtocol
    private let router: GenresRouterProtocol
    private var genres: [Genre] = []
    private var loadTask: Task<Void, Never>?

    let title = "Genres"

    init(interactor: GenresInteractorProtocol, router: GenresRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        load()
    }

    func retry() {
        load()
    }

    func refresh() {
        load(showsLoading: false)
    }

    func didSelectGenre(id: Int) {
        guard let genre = genres.first(where: { $0.id == id }) else { return }
        router.showMovies(for: genre)
    }

    func viewDidClose() {
        loadTask?.cancel()
    }

    private func load(showsLoading: Bool = true) {
        loadTask?.cancel()
        if showsLoading { view?.render(.loading) }
        loadTask = Task { [weak self] in
            guard let self else { return }
            defer { if !showsLoading { view?.endRefreshing() } }
            do {
                let loaded = try await interactor.fetchGenres()
                genres = loaded
                if loaded.isEmpty {
                    view?.render(.empty("No genres available"))
                } else {
                    view?.render(.content(loaded.map { GenreRowViewModel(id: $0.id, name: $0.name) }))
                }
            } catch is CancellationError {
                return
            } catch {
                view?.render(.error(LoadError(error)))
            }
        }
    }
}

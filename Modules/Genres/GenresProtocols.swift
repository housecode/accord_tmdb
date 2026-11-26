import Foundation

@MainActor
protocol GenresViewProtocol: AnyObject {
    func render(_ state: ScreenState<[GenreRowViewModel]>)
    func endRefreshing()
}

@MainActor
protocol GenresPresenterProtocol: AnyObject {
    var title: String { get }
    func viewDidLoad()
    func retry()
    func refresh()
    func didSelectGenre(id: Int)
    func viewDidClose()
}

@MainActor
protocol GenresInteractorProtocol: AnyObject {
    func fetchGenres() async throws -> [Genre]
}

@MainActor
protocol GenresRouterProtocol: AnyObject {
    func showMovies(for genre: Genre)
}

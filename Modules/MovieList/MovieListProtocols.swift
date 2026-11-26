import Foundation

@MainActor
protocol MovieListViewProtocol: AnyObject {
    func render(_ state: MovieListViewState)
    func endRefreshing()
}

@MainActor
protocol MovieListPresenterProtocol: AnyObject {
    var title: String { get }
    func viewDidLoad()
    func retry()
    func refresh()
    func willDisplayItem(at index: Int)
    func didSelectMovie(id: Int)
    func viewDidClose()
}

@MainActor
protocol MovieListInteractorProtocol: AnyObject {
    /// Starts again from page 1; a response still in flight for the old run is discarded.
    func restart()
    /// Returns nil when a request is already active or the last page was reached.
    func loadNextPage() async throws -> MoviePage?
}

@MainActor
protocol MovieListRouterProtocol: AnyObject {
    func showDetail(movieID: Int)
}

import Foundation

@MainActor
protocol ReviewsViewProtocol: AnyObject {
    func render(_ state: ReviewsViewState)
    func endRefreshing()
}

@MainActor
protocol ReviewsPresenterProtocol: AnyObject {
    var title: String { get }
    func viewDidLoad()
    func retry()
    func refresh()
    func willDisplayItem(at index: Int)
    func toggleExpanded(id: String)
    func viewDidClose()
}

@MainActor
protocol ReviewsInteractorProtocol: AnyObject {
    /// Starts again from page 1; a response still in flight for the old run is discarded.
    func restart()
    /// Returns nil when a request is already active or the last page was reached.
    func loadNextPage() async throws -> ReviewPage?
}

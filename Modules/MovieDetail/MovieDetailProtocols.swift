import Foundation

@MainActor
protocol MovieDetailViewProtocol: AnyObject {
    func render(_ state: ScreenState<MovieDetailViewModel>)
    func renderTrailer(_ state: TrailerButtonState)
}

@MainActor
protocol MovieDetailPresenterProtocol: AnyObject {
    func viewDidLoad()
    func retry()
    func retryTrailer()
    func didTapTrailer()
    func didTapReviews()
    func viewDidClose()
}

@MainActor
protocol MovieDetailInteractorProtocol: AnyObject {
    func fetchDetail() async throws -> MovieDetail
    /// The YouTube key of the best video, or nil when the movie has none.
    func fetchTrailerKey() async throws -> String?
}

@MainActor
protocol MovieDetailRouterProtocol: AnyObject {
    func showReviews(movieID: Int)
    func showTrailer(videoKey: String, movieTitle: String)
}

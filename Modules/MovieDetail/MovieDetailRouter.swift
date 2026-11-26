import UIKit

@MainActor
final class MovieDetailRouter: MovieDetailRouterProtocol {
    weak var viewController: UIViewController?
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func showReviews(movieID: Int) {
        let next = ReviewsBuilder.build(movieID: movieID, dependencies: dependencies)
        viewController?.navigationController?.pushViewController(next, animated: true)
    }

    func showTrailer(videoKey: String, movieTitle: String) {
        let next = TrailerBuilder.build(videoKey: videoKey, movieTitle: movieTitle)
        viewController?.navigationController?.pushViewController(next, animated: true)
    }
}

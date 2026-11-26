import UIKit

@MainActor
final class MovieListRouter: MovieListRouterProtocol {
    weak var viewController: UIViewController?
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func showDetail(movieID: Int) {
        let next = MovieDetailBuilder.build(movieID: movieID, dependencies: dependencies)
        viewController?.navigationController?.pushViewController(next, animated: true)
    }
}

import UIKit

@MainActor
final class GenresRouter: GenresRouterProtocol {
    weak var viewController: UIViewController?
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func showMovies(for genre: Genre) {
        let next = MovieListBuilder.build(genre: genre, dependencies: dependencies)
        viewController?.navigationController?.pushViewController(next, animated: true)
    }
}

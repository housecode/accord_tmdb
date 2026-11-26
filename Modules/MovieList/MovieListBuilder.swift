import UIKit

@MainActor
enum MovieListBuilder {
    static func build(genre: Genre, dependencies: AppDependencies) -> UIViewController {
        let interactor = MovieListInteractor(genreID: genre.id, apiClient: dependencies.apiClient)
        let router = MovieListRouter(dependencies: dependencies)
        let presenter = MovieListPresenter(genre: genre, interactor: interactor, router: router)
        let view = MovieListViewController(presenter: presenter)
        presenter.view = view
        router.viewController = view
        return view
    }
}

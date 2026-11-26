import UIKit

@MainActor
enum MovieDetailBuilder {
    static func build(movieID: Int, dependencies: AppDependencies) -> UIViewController {
        let interactor = MovieDetailInteractor(movieID: movieID, apiClient: dependencies.apiClient)
        let router = MovieDetailRouter(dependencies: dependencies)
        let presenter = MovieDetailPresenter(movieID: movieID, interactor: interactor, router: router)
        let view = MovieDetailViewController(presenter: presenter)
        presenter.view = view
        router.viewController = view
        return view
    }
}

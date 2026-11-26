import UIKit

@MainActor
enum GenresBuilder {
    static func build(dependencies: AppDependencies) -> UIViewController {
        let interactor = GenresInteractor(apiClient: dependencies.apiClient)
        let router = GenresRouter(dependencies: dependencies)
        let presenter = GenresPresenter(interactor: interactor, router: router)
        let view = GenresViewController(presenter: presenter)
        presenter.view = view
        router.viewController = view
        return view
    }
}

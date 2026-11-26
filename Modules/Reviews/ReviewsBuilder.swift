import UIKit

@MainActor
enum ReviewsBuilder {
    static func build(movieID: Int, dependencies: AppDependencies) -> UIViewController {
        let interactor = ReviewsInteractor(movieID: movieID, apiClient: dependencies.apiClient)
        let presenter = ReviewsPresenter(interactor: interactor)
        let view = ReviewsViewController(presenter: presenter)
        presenter.view = view
        return view
    }
}

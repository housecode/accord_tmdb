import UIKit

@MainActor
enum TrailerBuilder {
    static func build(videoKey: String, movieTitle: String) -> UIViewController {
        let presenter = TrailerPresenter(videoKey: videoKey, movieTitle: movieTitle, router: TrailerRouter())
        let view = TrailerViewController(presenter: presenter)
        presenter.view = view
        return view
    }
}

import Foundation

enum TrailerEmbed {
    /// YouTube rejects embeds that have no referrer, so the player page is served from a fixed https origin.
    static let origin = "https://movie-app.example.com"
}

@MainActor
final class TrailerPresenter: TrailerPresenterProtocol {
    weak var view: TrailerViewProtocol?
    private let videoKey: String
    private let movieTitle: String
    private let router: TrailerRouterProtocol

    var title: String { movieTitle }

    var embedURL: URL? {
        URL(string: "https://www.youtube.com/embed/\(videoKey)?playsinline=1&autoplay=1&rel=0&enablejsapi=1&origin=\(TrailerEmbed.origin)")
    }

    var watchURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(videoKey)")
    }

    init(videoKey: String, movieTitle: String, router: TrailerRouterProtocol) {
        self.videoKey = videoKey
        self.movieTitle = movieTitle
        self.router = router
    }

    func viewDidLoad() {
        guard let embedURL else {
            playbackFailed()
            return
        }
        view?.load(embedURL: embedURL)
    }

    func playbackFailed() {
        view?.showPlaybackFailure(message: "The trailer could not be played here")
        openInYouTube()
    }

    func openInYouTube() {
        guard let watchURL else { return }
        router.openExternally(watchURL)
    }
}

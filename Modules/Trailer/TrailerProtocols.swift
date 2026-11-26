import Foundation

@MainActor
protocol TrailerViewProtocol: AnyObject {
    func load(embedURL: URL)
    func showPlaybackFailure(message: String)
}

@MainActor
protocol TrailerPresenterProtocol: AnyObject {
    var title: String { get }
    func viewDidLoad()
    func playbackFailed()
    func openInYouTube()
}

@MainActor
protocol TrailerRouterProtocol: AnyObject {
    func openExternally(_ url: URL)
}

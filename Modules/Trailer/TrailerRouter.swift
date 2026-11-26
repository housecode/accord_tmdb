import UIKit

@MainActor
final class TrailerRouter: TrailerRouterProtocol {
    func openExternally(_ url: URL) {
        UIApplication.shared.open(url)
    }
}

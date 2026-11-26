import Foundation

enum ScreenState<Content> {
    case loading
    case content(Content)
    case empty(String)
    case error(LoadError)
}

enum ListFooter: Equatable {
    case none
    case loadingMore
    case retry(String)
}

import Foundation

/// Guards endless scrolling: one active request, no repeated page, stop at the last page.
struct PagingState {
    static let prefetchDistance = 5

    private(set) var nextPage = 1
    private(set) var totalPages: Int?
    private(set) var isLoading = false
    private(set) var reachedEnd = false
    private var loadedPages = Set<Int>()

    var isFirstPage: Bool { nextPage == 1 }

    /// Returns the page to request, or nil when a request is active, the page is loaded, or the end was reached.
    mutating func beginLoad() -> Int? {
        guard !isLoading, !reachedEnd, !loadedPages.contains(nextPage) else { return nil }
        isLoading = true
        return nextPage
    }

    mutating func finish(page: Int, totalPages: Int, receivedItems: Int) {
        isLoading = false
        loadedPages.insert(page)
        self.totalPages = totalPages
        nextPage = page + 1
        if receivedItems == 0 || page >= totalPages {
            reachedEnd = true
        }
    }

    /// Keeps `nextPage` so a retry repeats the failed page.
    mutating func fail() {
        isLoading = false
    }

    mutating func reset() {
        self = PagingState()
    }

    static func shouldPrefetch(displayedIndex: Int, itemCount: Int) -> Bool {
        displayedIndex >= itemCount - prefetchDistance
    }
}

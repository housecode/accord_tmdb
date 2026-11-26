import XCTest
@testable import MovieApp

final class PagingStateTests: XCTestCase {
    func testFirstLoadStartsAtPageOne() {
        var state = PagingState()
        XCTAssertEqual(state.beginLoad(), 1)
    }

    func testSecondLoadWhileActiveIsRejected() {
        var state = PagingState()
        _ = state.beginLoad()
        XCTAssertNil(state.beginLoad())
    }

    func testPagesAdvanceOneByOne() {
        var state = PagingState()
        _ = state.beginLoad()
        state.finish(page: 1, totalPages: 3, receivedItems: 20)
        XCTAssertEqual(state.beginLoad(), 2)
    }

    func testFailureRepeatsSamePage() {
        var state = PagingState()
        _ = state.beginLoad()
        state.finish(page: 1, totalPages: 3, receivedItems: 20)
        _ = state.beginLoad()
        state.fail()
        XCTAssertEqual(state.beginLoad(), 2)
    }

    func testStopsAtLastPage() {
        var state = PagingState()
        _ = state.beginLoad()
        state.finish(page: 1, totalPages: 1, receivedItems: 5)
        XCTAssertTrue(state.reachedEnd)
        XCTAssertNil(state.beginLoad())
    }

    func testStopsOnEmptyPage() {
        var state = PagingState()
        _ = state.beginLoad()
        state.finish(page: 1, totalPages: 9, receivedItems: 0)
        XCTAssertNil(state.beginLoad())
    }

    func testPrefetchTriggersInsideLastFiveItems() {
        XCTAssertFalse(PagingState.shouldPrefetch(displayedIndex: 14, itemCount: 20))
        XCTAssertTrue(PagingState.shouldPrefetch(displayedIndex: 15, itemCount: 20))
    }
}

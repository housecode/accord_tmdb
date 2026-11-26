import XCTest
@testable import MovieApp

final class FormattingTests: XCTestCase {
    func testSubtitleCombinesRatingAndYear() {
        XCTAssertEqual(MovieFormatter.subtitle(rating: 7.456, releaseDate: "2021-05-04"), "★ 7.5 · 2021")
    }

    func testSubtitleSkipsMissingParts() {
        XCTAssertEqual(MovieFormatter.subtitle(rating: 0, releaseDate: ""), "")
        XCTAssertEqual(MovieFormatter.subtitle(rating: nil, releaseDate: "1999-01-01"), "1999")
    }

    func testImageURLBuildsFromPath() {
        XCTAssertEqual(ImageURL.make(path: "/a.jpg", size: .poster)?.absoluteString, "https://image.tmdb.org/t/p/w342/a.jpg")
    }

    func testImageURLIsNilForEmptyPath() {
        XCTAssertNil(ImageURL.make(path: nil, size: .poster))
        XCTAssertNil(ImageURL.make(path: "", size: .poster))
    }
}

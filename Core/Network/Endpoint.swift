import Foundation

struct Endpoint: Equatable {
    let path: String
    var queryItems: [URLQueryItem] = []

    static let genres = Endpoint(path: "/genre/movie/list")

    static func movies(genreID: Int, page: Int) -> Endpoint {
        Endpoint(path: "/discover/movie", queryItems: [
            URLQueryItem(name: "with_genres", value: String(genreID)),
            URLQueryItem(name: "page", value: String(page))
        ])
    }

    static func movieDetail(id: Int) -> Endpoint {
        Endpoint(path: "/movie/\(id)")
    }

    static func reviews(movieID: Int, page: Int) -> Endpoint {
        Endpoint(path: "/movie/\(movieID)/reviews", queryItems: [
            URLQueryItem(name: "page", value: String(page))
        ])
    }

    static func videos(movieID: Int) -> Endpoint {
        Endpoint(path: "/movie/\(movieID)/videos")
    }
}

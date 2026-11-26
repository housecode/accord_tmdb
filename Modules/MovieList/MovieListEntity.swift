import Foundation

struct Movie: Equatable {
    let id: Int
    let title: String
    let posterPath: String?
    let voteAverage: Double?
    let releaseDate: String?
}

struct MoviePage: Equatable {
    let movies: [Movie]
    let hasMore: Bool
}

struct MovieDTO: Decodable {
    let id: Int
    let title: String
    let posterPath: String?
    let voteAverage: Double?
    let releaseDate: String?

    var entity: Movie {
        Movie(id: id, title: title, posterPath: posterPath, voteAverage: voteAverage, releaseDate: releaseDate)
    }
}

struct MovieCellViewModel: Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let posterURL: URL?
}

enum MovieListViewState {
    case loading
    case content(items: [MovieCellViewModel], footer: ListFooter)
    case empty(String)
    case error(LoadError)
}

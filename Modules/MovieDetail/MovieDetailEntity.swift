import Foundation

struct MovieDetail: Equatable {
    let id: Int
    let title: String
    let tagline: String?
    let overview: String?
    let releaseDate: String?
    let runtime: Int?
    let genres: [Genre]
    let voteAverage: Double?
    let voteCount: Int?
    let backdropPath: String?
    let posterPath: String?
}

struct MovieDetailDTO: Decodable {
    let id: Int
    let title: String
    let tagline: String?
    let overview: String?
    let releaseDate: String?
    let runtime: Int?
    let genres: [GenreDTO]?
    let voteAverage: Double?
    let voteCount: Int?
    let backdropPath: String?
    let posterPath: String?

    var entity: MovieDetail {
        MovieDetail(id: id, title: title, tagline: tagline, overview: overview, releaseDate: releaseDate,
                    runtime: runtime, genres: (genres ?? []).map(\.entity), voteAverage: voteAverage,
                    voteCount: voteCount, backdropPath: backdropPath, posterPath: posterPath)
    }
}

struct Video: Equatable {
    let key: String
    let site: String
    let type: String
    let official: Bool
    let name: String?
}

struct VideoDTO: Decodable {
    let key: String
    let site: String
    let type: String
    let official: Bool?
    let name: String?

    var entity: Video {
        Video(key: key, site: site, type: type, official: official ?? false, name: name)
    }
}

struct VideoListDTO: Decodable {
    let results: [VideoDTO]
}

enum TrailerSelector {
    /// Official YouTube trailer, else any YouTube trailer, else any YouTube video.
    static func pick(from videos: [Video]) -> Video? {
        let youTube = videos.filter { $0.site.caseInsensitiveCompare("YouTube") == .orderedSame && !$0.key.isEmpty }
        let trailers = youTube.filter { $0.type.caseInsensitiveCompare("Trailer") == .orderedSame }
        return trailers.first(where: \.official) ?? trailers.first ?? youTube.first
    }
}

struct MovieDetailViewModel: Equatable {
    let title: String
    let tagline: String?
    let overview: String
    let metaLine: String
    let genresLine: String?
    let imageURL: URL?
}

enum TrailerButtonState: Equatable {
    case loading
    case available
    case unavailable
    case failed(String)
}

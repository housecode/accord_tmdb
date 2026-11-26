import Foundation

enum ImageSize: String {
    case poster = "w342"
    case backdrop = "w780"
}

enum ImageURL {
    static func make(path: String?, size: ImageSize) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: AppConfig.imageBaseURL + size.rawValue + path)
    }
}

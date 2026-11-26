import Foundation

struct AppConfig {
    let apiBaseURL: URL
    let accessToken: String

    static let imageBaseURL = "https://image.tmdb.org/t/p/"

    static func load(from bundle: Bundle = .main) -> AppConfig {
        let token = bundle.object(forInfoDictionaryKey: "TMDBAccessToken") as? String ?? ""
        return AppConfig(apiBaseURL: URL(string: "https://api.themoviedb.org/3") ?? URL(fileURLWithPath: "/"),
                         accessToken: token)
    }
}

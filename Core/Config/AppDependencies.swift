import Foundation

struct AppDependencies {
    let apiClient: APIClient

    static func live(config: AppConfig = .load()) -> AppDependencies {
        AppDependencies(apiClient: URLSessionAPIClient(baseURL: config.apiBaseURL, token: config.accessToken))
    }
}

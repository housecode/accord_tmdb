import Foundation

struct LoadError: Equatable {
    let message: String
    let isRetryable: Bool
}

extension LoadError {
    init(_ error: Error) {
        guard let apiError = error as? APIError else {
            self.init(message: "Something went wrong", isRetryable: true)
            return
        }
        switch apiError {
        case .noConnection:
            self.init(message: "No internet connection", isRetryable: true)
        case .timeout:
            self.init(message: "The request took too long", isRetryable: true)
        case .unauthorized:
            self.init(message: "Access denied, check the API token", isRetryable: false)
        case .notFound:
            self.init(message: "Data not found", isRetryable: false)
        case .rateLimited:
            self.init(message: "Too many requests, try again later", isRetryable: true)
        case .server:
            self.init(message: "The server is having problems", isRetryable: true)
        case .parsing:
            self.init(message: "The data could not be processed", isRetryable: true)
        case .unexpectedStatus, .invalidRequest:
            self.init(message: "Something went wrong", isRetryable: true)
        }
    }
}

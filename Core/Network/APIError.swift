import Foundation

enum APIError: Error, Equatable {
    case noConnection
    case timeout
    case unauthorized
    case notFound
    case rateLimited
    case server(statusCode: Int)
    case unexpectedStatus(Int)
    case parsing
    case invalidRequest
}

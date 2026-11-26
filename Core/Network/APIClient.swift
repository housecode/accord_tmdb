import Foundation

protocol APIClient {
    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response
}

struct URLSessionAPIClient: APIClient {
    static let defaultTimeout: TimeInterval = 30

    private let baseURL: URL
    private let token: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL, token: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func send<Response: Decodable>(_ endpoint: Endpoint) async throws -> Response {
        let request = try makeRequest(for: endpoint)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw Self.map(transportError: error)
        }
        try Self.validate(response)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.parsing
        }
    }

    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidRequest
        }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems
        guard let url = components.url else { throw APIError.invalidRequest }
        var request = URLRequest(url: url, timeoutInterval: Self.defaultTimeout)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.parsing }
        switch http.statusCode {
        case 200..<300: return
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        case 429: throw APIError.rateLimited
        case 500..<600: throw APIError.server(statusCode: http.statusCode)
        default: throw APIError.unexpectedStatus(http.statusCode)
        }
    }

    private static func map(transportError error: Error) -> Error {
        guard let urlError = error as? URLError else { return error }
        switch urlError.code {
        case .cancelled:
            return CancellationError()
        case .timedOut:
            return APIError.timeout
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dataNotAllowed:
            return APIError.noConnection
        default:
            return APIError.noConnection
        }
    }
}

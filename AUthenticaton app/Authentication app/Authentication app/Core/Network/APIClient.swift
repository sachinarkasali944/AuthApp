import Foundation

/// HTTP methods supported by the API client
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Defines the contract for an API Endpoint.
/// Adheres to Open/Closed Principle (OCP): New endpoints can be added without modifying the network client.
public protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    var queryItems: [URLQueryItem]? { get }
}

public extension Endpoint {
    var headers: [String: String]? { nil }
    var body: Data? { nil }
    var queryItems: [URLQueryItem]? { nil }
}

/// Network-specific errors
public enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    case clientError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .noData:
            return "No data received from the server."
        case .decodingError(let details):
            return "Failed to decode response: \(details)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Please try again later.")"
        case .unauthorized:
            return "Unauthorized access. Please log in again."
        case .clientError(let message):
            return message
        }
    }
}

/// Abstract contract for making network requests.
/// Adheres to Dependency Inversion Principle (DIP).
public protocol APIClient {
    func request<T: Decodable>(endpoint: Endpoint) async throws -> T
}

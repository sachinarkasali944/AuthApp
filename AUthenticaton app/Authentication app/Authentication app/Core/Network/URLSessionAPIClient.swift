import Foundation

/// Concrete implementation of APIClient using Apple's URLSession with async/await.
/// Also features an optional mock simulator mode for offline interview demos & unit tests.
public final class URLSessionAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    public var isMockMode: Bool

    public init(
        baseURL: URL = URL(string: "https://api.authdemo.example.com/v1")!,
        session: URLSession = .shared,
        jsonDecoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }(),
        isMockMode: Bool = true
    ) {
        self.baseURL = baseURL
        self.session = session
        self.jsonDecoder = jsonDecoder
        self.isMockMode = isMockMode
    }

    public func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        // If mock mode is active, simulate network request with mock data
        if isMockMode {
            return try await simulateMockResponse(for: endpoint)
        }

        // 1. Build URL
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let queryItems = endpoint.queryItems {
            components?.queryItems = queryItems
        }

        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL
        }

        // 2. Build URLRequest
        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body = endpoint.body {
            request.httpBody = body
        }

        // 3. Execute via URLSession
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.clientError(error.localizedDescription)
        }

        // 4. Validate HTTP status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try jsonDecoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error.localizedDescription)
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            let serverMsg = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: serverMsg)
        }
    }

    // MARK: - Mock Handler for Offline Demonstrations
    private func simulateMockResponse<T: Decodable>(for endpoint: Endpoint) async throws -> T {
        // Simulate realistic network latency
        try await Task.sleep(nanoseconds: 600_000_000)

        // Mock Login
        if endpoint.path.contains("/auth/login") {
            let mockJSON = """
            {
                "user": {
                    "id": "usr_99812",
                    "email": "alex.dev@example.com",
                    "name": "Alex Developer",
                    "created_at": "2026-01-15T08:30:00Z"
                },
                "tokens": {
                    "access_token": "mock_jwt_access_token_xyz987abc123",
                    "refresh_token": "mock_refresh_token_uvw456def456",
                    "expires_in_seconds": 3600
                }
            }
            """
            guard let data = mockJSON.data(using: .utf8) else { throw NetworkError.noData }
            return try jsonDecoder.decode(T.self, from: data)
        }

        // Mock Signup
        if endpoint.path.contains("/auth/signup") {
            let mockJSON = """
            {
                "user": {
                    "id": "usr_\(Int.random(in: 10000...99999))",
                    "email": "newuser@example.com",
                    "name": "New User",
                    "created_at": "2026-10-11T10:00:00Z"
                },
                "tokens": {
                    "access_token": "mock_signup_access_token_\(UUID().uuidString)",
                    "refresh_token": "mock_signup_refresh_token_\(UUID().uuidString)",
                    "expires_in_seconds": 3600
                }
            }
            """
            guard let data = mockJSON.data(using: .utf8) else { throw NetworkError.noData }
            return try jsonDecoder.decode(T.self, from: data)
        }

        // Mock Profile / Current User
        if endpoint.path.contains("/auth/me") {
            let mockJSON = """
            {
                "user": {
                    "id": "usr_99812",
                    "email": "alex.dev@example.com",
                    "name": "Alex Developer",
                    "created_at": "2026-01-15T08:30:00Z"
                },
                "tokens": {
                    "access_token": "mock_jwt_access_token_xyz987abc123",
                    "refresh_token": "mock_refresh_token_uvw456def456",
                    "expires_in_seconds": 3600
                }
            }
            """
            guard let data = mockJSON.data(using: .utf8) else { throw NetworkError.noData }
            return try jsonDecoder.decode(T.self, from: data)
        }

        throw NetworkError.serverError(statusCode: 404, message: "Endpoint not found in mock simulator.")
    }
}

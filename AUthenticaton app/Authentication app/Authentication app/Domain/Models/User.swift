import Foundation

/// Pure Domain entity representing an authenticated user.
/// Independent of any network DTO or database model.
public struct User: Identifiable, Equatable, Hashable, Codable {
    public let id: String
    public let email: String
    public let name: String
    public let createdAt: Date?

    public init(
        id: String,
        email: String,
        name: String,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
    }
}

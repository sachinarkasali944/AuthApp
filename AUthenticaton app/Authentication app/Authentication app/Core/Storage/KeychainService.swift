import Foundation
import Security

/// Keychain error types for error handling and diagnostics
public enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case unexpectedData
    case unhandledError(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found in Keychain."
        case .duplicateItem:
            return "Item already exists in Keychain."
        case .unexpectedData:
            return "Unexpected data format in Keychain."
        case .unhandledError(let status):
            return "Keychain error with OSStatus: \(status)"
        }
    }
}

/// Abstract contract for secure token and credential persistence.
/// In an LLD interview, point out:
/// - UserDefaults is unencrypted plist file -> INSECURE for tokens.
/// - Keychain is encrypted using Secure Enclave hardware keys -> SECURE.
public protocol KeychainService {
    func save(key: String, data: Data) throws
    func get(key: String) throws -> Data?
    func delete(key: String) throws
    func clearAll() throws
}

public extension KeychainService {
    func saveString(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else { return }
        try save(key: key, data: data)
    }

    func getString(key: String) throws -> String? {
        guard let data = try get(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

/// Concrete KeychainService implementation utilizing Apple's Security framework.
public final class DefaultKeychainService: KeychainService {
    private let serviceName: String

    public init(serviceName: String = "com.authapp.security") {
        self.serviceName = serviceName
    }

    public func save(key: String, data: Data) throws {
        // Query to check if key already exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        if status == errSecItemNotFound {
            // Item does not exist, insert new
            var newItem = query
            newItem[kSecValueData as String] = data
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func get(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = dataTypeRef as? Data else {
            throw KeychainError.unexpectedData
        }

        return data
    }

    public func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

//
//  KeychainHelper.swift
//  GameLoggr
//
//  Created by Justin Gain on 7/18/25.
//

import Foundation
import Security

/// A helper class for securely storing and retrieving sensitive data from iOS Keychain
class KeychainHelper {
    
    static let shared = KeychainHelper()
    private init() {}
    
    // MARK: - Keychain Keys
    private enum KeychainKey {
        static let igdbClientId = "com.justingain.gameloggr.igdb.clientid"
        static let igdbClientSecret = "com.justingain.gameloggr.igdb.clientsecret"
    }
    
    // MARK: - Public API
    
    /// Store IGDB Client ID securely in Keychain
    func storeIGDBClientId(_ clientId: String) -> Bool {
        return store(key: KeychainKey.igdbClientId, value: clientId)
    }
    
    /// Retrieve IGDB Client ID from Keychain
    func getIGDBClientId() -> String? {
        return retrieve(key: KeychainKey.igdbClientId)
    }
    
    /// Store IGDB Client Secret securely in Keychain
    func storeIGDBClientSecret(_ clientSecret: String) -> Bool {
        return store(key: KeychainKey.igdbClientSecret, value: clientSecret)
    }
    
    /// Retrieve IGDB Client Secret from Keychain
    func getIGDBClientSecret() -> String? {
        return retrieve(key: KeychainKey.igdbClientSecret)
    }
    
    /// Check if IGDB credentials are stored in Keychain
    func hasIGDBCredentials() -> Bool {
        return getIGDBClientId() != nil && getIGDBClientSecret() != nil
    }
    
    /// Remove IGDB credentials from Keychain
    func removeIGDBCredentials() -> Bool {
        let clientIdRemoved = remove(key: KeychainKey.igdbClientId)
        let clientSecretRemoved = remove(key: KeychainKey.igdbClientSecret)
        return clientIdRemoved && clientSecretRemoved
    }
    
    // MARK: - Private Keychain Operations
    
    /// Store a string value in Keychain
    private func store(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("KeychainHelper: Failed to convert string to data")
            return false
        }
        
        // Delete any existing item first
        _ = remove(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("KeychainHelper: Successfully stored item for key: \(key)")
            return true
        } else {
            print("KeychainHelper: Failed to store item for key: \(key), status: \(status)")
            return false
        }
    }
    
    /// Retrieve a string value from Keychain
    private func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        } else if status == errSecItemNotFound {
            print("KeychainHelper: No item found for key: \(key)")
            return nil
        } else {
            print("KeychainHelper: Failed to retrieve item for key: \(key), status: \(status)")
            return nil
        }
    }
    
    /// Remove an item from Keychain
    private func remove(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            return true
        } else {
            print("KeychainHelper: Failed to remove item for key: \(key), status: \(status)")
            return false
        }
    }
}

// MARK: - Error Handling Extension
extension KeychainHelper {
    
    /// Convert Keychain status code to readable error message
    private func keychainErrorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecItemNotFound:
            return "Item not found"
        case errSecDuplicateItem:
            return "Duplicate item"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecUnimplemented:
            return "Unimplemented"
        case errSecParam:
            return "Invalid parameter"
        case errSecAllocate:
            return "Memory allocation failed"
        case errSecNotAvailable:
            return "Service not available"
        case errSecDecode:
            return "Decode failed"
        default:
            return "Unknown error: \(status)"
        }
    }
}

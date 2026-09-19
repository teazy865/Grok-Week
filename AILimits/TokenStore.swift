import Foundation
import Security

enum TokenStore {
    private static let account = "xai.oauth"
    private static let groupKey = "xai.tokens.v1"

    static func save(_ tokens: TokenSet) {
        let data = (try? JSONEncoder().encode(tokens)) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
        AppGroup.defaults.set(data, forKey: groupKey)
    }

    static func load() -> TokenSet? {
        if let data = AppGroup.defaults.data(forKey: groupKey),
           let tokens = try? JSONDecoder().decode(TokenSet.self, from: data) {
            return tokens
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return try? JSONDecoder().decode(TokenSet.self, from: data)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        AppGroup.defaults.removeObject(forKey: groupKey)
    }
}

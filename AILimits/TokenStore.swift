import Foundation
import Security

enum TokenStore {
    private static let account = "xai.oauth"
    private static let defaultsKey = "xai.oauth.tokens.v1"

    static func save(_ tokens: TokenSet) {
        let data = (try? JSONEncoder().encode(tokens)) ?? Data()
        AppGroup.defaults.set(data, forKey: defaultsKey)
        UserDefaults.standard.set(data, forKey: defaultsKey)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    static func load() -> TokenSet? {
        if let data = AppGroup.defaults.data(forKey: defaultsKey)
            ?? UserDefaults.standard.data(forKey: defaultsKey),
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
        AppGroup.defaults.removeObject(forKey: defaultsKey)
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

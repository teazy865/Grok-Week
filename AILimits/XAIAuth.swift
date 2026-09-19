import Foundation
import UIKit

enum XAIAuth {
    static let clientId = "b1a00492-073a-47ea-816f-4c329264a828"
    static let scope = "openid profile email offline_access grok-cli:access api:access"
    static let deviceURL = URL(string: "https://auth.x.ai/oauth2/device/code")!
    static let tokenURL = URL(string: "https://auth.x.ai/oauth2/token")!

    struct DeviceStart {
        var deviceCode: String
        var userCode: String
        var verifyURL: URL
        var interval: TimeInterval
        var expiresAt: Date
    }

    static func startDevice() async throws -> DeviceStart {
        var req = URLRequest(url: deviceURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = "client_id=\(clientId)&scope=\(scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scope)".data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let device = json["device_code"] as? String,
              let user = json["user_code"] as? String,
              let uri = (json["verification_uri_complete"] as? String) ?? (json["verification_uri"] as? String),
              let url = URL(string: uri) else {
            throw NSError(domain: "xai", code: 1, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "device start failed"])
        }
        let interval = TimeInterval(json["interval"] as? Int ?? 5)
        let exp = TimeInterval(json["expires_in"] as? Int ?? 600)
        return DeviceStart(deviceCode: device, userCode: user, verifyURL: url, interval: interval, expiresAt: Date().addingTimeInterval(exp))
    }

    static func poll(_ start: DeviceStart) async throws -> TokenSet {
        while Date() < start.expiresAt {
            try await Task.sleep(nanoseconds: UInt64(start.interval * 1_000_000_000))
            var req = URLRequest(url: tokenURL)
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let body = "grant_type=\("urn:ietf:params:oauth:grant-type:device_code".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&device_code=\(start.deviceCode)&client_id=\(clientId)"
            req.httpBody = body.data(using: .utf8)
            let (data, _) = try await URLSession.shared.data(for: req)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            if let access = json["access_token"] as? String {
                let refresh = json["refresh_token"] as? String
                let exp = TimeInterval(json["expires_in"] as? Int ?? 21600)
                return TokenSet(accessToken: access, refreshToken: refresh, expiresAt: Date().addingTimeInterval(exp))
            }
            let err = json["error"] as? String ?? ""
            if err == "authorization_pending" || err == "slow_down" { continue }
            throw NSError(domain: "xai", code: 2, userInfo: [NSLocalizedDescriptionKey: err.isEmpty ? (String(data: data, encoding: .utf8) ?? "auth failed") : err])
        }
        throw NSError(domain: "xai", code: 3, userInfo: [NSLocalizedDescriptionKey: "Код истёк"])
    }

    static func refreshIfNeeded(_ tokens: TokenSet) async throws -> TokenSet {
        if tokens.expiresAt.timeIntervalSinceNow > 120 { return tokens }
        guard let refresh = tokens.refreshToken else { return tokens }
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = "grant_type=refresh_token&refresh_token=\(refresh)&client_id=\(clientId)".data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let access = json["access_token"] as? String else {
            throw NSError(domain: "xai", code: 4, userInfo: [NSLocalizedDescriptionKey: "refresh failed"])
        }
        let newRefresh = json["refresh_token"] as? String ?? refresh
        let exp = TimeInterval(json["expires_in"] as? Int ?? 21600)
        let next = TokenSet(accessToken: access, refreshToken: newRefresh, expiresAt: Date().addingTimeInterval(exp))
        TokenStore.save(next)
        return next
    }

    static func open(_ url: URL) {
        DispatchQueue.main.async { UIApplication.shared.open(url) }
    }
}

import Foundation

struct UsageSnapshot: Codable, Equatable {
    var percentUsed: Double?
    var resetAt: Date?
    var updatedAt: Date
    var plan: String?
    var error: String?
    var signedIn: Bool
    var breakdown: [String: Double]

    var percentLeft: Double? {
        guard let used = percentUsed else { return nil }
        return max(0, 100 - used)
    }

    static var empty: UsageSnapshot {
        UsageSnapshot(percentUsed: nil, resetAt: nil, updatedAt: Date(), plan: nil, error: nil, signedIn: false, breakdown: [:])
    }
}

struct TokenSet: Codable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date
}

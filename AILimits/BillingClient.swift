import Foundation

enum BillingClient {
    static func fetch(token: String) async throws -> UsageSnapshot {
        var req = URLRequest(url: URL(string: "https://cli-chat-proxy.grok.com/v1/billing?format=credits")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("xai-grok-cli", forHTTPHeaderField: "X-XAI-Token-Auth")
        req.setValue("ai-limits-ios", forHTTPHeaderField: "x-grok-client-surface")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else {
            throw NSError(domain: "billing", code: code, userInfo: [NSLocalizedDescriptionKey: "HTTP \(code) " + (String(data: data, encoding: .utf8) ?? "")])
        }
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let config = (root["config"] as? [String: Any]) ?? root

        var used = number(config["creditUsagePercent"]) ?? number(config["credit_usage_percent"])
        if let u = used, u <= 1.0001 { used = u * 100 }

        var reset: Date? = nil
        if let period = config["currentPeriod"] as? [String: Any] {
            if let end = period["end"] as? String { reset = parseDate(end) }
        } else if let period = config["current_period"] as? [String: Any] {
            if let end = period["end"] as? String { reset = parseDate(end) }
        }

        var parts: [String: Double] = [:]
        let products = (config["productUsage"] as? [[String: Any]]) ?? (config["product_usage"] as? [[String: Any]]) ?? []
        for p in products {
            let name = pretty((p["product"] as? String) ?? "?")
            var val = number(p["usagePercent"]) ?? number(p["usage_percent"]) ?? 0
            if val <= 1.0001 { val *= 100 }
            parts[name] = val
        }

        var plan: String? = nil
        if let settings = try? await settings(token: token) { plan = settings }

        return UsageSnapshot(
            percentUsed: used,
            resetAt: reset,
            updatedAt: Date(),
            plan: plan,
            error: used == nil ? "xAI не вернул percent — сброс всё равно показан" : nil,
            signedIn: true,
            breakdown: parts
        )
    }

    private static func settings(token: String) async throws -> String? {
        var req = URLRequest(url: URL(string: "https://cli-chat-proxy.grok.com/v1/settings")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("xai-grok-cli", forHTTPHeaderField: "X-XAI-Token-Auth")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return (json["subscription_tier_display"] as? String)
            ?? (json["subscriptionTierDisplay"] as? String)
    }

    private static func number(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let n = any as? NSNumber { return n.doubleValue }
        return nil
    }

    private static func parseDate(_ raw: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: raw) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: raw)
    }

    private static func pretty(_ raw: String) -> String {
        raw.replacingOccurrences(of: "Grok", with: "")
    }
}

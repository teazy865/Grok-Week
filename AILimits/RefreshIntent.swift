import AppIntents
import Foundation

struct RefreshUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Обновить Grok"
    static var description: IntentDescription = "Тянет недельный пул xAI"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await UsageRefresher.run()
        return .result()
    }
}

enum UsageRefresher {
    static func run() async {
        guard var tokens = TokenStore.load() else { return }
        do {
            tokens = try await XAIAuth.refreshIfNeeded(tokens)
            let snap = try await BillingClient.fetch(token: tokens.accessToken)
            UsageStore.save(snap)
        } catch {
            var snap = UsageStore.load()
            snap.error = error.localizedDescription
            snap.signedIn = true
            UsageStore.save(snap)
        }
    }
}

import AppIntents
import WidgetKit

struct RefreshUsageIntent: AppIntent {
    static var title: LocalizedStringResource = "Обновить Grok"
    static var description: IntentDescription = "Тянет недельный пул xAI"

    func perform() async throws -> some IntentResult {
        guard var tokens = TokenStore.load() else {
            return .result()
        }
        tokens = (try? await XAIAuth.refreshIfNeeded(tokens)) ?? tokens
        if let snap = try? await BillingClient.fetch(token: tokens.accessToken) {
            UsageStore.save(snap)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

import Foundation
import WidgetKit

enum UsageStore {
    static func load() -> UsageSnapshot {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.snapshotKey),
              let snap = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else {
            return .empty
        }
        return snap
    }

    static func save(_ snap: UsageSnapshot) {
        if let data = try? JSONEncoder().encode(snap) {
            AppGroup.defaults.set(data, forKey: AppGroup.snapshotKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

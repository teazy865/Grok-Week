import Foundation

enum UsageStore {
    static func load() -> UsageSnapshot {
        let data = AppGroup.defaults.data(forKey: AppGroup.snapshotKey)
            ?? UserDefaults.standard.data(forKey: AppGroup.snapshotKey)
        guard let data,
              let snap = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else {
            return .empty
        }
        return snap
    }

    static func save(_ snap: UsageSnapshot) {
        guard let data = try? JSONEncoder().encode(snap) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.snapshotKey)
        UserDefaults.standard.set(data, forKey: AppGroup.snapshotKey)
        reloadWidgets()
    }

    private static func reloadWidgets() {
        guard let cls = NSClassFromString("WidgetKit.WidgetCenter") as? NSObject.Type else { return }
        let center = cls.perform(NSSelectorFromString("shared"))?.takeUnretainedValue() as? NSObject
        _ = center?.perform(NSSelectorFromString("reloadAllTimelines"))
    }
}

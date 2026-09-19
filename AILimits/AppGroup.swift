import Foundation

enum AppGroup {
    static let id = "group.com.teazy.ailimits"
    static let snapshotKey = "usage.snapshot.v2"
    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

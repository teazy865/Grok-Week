import Foundation

struct UsageSnapshot: Equatable {
    var percentUsed: Double
    var resetAt: Date
    var updatedAt: Date
    var breakdown: [(name: String, value: Double)]

    var percentLeft: Double { max(0, 100 - percentUsed) }

    static var empty: UsageSnapshot {
        UsageSnapshot(
            percentUsed: 0,
            resetAt: Date().addingTimeInterval(7 * 24 * 3600),
            updatedAt: Date(),
            breakdown: [("Chat", 0), ("Imagine", 0), ("Voice", 0), ("Build", 0)]
        )
    }
}

import WidgetKit
import SwiftUI
import AppIntents

struct Entry: TimelineEntry {
    let date: Date
    let snap: UsageSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), snap: .empty) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), snap: UsageStore.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let snap = UsageStore.load()
        let next = Date().addingTimeInterval(5 * 60)
        completion(Timeline(entries: [Entry(date: Date(), snap: snap)], policy: .after(next)))
    }
}

struct UsageWidgetView: View {
    var entry: Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let left = entry.snap.percentLeft.map { "\(Int($0.rounded()))% left" } ?? "нет %"
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Grok week").font(.headline)
                Spacer()
                Button(intent: RefreshUsageIntent()) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            Text(left).font(.title2.bold())
            ProgressView(value: min(1, (entry.snap.percentUsed ?? 0) / 100)).tint(.orange)
            if family != .systemSmall {
                if let used = entry.snap.percentUsed {
                    Text("\(Int(used.rounded()))% used")
                }
                if let reset = entry.snap.resetAt {
                    Text("сброс \(reset.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(for: .widget) { Color.black }
    }
}

@main
struct UsageWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UsageWidget", provider: Provider()) { UsageWidgetView(entry: $0) }
        .configurationDisplayName("Grok Usage")
        .description("Остаток недели, обновление каждые 5 мин")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

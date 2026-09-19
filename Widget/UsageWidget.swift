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
        let now = Date()
        var entries: [Entry] = [Entry(date: now, snap: snap)]
        if let t = Calendar.current.date(byAdding: .minute, value: 5, to: now) {
            entries.append(Entry(date: t, snap: snap))
        }
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(300)
        completion(Timeline(entries: entries, policy: .after(next)))
    }
}

struct UsageWidgetView: View {
    var entry: Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let left = entry.snap.percentLeft.map { "\(Int($0.rounded()))%" } ?? "нет %"
        let used = entry.snap.percentUsed.map { "\(Int($0.rounded()))% used" } ?? "—"
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Grok week").font(.headline)
                Spacer()
                Button(intent: RefreshUsageIntent()) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .tint(.orange)
            }
            Text(left).font(.title2.bold())
            ProgressView(value: min(1, (entry.snap.percentUsed ?? 0) / 100)).tint(.orange)
            if family != .systemSmall {
                Text(used)
                if let reset = entry.snap.resetAt {
                    Text("сброс \(reset.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text(entry.snap.updatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2).foregroundStyle(.secondary)
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
            .description("Сколько осталось недельного пула")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

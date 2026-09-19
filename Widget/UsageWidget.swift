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
        Task {
            await UsageRefresher.run()
            let snap = UsageStore.load()
            let now = Date()
            var entries: [Entry] = []
            for i in 0..<6 {
                let t = now.addingTimeInterval(TimeInterval(i * 50))
                entries.append(Entry(date: t, snap: snap))
            }
            let next = Calendar.current.date(byAdding: .minute, value: 5, to: now)
                ?? now.addingTimeInterval(300)
            completion(Timeline(entries: entries, policy: .after(next)))
        }
    }
}

struct UsageWidgetView: View {
    var entry: Entry
    @Environment(\.widgetFamily) private var family

    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        let left = entry.snap.percentLeft.map { "\(Int($0.rounded()))%" } ?? "нет %"
        let used = entry.snap.percentUsed.map { "\(Int($0.rounded()))% использовано" } ?? "—"
        GeometryReader { geo in
            let lead = geo.size.width * 0.05
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: isSmall ? 4 : 6) {
                    if isSmall { Spacer(minLength: 10) }
                    Text("Неделя Grok")
                        .font(isSmall ? .subheadline.weight(.semibold) : .headline)
                    Text(left)
                        .font(isSmall ? .title3.bold() : .title2.bold())
                    ProgressView(value: min(1, (entry.snap.percentUsed ?? 0) / 100))
                        .tint(.orange)
                    Text(used)
                        .font(isSmall ? .caption : .body)
                    if let reset = entry.snap.resetAt {
                        Text("сброс \(reset.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Text(entry.snap.updatedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding(.leading, lead)
                .padding(.trailing, isSmall ? 28 : 16)
                .padding(.top, isSmall ? 8 : 10)
                .padding(.bottom, 28)

                Button(intent: RefreshUsageIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(8)
                }
                .buttonStyle(.plain)
                .tint(.white)
                .padding(.trailing, 8)
                .padding(.bottom, 8)
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
            .contentMarginsDisabled()
    }
}

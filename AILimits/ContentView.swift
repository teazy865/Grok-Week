import SwiftUI
import UIKit

struct ContentView: View {
    @State private var snap = UsageSnapshot.empty

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Grok")
                        .font(.largeTitle.bold())
                    Text("Демо на устройстве. Живой пул — в приложении Grok → Settings → Usage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 18) {
                        ZStack {
                            Circle().stroke(.white.opacity(0.12), lineWidth: 12)
                            Circle()
                                .trim(from: 0, to: min(1, snap.percentUsed / 100))
                                .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 2) {
                                Text("\(Int(snap.percentUsed.rounded()))%")
                                    .font(.title.bold())
                                Text("used")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 120, height: 120)

                        VStack(alignment: .leading, spacing: 8) {
                            metric("Осталось", "\(Int(snap.percentLeft.rounded()))%")
                            metric("Сброс", snap.resetAt.formatted(date: .abbreviated, time: .shortened))
                            metric("Обновлено", snap.updatedAt.formatted(date: .omitted, time: .shortened))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.06)))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Разбивка")
                            .font(.headline)
                        ForEach(snap.breakdown, id: \.name) { row in
                            HStack {
                                Text(row.name)
                                Spacer()
                                Text("\(row.value, specifier: "%.1f")%")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.06)))

                    Button {
                        snap = demo()
                    } label: {
                        Label("Обновить демо", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    Button {
                        if let url = URL(string: "grok://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Открыть Grok", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold))
        }
    }

    private func demo() -> UsageSnapshot {
        let used = Double.random(in: 10...58)
        let chat = used * 0.45
        let imagine = used * 0.32
        let voice = used * 0.13
        let build = max(0, used - chat - imagine - voice)
        return UsageSnapshot(
            percentUsed: (used * 10).rounded() / 10,
            resetAt: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date(),
            updatedAt: Date(),
            breakdown: [
                ("Chat", (chat * 10).rounded() / 10),
                ("Imagine", (imagine * 10).rounded() / 10),
                ("Voice", (voice * 10).rounded() / 10),
                ("Build", (build * 10).rounded() / 10)
            ]
        )
    }
}

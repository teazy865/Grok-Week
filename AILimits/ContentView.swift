import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var snap = UsageStore.load()
    @State private var userCode = ""
    @State private var status = ""
    @State private var busy = false
    @State private var pending: XAIAuth.DeviceStart?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Grok")
                        .font(.largeTitle.bold())
                    if let plan = snap.plan {
                        Text(plan).foregroundStyle(.secondary)
                    }

                    ring
                    breakdown

                    if let pending {
                        Text("Код: \(pending.userCode)")
                            .font(.title2.monospaced())
                    } else if !userCode.isEmpty {
                        Text("Код: \(userCode)")
                            .font(.title2.monospaced())
                    }
                    if !status.isEmpty {
                        Text(status).font(.footnote).foregroundStyle(.secondary)
                    }
                    if let err = snap.error {
                        Text(err).font(.footnote).foregroundStyle(.orange)
                    }

                    Button { Task { await login() } } label: {
                        Label(snap.signedIn ? "Войти снова" : "Войти в xAI", systemImage: "person.badge.key")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(busy)

                    if pending != nil {
                        Button { Task { await finishLogin() } } label: {
                            Label("Я уже авторизовал", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(busy)
                    }

                    Button { Task { await refresh() } } label: {
                        Label("Обновить пул", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(busy || TokenStore.load() == nil)

                    Button(role: .destructive) {
                        TokenStore.clear()
                        XAIAuth.clearPending()
                        pending = nil
                        snap = .empty
                        UsageStore.save(snap)
                    } label: {
                        Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .task {
                pending = XAIAuth.loadPending()
                if TokenStore.load() != nil { await refresh() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    pending = XAIAuth.loadPending()
                    if pending != nil { Task { await finishLogin() } }
                }
            }
        }
    }

    private var ring: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(.white.opacity(0.12), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: min(1, (snap.percentUsed ?? 0) / 100))
                    .stroke(.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text(snap.percentUsed.map { "\(Int($0.rounded()))%" } ?? "—")
                        .font(.title.bold())
                    Text("used").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            VStack(alignment: .leading, spacing: 8) {
                row("Осталось", snap.percentLeft.map { "\(Int($0.rounded()))%" } ?? "—")
                row("Сброс", snap.resetAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                row("Обновлено", snap.updatedAt.formatted(date: .omitted, time: .shortened))
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.06)))
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Разбивка недели").font(.headline)
            if snap.breakdown.isEmpty {
                Text("Нет данных").foregroundStyle(.secondary)
            } else {
                ForEach(snap.breakdown.keys.sorted(), id: \.self) { k in
                    HStack {
                        Text(k)
                        Spacer()
                        Text("\(snap.breakdown[k] ?? 0, specifier: "%.1f")%")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.06)))
    }

    private func row(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(t).font(.caption).foregroundStyle(.secondary)
            Text(v).font(.subheadline.weight(.semibold))
        }
    }

    @MainActor
    private func login() async {
        busy = true
        status = "Запрашиваю код…"
        do {
            let start = try await XAIAuth.startDevice()
            pending = start
            userCode = start.userCode
            status = "Открой xAI, введи код, вернись сюда и нажми «Я уже авторизовал»"
            XAIAuth.open(start.verifyURL)
        } catch {
            status = error.localizedDescription
        }
        busy = false
    }

    @MainActor
    private func finishLogin() async {
        guard let start = pending ?? XAIAuth.loadPending() else {
            status = "Сначала запроси код"
            return
        }
        busy = true
        status = "Забираю токен…"
        do {
            if let tokens = try await XAIAuth.tryTokenOnce(start) {
                TokenStore.save(tokens)
                pending = nil
                userCode = ""
                status = "Вход есть, тяну usage…"
                await refresh()
            } else {
                status = "xAI ещё не отдал токен. Закрой Safari и нажми кнопку снова."
            }
        } catch {
            status = error.localizedDescription
        }
        busy = false
    }

    @MainActor
    private func refresh() async {
        guard var tokens = TokenStore.load() else {
            status = "Сначала войди"
            return
        }
        busy = true
        do {
            tokens = try await XAIAuth.refreshIfNeeded(tokens)
            snap = try await BillingClient.fetch(token: tokens.accessToken)
            UsageStore.save(snap)
            status = "Ок"
        } catch {
            snap.error = error.localizedDescription
            snap.signedIn = TokenStore.load() != nil
            UsageStore.save(snap)
            status = error.localizedDescription
        }
        busy = false
    }
}

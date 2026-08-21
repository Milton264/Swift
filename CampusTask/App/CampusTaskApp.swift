import SwiftUI
import SwiftData

@main
struct CampusTaskApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [CampusTaskItem.self, CourseRecord.self, PendingMutation.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var appState = AppState()
    @StateObject private var network = NetworkMonitor()
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue

    private var appearance: Appearance {
        Appearance(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        Group {
            switch appState.launchState {
            case .splash:
                SplashView(message: appState.lastMessage)
            case .loggedOut:
                LoginView()
            case .ready:
                MainTabView()
            }
        }
        .environmentObject(appState)
        .environmentObject(network)
        .preferredColorScheme(appearance.colorScheme)
        .task { await appState.start(using: modelContext) }
        .onChange(of: network.isConnected) { wasConnected, isConnected in
            guard !wasConnected, isConnected, appState.launchState == .ready else { return }
            Task { try? await appState.syncPendingChanges(using: modelContext) }
        }
        .alert(
            "CampusTask",
            isPresented: Binding(
                get: { appState.presentedError != nil },
                set: { if !$0 { appState.presentedError = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) { appState.presentedError = nil }
        } message: {
            Text(appState.presentedError ?? "Ocurrió un error.")
        }
    }
}

struct SplashView: View {
    let message: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.campusInk, Color(hex: "27204F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.12))
                        .frame(width: 104, height: 104)
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(spacing: 7) {
                    Text("CampusTask")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Tu universidad, incluso sin conexión")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)

                ProgressView()
                    .tint(.white)
                    .padding(.top, 14)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(32)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var network: NetworkMonitor

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Inicio", systemImage: "square.grid.2x2.fill") }

            TaskListView()
                .tabItem { Label("Actividades", systemImage: "checklist") }

            CoursesView()
                .tabItem { Label("Materias", systemImage: "books.vertical.fill") }

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
        }
        .tint(.campusPurple)
        .safeAreaInset(edge: .top, spacing: 0) {
            if !network.isConnected {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: network.isConnected)
    }
}

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
            VStack(alignment: .leading, spacing: 1) {
                Text("Modo sin conexión").font(.subheadline.bold())
                Text("Tus cambios se guardarán en el iPhone.").font(.caption)
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.campusOrange)
    }
}

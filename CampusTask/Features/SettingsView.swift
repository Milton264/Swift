import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    @AppStorage("taskFilter") private var filterRaw = TaskFilter.all.rawValue
    @AppStorage("compactMode") private var compactMode = false
    @State private var confirmingReset = false
    @State private var confirmingLogout = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 13) {
                        ZStack {
                            Circle().fill(Color.campusPurple.opacity(0.13)).frame(width: 52, height: 52)
                            Image(systemName: "person.fill").foregroundStyle(.campusPurple)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(appState.currentUser?.fullName ?? "Estudiante").font(.headline)
                            Text(appState.currentUser?.email ?? "Sesión local")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Preferencias · UserDefaults") {
                    Picker("Apariencia", selection: $appearanceRaw) {
                        ForEach(Appearance.allCases) { item in Text(item.rawValue).tag(item.rawValue) }
                    }
                    Picker("Filtro inicial", selection: $filterRaw) {
                        ForEach(TaskFilter.allCases) { item in Text(item.rawValue).tag(item.rawValue) }
                    }
                    Toggle("Vista compacta", isOn: $compactMode)
                }

                Section("Seguridad · Keychain") {
                    Label(
                        appState.hasStoredToken ? "Token de sesión protegido" : "No existe una sesión guardada",
                        systemImage: appState.hasStoredToken ? "lock.shield.fill" : "lock.open"
                    )
                    .foregroundStyle(appState.hasStoredToken ? Color.campusTeal : Color.secondary)
                    Text("Las preferencias no son sensibles y se guardan en UserDefaults; el token sí es sensible y se almacena en Keychain.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Exposición") {
                    NavigationLink {
                        DemoTopicsView()
                    } label: {
                        Label("Ver temas 5.1–5.5", systemImage: "graduationcap.fill")
                    }
                    NavigationLink {
                        SyncStatusView()
                    } label: {
                        Label("Estado de sincronización", systemImage: "arrow.triangle.2.circlepath.icloud")
                    }
                }

                Section("Datos de prueba") {
                    Button("Restaurar datos del prototipo") { confirmingReset = true }
                    Button("Cerrar sesión", role: .destructive) { confirmingLogout = true }
                }

                Section {
                    Text("CampusTask 1.0 · Prototipo académico")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Configuración")
            .confirmationDialog("¿Restaurar los datos locales?", isPresented: $confirmingReset) {
                Button("Restaurar", role: .destructive) { appState.resetLocalData(using: modelContext) }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se reemplazarán las tareas locales por los datos de demostración.")
            }
            .confirmationDialog("¿Cerrar la sesión?", isPresented: $confirmingLogout) {
                Button("Cerrar sesión", role: .destructive) { appState.logout() }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }
}

struct DemoTopicsView: View {
    private let topics: [DemoTopic] = [
        .init(number: "5.1", title: "Concurrencia", icon: "bolt.fill", color: "6D5DFB", summary: "Perfil, tareas y materias se descargan simultáneamente.", code: "async let perfil = api.fetchProfile()\nasync let tareas = api.fetchTodos()"),
        .init(number: "5.2", title: "API y URLSession", icon: "network", color: "0EA5A8", summary: "Se ejecutan GET, POST y PATCH, validando respuestas 200..<300.", code: "let (data, response) = try await\nURLSession.shared.data(for: request)"),
        .init(number: "5.3", title: "Codable", icon: "curlybraces", color: "F59E0B", summary: "El JSON se transforma en modelos Swift con CodingKeys, opcionales y fechas.", code: "case title = \"todo\"\ndecoder.keyDecodingStrategy =\n  .convertFromSnakeCase"),
        .init(number: "5.4", title: "UserDefaults y Keychain", icon: "key.fill", color: "EF5DA8", summary: "El tema y los filtros son preferencias; el token es un dato sensible.", code: "@AppStorage(\"appearance\") var theme\nKeychainStore().saveToken(token)"),
        .init(number: "5.5", title: "SwiftData", icon: "externaldrive.fill", color: "3E4CA8", summary: "Tareas, materias y cambios pendientes permanecen disponibles offline.", code: "@Model final class CampusTaskItem\ncontext.insert(task)\ntry context.save()")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(topics) { topic in TopicCard(topic: topic) }
            }
            .padding(18)
        }
        .background(Color.primary.opacity(0.025))
        .navigationTitle("Temas demostrados")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DemoTopic: Identifiable {
    let number: String
    let title: String
    let icon: String
    let color: String
    let summary: String
    let code: String
    var id: String { number }
}

private struct TopicCard: View {
    let topic: DemoTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                Image(systemName: topic.icon)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: topic.color), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tema \(topic.number)").font(.caption.bold()).foregroundStyle(Color(hex: topic.color))
                    Text(topic.title).font(.headline)
                }
            }
            Text(topic.summary).font(.subheadline).foregroundStyle(.secondary)
            Text(topic.code)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
        }
        .campusCard()
    }
}

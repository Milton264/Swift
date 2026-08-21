import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var network: NetworkMonitor
    @Query(sort: \CampusTaskItem.dueDate) private var tasks: [CampusTaskItem]
    @State private var showingCreate = false

    private var pending: Int { tasks.filter { $0.status == .pending }.count }
    private var completed: Int { tasks.filter { $0.status == .completed }.count }
    private var overdue: Int { tasks.filter { $0.status == .overdue }.count }
    private var completion: Double {
        tasks.isEmpty ? 0 : Double(completed) / Double(tasks.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    greeting
                    creatorsCard
                    progressCard
                    stats
                    quickActions
                    upcoming
                    concurrencyNote
                }
                .padding(18)
            }
            .background(Color.primary.opacity(0.025))
            .navigationTitle("Resumen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SyncStatusView()
                    } label: {
                        Image(systemName: appState.isSyncing ? "arrow.triangle.2.circlepath" : "icloud")
                    }
                }
            }
            .refreshable {
                await appState.refresh(using: modelContext, showErrors: true)
            }
            .sheet(isPresented: $showingCreate) { CreateTaskView() }
        }
    }

    private var greeting: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle().fill(Color.campusPurple.opacity(0.13)).frame(width: 52, height: 52)
                Text(initials)
                    .font(.headline.bold())
                    .foregroundStyle(.campusPurple)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Hola, \(firstName)")
                    .font(.title2.bold())
                Label(network.connectionName, systemImage: network.isConnected ? "wifi" : "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(network.isConnected ? Color.campusTeal : Color.campusOrange)
            }
            Spacer()
            Image(systemName: "bell.fill")
                .foregroundStyle(.campusPurple)
                .padding(11)
                .background(Color.campusPurple.opacity(0.1), in: Circle())
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progreso semanal")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Vas avanzando. Cada actividad cuenta.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                Text(completion, format: .percent.precision(.fractionLength(0)))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
            ProgressView(value: completion)
                .tint(.white)
                .background(.white.opacity(0.2))
            HStack {
                Label("\(completed) listas", systemImage: "checkmark.circle.fill")
                Spacer()
                Text("\(tasks.count) actividades")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.campusPurple, Color(hex: "3E4CA8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private var creatorsCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.headline)
                .foregroundStyle(.campusPurple)
                .frame(width: 40, height: 40)
                .background(Color.campusPurple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text("Creado por")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Milton · Angel · Walter · Leonel · Carlos")
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .campusCard()
    }

    private var stats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Pendientes", value: pending, icon: "clock.fill", tint: .campusOrange)
            StatCard(title: "Completadas", value: completed, icon: "checkmark.circle.fill", tint: .campusTeal)
            StatCard(title: "Vencidas", value: overdue, icon: "exclamationmark.triangle.fill", tint: .red)
            StatCard(title: "Total", value: tasks.count, icon: "tray.full.fill", tint: .campusPurple)
        }
    }

    private var quickActions: some View {
        VStack(spacing: 12) {
            SectionTitle("Acciones rápidas")
            HStack(spacing: 12) {
                Button { showingCreate = true } label: {
                    QuickAction(icon: "plus", title: "Nueva tarea", tint: .campusPurple)
                }
                NavigationLink {
                    SyncStatusView()
                } label: {
                    QuickAction(icon: "arrow.triangle.2.circlepath", title: "Sincronizar", tint: .campusTeal)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var upcoming: some View {
        VStack(spacing: 12) {
            HStack {
                SectionTitle("Próximas entregas", subtitle: "Ordenadas por fecha")
                NavigationLink("Ver todas") { TaskListView() }
                    .font(.caption.bold())
            }
            if tasks.isEmpty {
                ContentUnavailableView("Sin actividades", systemImage: "checkmark.seal", description: Text("Creá tu primera tarea."))
                    .frame(height: 180)
            } else {
                ForEach(Array(tasks.filter { !$0.isCompleted }.prefix(3)), id: \.localID) { task in
                    NavigationLink { TaskDetailView(task: task) } label: {
                        DashboardTaskRow(task: task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var concurrencyNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.title3)
                .foregroundStyle(.campusPurple)
            VStack(alignment: .leading, spacing: 3) {
                Text("Concurrencia activa").font(.subheadline.bold())
                Text("El perfil, las tareas y las materias se cargaron al mismo tiempo usando async let.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .campusCard()
    }

    private var firstName: String {
        appState.currentUser?.fullName.split(separator: " ").first.map(String.init) ?? "Estudiante"
    }

    private var initials: String {
        let parts = (appState.currentUser?.fullName ?? "Campus Task").split(separator: " ")
        return parts.prefix(2).compactMap(\.first).map(String.init).joined()
    }
}

private struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(value)").font(.title2.bold())
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .campusCard()
    }
}

private struct QuickAction: View {
    let icon: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(tint, in: RoundedRectangle(cornerRadius: 11))
            Text(title).font(.subheadline.bold()).foregroundStyle(.primary)
            Spacer()
        }
        .campusCard()
    }
}

private struct DashboardTaskRow: View {
    let task: CampusTaskItem

    var body: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: task.colorHex))
                .frame(width: 5, height: 55)
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title).font(.subheadline.bold()).lineLimit(1)
                Text(task.courseCode).font(.caption).foregroundStyle(.secondary)
                Label(task.dueDate.campusRelative, systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(task.status == .overdue ? Color.red : Color.primary.opacity(0.55))
            }
            Spacer()
            StatusPill(status: task.status)
        }
        .campusCard()
    }
}

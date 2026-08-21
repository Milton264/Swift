import SwiftUI
import SwiftData

struct TaskListView: View {
    @Query(sort: \CampusTaskItem.dueDate) private var tasks: [CampusTaskItem]
    @AppStorage("taskFilter") private var filterRaw = TaskFilter.all.rawValue
    @State private var searchText = ""
    @State private var showingCreate = false

    private var filter: TaskFilter {
        TaskFilter(rawValue: filterRaw) ?? .all
    }

    private var filteredTasks: [CampusTaskItem] {
        tasks.filter { task in
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = true
            case .pending: matchesFilter = task.status == .pending
            case .completed: matchesFilter = task.status == .completed
            case .overdue: matchesFilter = task.status == .overdue
            }
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty || task.title.localizedCaseInsensitiveContains(query) || task.courseName.localizedCaseInsensitiveContains(query)
            return matchesFilter && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filtro", selection: $filterRaw) {
                    ForEach(TaskFilter.allCases) { item in
                        Text(item.rawValue).tag(item.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if filteredTasks.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredTasks, id: \.localID) { task in
                            NavigationLink { TaskDetailView(task: task) } label: {
                                TaskListRow(task: task)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Actividades")
            .searchable(text: $searchText, prompt: "Buscar tarea o materia")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingCreate) { CreateTaskView() }
        }
    }
}

private struct TaskListRow: View {
    let task: CampusTaskItem
    @AppStorage("compactMode") private var compactMode = false

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(task.isCompleted ? Color.campusTeal : Color(hex: task.colorHex))
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                Text(task.courseName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 7) {
                    StatusPill(status: task.status)
                    SyncPill(state: task.syncState)
                }
            }
            Spacer(minLength: 4)
        }
        .padding(.vertical, compactMode ? 1 : 7)
    }
}

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var network: NetworkMonitor
    let task: CampusTaskItem

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                infoGrid
                notesCard
                storageCard
                Button {
                    Task {
                        await appState.toggleCompletion(of: task, isConnected: network.isConnected, using: modelContext)
                    }
                } label: {
                    Label(task.isCompleted ? "Marcar como pendiente" : "Completar actividad", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                }
                .buttonStyle(CampusPrimaryButtonStyle())
            }
            .padding(18)
        }
        .background(Color.primary.opacity(0.025))
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text(task.courseCode)
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: task.colorHex))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: task.colorHex).opacity(0.12), in: Capsule())
                Spacer()
                StatusPill(status: task.status)
            }
            Text(task.title)
                .font(.system(size: 27, weight: .bold, design: .rounded))
            Text(task.courseName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .campusCard()
    }

    private var infoGrid: some View {
        HStack(spacing: 12) {
            DetailInfo(icon: "calendar", label: "Entrega", value: task.dueDate.campusFormatted, tint: .campusPurple)
            DetailInfo(icon: "icloud", label: "Estado", value: syncLabel, tint: .campusTeal)
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle("Indicaciones")
            Text(task.notes.isEmpty ? "Esta actividad no tiene indicaciones adicionales." : task.notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .campusCard()
    }

    private var storageCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "externaldrive.fill.badge.checkmark")
                .font(.title2)
                .foregroundStyle(Color.campusPurple)
            VStack(alignment: .leading, spacing: 4) {
                Text("Guardada con SwiftData").font(.subheadline.bold())
                Text("Podés consultar y modificar esta actividad aunque el iPhone no tenga internet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .campusCard()
    }

    private var syncLabel: String {
        switch task.syncState {
        case .synced: return "Sincronizada"
        case .pending: return "Pendiente"
        case .syncing: return "En proceso"
        case .failed: return "Con error"
        }
    }
}

private struct DetailInfo: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.caption.bold()).lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .campusCard()
    }
}

struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var network: NetworkMonitor
    @Query(sort: \CourseRecord.name) private var courses: [CourseRecord]
    @State private var title = ""
    @State private var notes = ""
    @State private var courseCode = ""
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
    @State private var isSaving = false

    private var selectedCourse: CourseRecord? {
        courses.first(where: { $0.code == courseCode }) ?? courses.first
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") {
                    TextField("Ej. Preparar presentación", text: $title)
                    TextField("Indicaciones o notas", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Materia y entrega") {
                    Picker("Materia", selection: $courseCode) {
                        ForEach(courses, id: \.code) { course in
                            Text(course.name).tag(course.code)
                        }
                    }
                    DatePicker("Fecha", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
                Section {
                    Label(
                        network.isConnected ? "Se enviará a la API con POST." : "Se guardará en SwiftData y quedará pendiente.",
                        systemImage: network.isConnected ? "wifi" : "wifi.slash"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Nueva actividad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 || selectedCourse == nil || isSaving)
                }
            }
            .onAppear {
                if courseCode.isEmpty { courseCode = courses.first?.code ?? "" }
            }
        }
    }

    private func save() {
        guard let course = selectedCourse else { return }
        isSaving = true
        Task {
            await appState.createTask(
                title: title,
                notes: notes,
                course: course,
                dueDate: dueDate,
                isConnected: network.isConnected,
                using: modelContext
            )
            isSaving = false
            dismiss()
        }
    }
}

import Foundation
import SwiftData
import Combine

enum LaunchState: Equatable {
    case splash
    case loggedOut
    case ready
}

@MainActor
final class AppState: ObservableObject {
    @Published var launchState: LaunchState = .splash
    @Published var currentUser: UserProfile?
    @Published var isBusy = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var lastMessage = "Preparando CampusTask…"
    @Published var presentedError: String?

    private let api = CampusAPI()
    private let keychain = KeychainStore()
    private var didStart = false

    var hasStoredToken: Bool { keychain.readToken() != nil }

    func start(using context: ModelContext) async {
        guard !didStart else { return }
        didStart = true
        lastMessage = "Leyendo sesión segura…"
        try? await Task.sleep(nanoseconds: 850_000_000)

        if let token = keychain.readToken() {
            currentUser = cachedDemoUser()
            launchState = .ready
            lastMessage = "Datos locales disponibles"

            // TEMA 5.1: Task permite actualizar sin bloquear la interfaz.
            Task { [weak self] in
                await self?.refresh(using: context, token: token, showErrors: false)
            }
        } else {
            launchState = .loggedOut
        }
    }

    func login(username: String, password: String, using context: ModelContext) async {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            presentedError = "Escribí el usuario y la contraseña."
            return
        }

        isBusy = true
        lastMessage = "Autenticando con la API…"
        defer { isBusy = false }

        do {
            let response = try await api.login(username: username, password: password)
            try keychain.saveToken(response.accessToken)
            currentUser = UserProfile(
                id: response.id,
                fullName: "\(response.firstName) \(response.lastName)",
                email: response.email,
                username: response.username
            )
            launchState = .ready
            await refresh(using: context, token: response.accessToken, showErrors: true)
        } catch {
            presentedError = friendly(error)
        }
    }

    func enterOfflineDemo(using context: ModelContext) {
        do {
            try keychain.saveToken("campustask-offline-demo-token")
            currentUser = cachedDemoUser()
            try seedDemoDataIfNeeded(using: context)
            launchState = .ready
            lastMessage = "Modo demostración sin conexión"
        } catch {
            presentedError = friendly(error)
        }
    }

    func refresh(using context: ModelContext, token: String? = nil, showErrors: Bool = true) async {
        guard let sessionToken = token ?? keychain.readToken() else { return }
        isSyncing = true
        lastMessage = "Descargando perfil, materias y tareas a la vez…"
        defer { isSyncing = false }

        do {
            // TEMA 5.1: estas tres operaciones arrancan simultáneamente.
            async let profileRequest = api.fetchProfile(token: sessionToken)
            async let tasksRequest = api.fetchTodos()
            async let coursesRequest = api.fetchCourses()

            let (profile, remoteTasks, courses) = try await (
                profileRequest,
                tasksRequest,
                coursesRequest
            )

            currentUser = UserProfile(
                id: profile.id,
                fullName: "\(profile.firstName) \(profile.lastName)",
                email: profile.email,
                username: profile.username
            )
            try upsert(courses: courses, using: context)
            try upsert(remoteTasks: remoteTasks, courses: courses, using: context)
            try await syncPendingChanges(using: context)
            lastSyncDate = .now
            lastMessage = "Sincronización completada"
        } catch {
            try? seedDemoDataIfNeeded(using: context)
            lastMessage = "Mostrando información guardada sin conexión"
            if showErrors { presentedError = friendly(error) }
        }
    }

    func createTask(
        title: String,
        notes: String,
        course: CourseRecord,
        dueDate: Date,
        isConnected: Bool,
        using context: ModelContext
    ) async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            presentedError = "El título debe tener al menos 3 caracteres."
            return
        }

        let item = CampusTaskItem(
            title: trimmed,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            courseName: course.name,
            courseCode: course.code,
            colorHex: course.colorHex,
            dueDate: dueDate,
            syncState: isConnected ? .syncing : .pending
        )
        context.insert(item)

        if isConnected {
            do {
                let response = try await api.createTodo(
                    title: item.title,
                    completed: item.isCompleted,
                    userID: currentUser?.id ?? 1
                )
                item.serverID = response.id
                item.syncState = .synced
                lastSyncDate = .now
                lastMessage = "Tarea enviada con POST"
            } catch {
                item.syncState = .pending
                queueCreate(for: item, using: context, error: error.localizedDescription)
                lastMessage = "Tarea guardada para sincronizar después"
            }
        } else {
            queueCreate(for: item, using: context)
            lastMessage = "Tarea creada sin conexión"
        }
        try? context.save()
    }

    func toggleCompletion(of item: CampusTaskItem, isConnected: Bool, using context: ModelContext) async {
        item.isCompleted.toggle()
        item.updatedAt = .now
        item.syncState = isConnected ? .syncing : .pending

        guard isConnected, let serverID = item.serverID, serverID <= 150 else {
            queueToggle(for: item, using: context)
            try? context.save()
            lastMessage = "Cambio pendiente de sincronización"
            return
        }

        do {
            _ = try await api.updateTodo(id: serverID, completed: item.isCompleted)
            item.syncState = .synced
            lastSyncDate = .now
            lastMessage = "Estado actualizado con PATCH"
        } catch {
            item.syncState = .pending
            queueToggle(for: item, using: context, error: error.localizedDescription)
            lastMessage = "Cambio guardado localmente"
        }
        try? context.save()
    }

    func syncPendingChanges(using context: ModelContext) async throws {
        guard !isSyncing else {
            // refresh ya marca isSyncing; aun así debe procesar su cola.
            try await processPendingChanges(using: context)
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        try await processPendingChanges(using: context)
    }

    func logout() {
        keychain.deleteToken()
        currentUser = nil
        launchState = .loggedOut
        lastMessage = "Sesión cerrada"
    }

    func resetLocalData(using context: ModelContext) {
        do {
            for item in try context.fetch(FetchDescriptor<CampusTaskItem>()) { context.delete(item) }
            for course in try context.fetch(FetchDescriptor<CourseRecord>()) { context.delete(course) }
            for change in try context.fetch(FetchDescriptor<PendingMutation>()) { context.delete(change) }
            try context.save()
            try seedDemoDataIfNeeded(using: context)
            lastMessage = "Datos de demostración restaurados"
        } catch {
            presentedError = friendly(error)
        }
    }

    private func processPendingChanges(using context: ModelContext) async throws {
        let descriptor = FetchDescriptor<PendingMutation>(sortBy: [SortDescriptor(\.createdAt)])
        let pending = try context.fetch(descriptor)
        guard !pending.isEmpty else {
            lastSyncDate = .now
            lastMessage = "No hay cambios pendientes"
            return
        }

        let tasks = try context.fetch(FetchDescriptor<CampusTaskItem>())
        let taskByID = Dictionary(uniqueKeysWithValues: tasks.map { ($0.localID, $0) })

        for change in pending {
            guard let item = taskByID[change.taskLocalID] else {
                context.delete(change)
                continue
            }
            item.syncState = .syncing

            do {
                switch change.kind {
                case .create:
                    let response = try await api.createTodo(
                        title: item.title,
                        completed: item.isCompleted,
                        userID: currentUser?.id ?? 1
                    )
                    item.serverID = response.id
                case .toggle:
                    if let serverID = item.serverID, serverID <= 150 {
                        _ = try await api.updateTodo(id: serverID, completed: item.isCompleted)
                    }
                }
                item.syncState = .synced
                context.delete(change)
            } catch {
                item.syncState = .failed
                change.attempts += 1
                change.lastError = error.localizedDescription
                throw error
            }
        }

        try context.save()
        lastSyncDate = .now
        lastMessage = "Cambios pendientes sincronizados"
    }

    private func queueCreate(for item: CampusTaskItem, using context: ModelContext, error: String? = nil) {
        context.insert(PendingMutation(
            taskLocalID: item.localID,
            kind: .create,
            title: item.title,
            completed: item.isCompleted,
            lastError: error
        ))
    }

    private func queueToggle(for item: CampusTaskItem, using context: ModelContext, error: String? = nil) {
        context.insert(PendingMutation(
            taskLocalID: item.localID,
            serverID: item.serverID,
            kind: .toggle,
            completed: item.isCompleted,
            lastError: error
        ))
    }

    private func upsert(courses: [CourseDTO], using context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<CourseRecord>())
        let byCode = Dictionary(uniqueKeysWithValues: existing.map { ($0.code, $0) })
        for course in courses {
            if let stored = byCode[course.id] {
                stored.name = course.name
                stored.instructor = course.instructor
                stored.room = course.room
                stored.colorHex = course.colorHex
                stored.schedule = course.schedule
            } else {
                context.insert(CourseRecord(
                    code: course.id,
                    name: course.name,
                    instructor: course.instructor,
                    room: course.room,
                    colorHex: course.colorHex,
                    schedule: course.schedule
                ))
            }
        }
        try context.save()
    }

    private func upsert(remoteTasks: [RemoteTodoDTO], courses: [CourseDTO], using context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<CampusTaskItem>())
        let byServerID = Dictionary(uniqueKeysWithValues: existing.compactMap { item in
            item.serverID.map { ($0, item) }
        })
        let calendar = Calendar.current

        for (index, remote) in remoteTasks.enumerated() {
            if let stored = byServerID[remote.id] {
                if stored.syncState == .synced { stored.isCompleted = remote.completed }
                continue
            }
            let course = courses[index % courses.count]
            let offset = index == 1 ? -2 : index + 1
            let dueDate = calendar.date(byAdding: .day, value: offset, to: .now) ?? .now
            context.insert(CampusTaskItem(
                serverID: remote.id,
                title: DemoContent.academicTitles[index % DemoContent.academicTitles.count],
                notes: "\(DemoContent.notes[index % DemoContent.notes.count])\n\nTexto recibido por la API: \(remote.title)",
                courseName: course.name,
                courseCode: course.id,
                colorHex: course.colorHex,
                dueDate: dueDate,
                isCompleted: remote.completed,
                syncState: .synced
            ))
        }
        try context.save()
    }

    private func seedDemoDataIfNeeded(using context: ModelContext) throws {
        let courseCount = try context.fetchCount(FetchDescriptor<CourseRecord>())
        if courseCount == 0 { try upsert(courses: DemoContent.courses, using: context) }

        let taskCount = try context.fetchCount(FetchDescriptor<CampusTaskItem>())
        guard taskCount == 0 else { return }
        let calendar = Calendar.current
        for index in 0..<8 {
            let course = DemoContent.courses[index % DemoContent.courses.count]
            let offset = index == 0 ? -1 : index + 1
            context.insert(CampusTaskItem(
                title: DemoContent.academicTitles[index],
                notes: DemoContent.notes[index % DemoContent.notes.count],
                courseName: course.name,
                courseCode: course.id,
                colorHex: course.colorHex,
                dueDate: calendar.date(byAdding: .day, value: offset, to: .now) ?? .now,
                isCompleted: index == 3 || index == 6,
                syncState: .synced
            ))
        }
        try context.save()
    }

    private func cachedDemoUser() -> UserProfile {
        UserProfile(id: 1, fullName: "Emily Johnson", email: "emily.johnson@campus.demo", username: "emilys")
    }

    private func friendly(_ error: Error) -> String {
        if let localized = error as? LocalizedError, let message = localized.errorDescription {
            return message
        }
        return "No se pudo completar la operación: \(error.localizedDescription)"
    }
}

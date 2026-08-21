import Foundation
import SwiftData

enum ActivityStatus: String, CaseIterable, Identifiable, Equatable {
    case pending = "Pendiente"
    case completed = "Completada"
    case overdue = "Vencida"

    var id: String { rawValue }
}

enum SyncState: String, Codable, Equatable {
    case synced
    case pending
    case syncing
    case failed
}

enum MutationKind: String, Codable, Equatable {
    case create
    case toggle
}

@Model
final class CampusTaskItem {
    @Attribute(.unique) var localID: UUID
    var serverID: Int?
    var title: String
    var notes: String
    var courseName: String
    var courseCode: String
    var colorHex: String
    var dueDate: Date
    var isCompleted: Bool
    var syncStateRaw: String
    var createdAt: Date
    var updatedAt: Date

    init(
        localID: UUID = UUID(),
        serverID: Int? = nil,
        title: String,
        notes: String = "",
        courseName: String,
        courseCode: String,
        colorHex: String,
        dueDate: Date,
        isCompleted: Bool = false,
        syncState: SyncState = .synced,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.localID = localID
        self.serverID = serverID
        self.title = title
        self.notes = notes
        self.courseName = courseName
        self.courseCode = courseCode
        self.colorHex = colorHex
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.syncStateRaw = syncState.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .pending }
        set { syncStateRaw = newValue.rawValue }
    }

    var status: ActivityStatus {
        if isCompleted { return .completed }
        return dueDate < .now ? .overdue : .pending
    }
}

@Model
final class CourseRecord {
    @Attribute(.unique) var code: String
    var name: String
    var instructor: String
    var room: String
    var colorHex: String
    var schedule: String

    init(code: String, name: String, instructor: String, room: String, colorHex: String, schedule: String) {
        self.code = code
        self.name = name
        self.instructor = instructor
        self.room = room
        self.colorHex = colorHex
        self.schedule = schedule
    }
}

@Model
final class PendingMutation {
    @Attribute(.unique) var id: UUID
    var taskLocalID: UUID
    var serverID: Int?
    var kindRaw: String
    var title: String?
    var completed: Bool?
    var createdAt: Date
    var attempts: Int
    var lastError: String?

    init(
        id: UUID = UUID(),
        taskLocalID: UUID,
        serverID: Int? = nil,
        kind: MutationKind,
        title: String? = nil,
        completed: Bool? = nil,
        createdAt: Date = .now,
        attempts: Int = 0,
        lastError: String? = nil
    ) {
        self.id = id
        self.taskLocalID = taskLocalID
        self.serverID = serverID
        self.kindRaw = kind.rawValue
        self.title = title
        self.completed = completed
        self.createdAt = createdAt
        self.attempts = attempts
        self.lastError = lastError
    }

    var kind: MutationKind {
        MutationKind(rawValue: kindRaw) ?? .create
    }
}

struct CourseDTO: Identifiable, Sendable {
    let id: String
    let name: String
    let instructor: String
    let room: String
    let colorHex: String
    let schedule: String
}

struct UserProfile: Sendable {
    let id: Int
    let fullName: String
    let email: String
    let username: String
}

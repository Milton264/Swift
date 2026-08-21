import Foundation

struct LoginRequest: Encodable, Sendable {
    let username: String
    let password: String
    let expiresInMins: Int = 60
}

struct LoginResponse: Decodable, Sendable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let accessToken: String
    let refreshToken: String?
}

struct UserProfileDTO: Decodable, Sendable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
}

struct TodoListResponse: Decodable, Sendable {
    let todos: [RemoteTodoDTO]
    let total: Int
    let skip: Int
    let limit: Int
}

struct RemoteTodoDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let completed: Bool
    let userID: Int
    let deletedOn: Date?

    // TEMA 5.3: el JSON usa "todo" y "userId", pero el modelo Swift
    // conserva nombres expresivos. deletedOn es opcional y puede ser una fecha ISO-8601.
    enum CodingKeys: String, CodingKey {
        case id
        case title = "todo"
        case completed
        case userID = "userId"
        case deletedOn
    }
}

struct CreateTodoRequest: Encodable, Sendable {
    let todo: String
    let completed: Bool
    let userId: Int
}

struct UpdateTodoRequest: Encodable, Sendable {
    let completed: Bool
}

struct CreatedTodoResponse: Decodable, Sendable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int, String)
    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La dirección del servidor no es válida."
        case .invalidResponse:
            return "El servidor devolvió una respuesta que no se pudo interpretar."
        case let .httpStatus(code, message):
            return "Error HTTP \(code): \(message)"
        case let .invalidDate(value):
            return "La fecha \(value) no tiene un formato ISO-8601 válido."
        }
    }
}

struct CampusAPI: Sendable {
    private let baseURL = URL(string: "https://dummyjson.com")!

    func login(username: String, password: String) async throws -> LoginResponse {
        var request = URLRequest(url: baseURL.appending(path: "auth/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LoginRequest(username: username, password: password))
        return try await send(request)
    }

    func fetchProfile(token: String) async throws -> UserProfileDTO {
        var request = URLRequest(url: baseURL.appending(path: "auth/me"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await send(request)
    }

    func fetchTodos() async throws -> [RemoteTodoDTO] {
        var components = URLComponents(url: baseURL.appending(path: "todos"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "limit", value: "10")]
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let response: TodoListResponse = try await send(request)
        return response.todos
    }

    func fetchCourses() async throws -> [CourseDTO] {
        // Simula una tercera fuente para que async let muestre tres cargas simultáneas.
        try await Task.sleep(nanoseconds: 450_000_000)
        return DemoContent.courses
    }

    func createTodo(title: String, completed: Bool, userID: Int) async throws -> CreatedTodoResponse {
        var request = URLRequest(url: baseURL.appending(path: "todos/add"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            CreateTodoRequest(todo: title, completed: completed, userId: userID)
        )
        return try await send(request)
    }

    func updateTodo(id: Int, completed: Bool) async throws -> RemoteTodoDTO {
        var request = URLRequest(url: baseURL.appending(path: "todos/\(id)"))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(UpdateTodoRequest(completed: completed))
        return try await send(request)
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        // TEMA 5.2: URLSession usa async/await y siempre valida el código HTTP.
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Sin detalle"
            throw APIError.httpStatus(http.statusCode, body)
        }

        // TEMA 5.3: Codable, convertFromSnakeCase, opcionales y fechas ISO-8601.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) { return date }
            throw APIError.invalidDate(value)
        }
        return try decoder.decode(Response.self, from: data)
    }
}

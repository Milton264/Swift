import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = true
    @Published private(set) var connectionName = "Comprobando…"

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "CampusTask.NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let name: String
            if path.usesInterfaceType(.wifi) {
                name = "Wi-Fi"
            } else if path.usesInterfaceType(.cellular) {
                name = "Datos móviles"
            } else if connected {
                name = "Conectado"
            } else {
                name = "Sin conexión"
            }
            Task { @MainActor in
                self?.isConnected = connected
                self?.connectionName = name
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

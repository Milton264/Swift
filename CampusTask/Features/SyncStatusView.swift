import SwiftUI
import SwiftData

struct SyncStatusView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var network: NetworkMonitor
    @Query(sort: \PendingMutation.createdAt) private var pending: [PendingMutation]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                connectionCard
                syncSummary
                if pending.isEmpty { emptyQueue } else { pendingQueue }
                explanation
            }
            .padding(18)
        }
        .background(Color.primary.opacity(0.025))
        .navigationTitle("Sincronización")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var connectionCard: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill((network.isConnected ? Color.campusTeal : Color.campusOrange).opacity(0.13))
                    .frame(width: 58, height: 58)
                Image(systemName: network.isConnected ? "wifi" : "wifi.slash")
                    .font(.title2)
                    .foregroundStyle(network.isConnected ? Color.campusTeal : Color.campusOrange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(network.isConnected ? "Con conexión" : "Trabajando sin conexión")
                    .font(.headline)
                Text(network.connectionName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .campusCard()
    }

    private var syncSummary: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estado actual").font(.headline)
                    Text(appState.lastMessage).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if appState.isSyncing {
                    ProgressView().tint(Color.campusPurple)
                } else {
                    Image(systemName: pending.isEmpty ? "checkmark.circle.fill" : "clock.badge.exclamationmark.fill")
                        .font(.title2)
                        .foregroundStyle(pending.isEmpty ? Color.campusTeal : Color.campusOrange)
                }
            }
            Divider()
            HStack {
                Label("\(pending.count) cambios pendientes", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Spacer()
                Text(appState.lastSyncDate?.campusRelative ?? "Aún no sincronizado")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button {
                Task {
                    do {
                        try await appState.syncPendingChanges(using: modelContext)
                    } catch {
                        appState.presentedError = "La sincronización se detuvo: \(error.localizedDescription)"
                    }
                }
            } label: {
                Label("Sincronizar ahora", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(CampusPrimaryButtonStyle())
            .disabled(!network.isConnected || appState.isSyncing)
        }
        .campusCard()
    }

    private var emptyQueue: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.icloud.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color.campusTeal)
            Text("Todo está sincronizado").font(.headline)
            Text("Desactivá el internet, modificá una tarea y volvé aquí para crear un cambio pendiente.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .campusCard()
    }

    private var pendingQueue: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Cola local", subtitle: "Cambios almacenados con SwiftData")
            ForEach(pending, id: \.id) { change in
                HStack(spacing: 12) {
                    Image(systemName: change.kind == .create ? "plus.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(Color.campusOrange)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(change.kind == .create ? "Crear actividad" : "Cambiar estado")
                            .font(.subheadline.bold())
                        Text(change.createdAt.campusFormatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Intentos: \(change.attempts)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if change.id != pending.last?.id { Divider() }
            }
        }
        .campusCard()
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("¿Qué ocurre al volver el internet?")
            FlowStep(number: "1", text: "NWPathMonitor detecta la conexión.")
            FlowStep(number: "2", text: "Task inicia la sincronización sin bloquear la interfaz.")
            FlowStep(number: "3", text: "URLSession envía POST o PATCH y valida el código HTTP.")
            FlowStep(number: "4", text: "SwiftData elimina el cambio de la cola local.")
        }
        .campusCard()
    }
}

private struct FlowStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.campusPurple, in: Circle())
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }
}

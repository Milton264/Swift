import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @State private var username = "emilys"
    @State private var password = "emilyspass"
    @State private var showPassword = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F4F2FF"), Color(hex: "EDF8F8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    loginCard
                    demoNote
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 36)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(Color.campusPurple)
                    .frame(width: 82, height: 82)
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 37))
                    .foregroundStyle(.white)
            }
            Text("CampusTask")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.campusInk)
            Text("Organizá tus actividades desde cualquier lugar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Bienvenido").font(.title2.bold())
                Text("Ingresá con la cuenta pública de demostración.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Usuario").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Label {
                    TextField("Usuario", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } icon: {
                    Image(systemName: "person")
                        .foregroundStyle(.campusPurple)
                }
                .padding(13)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 13))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "lock")
                        .foregroundStyle(.campusPurple)
                    Group {
                        if showPassword {
                            TextField("Contraseña", text: $password)
                        } else {
                            SecureField("Contraseña", text: $password)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(13)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 13))
            }

            Button {
                Task { await appState.login(username: username, password: password, using: modelContext) }
            } label: {
                if appState.isBusy {
                    ProgressView().tint(.white)
                } else {
                    Label("Iniciar sesión", systemImage: "arrow.right")
                }
            }
            .buttonStyle(CampusPrimaryButtonStyle())
            .disabled(appState.isBusy)

            Button {
                appState.enterOfflineDemo(using: modelContext)
            } label: {
                Label("Entrar en modo demostración offline", systemImage: "wifi.slash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.campusPurple)
        }
        .campusCard()
        .shadow(color: .campusPurple.opacity(0.12), radius: 30, y: 14)
    }

    private var demoNote: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "key.fill").foregroundStyle(.campusTeal)
            Text("El token recibido se guarda en Keychain. El usuario y la contraseña visibles pertenecen únicamente a la API pública de prueba.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
    }
}

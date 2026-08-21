import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system = "Sistema"
    case light = "Claro"
    case dark = "Oscuro"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "Todas"
    case pending = "Pendientes"
    case completed = "Completadas"
    case overdue = "Vencidas"

    var id: String { rawValue }
}

extension Color {
    static let campusPurple = Color(hex: "6D5DFB")
    static let campusInk = Color(hex: "171A2D")
    static let campusTeal = Color(hex: "0EA5A8")
    static let campusOrange = Color(hex: "F59E0B")
    static let campusPink = Color(hex: "EF5DA8")

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red, green, blue: UInt64
        switch cleaned.count {
        case 3:
            (red, green, blue) = ((value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        default:
            (red, green, blue) = (value >> 16, value >> 8 & 0xFF, value & 0xFF)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}

struct CampusCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.primary.opacity(0.07), lineWidth: 1)
            }
    }
}

extension View {
    func campusCard() -> some View { modifier(CampusCard()) }
}

struct CampusPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.campusPurple, Color(hex: "8B7CFF")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct StatusPill: View {
    let status: ActivityStatus

    private var tint: Color {
        switch status {
        case .pending: return .campusOrange
        case .completed: return .campusTeal
        case .overdue: return .red
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct SyncPill: View {
    let state: SyncState

    private var label: String {
        switch state {
        case .synced: return "Sincronizada"
        case .pending: return "Pendiente"
        case .syncing: return "Sincronizando"
        case .failed: return "Reintentar"
        }
    }

    private var icon: String {
        switch state {
        case .synced: return "checkmark.icloud.fill"
        case .pending: return "icloud.slash"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .failed: return "exclamationmark.icloud.fill"
        }
    }

    private var tint: Color {
        switch state {
        case .synced: return .campusTeal
        case .pending: return .campusOrange
        case .syncing: return .campusPurple
        case .failed: return .red
        }
    }

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title3.bold())
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension Date {
    var campusRelative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    var campusFormatted: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}

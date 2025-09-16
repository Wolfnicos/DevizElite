import SwiftUI
import AppKit

final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: String = "system" { didSet { updateTheme() } }
    @Published var currentTheme: Theme = .system

    enum Theme: String, CaseIterable, Identifiable {
        case light, dark, system
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .light: return L10n.t("Light")
            case .dark: return L10n.t("Dark")
            case .system: return L10n.t("System")
            }
        }
        var icon: String {
            switch self {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .system: return "circle.lefthalf.filled"
            }
        }
    }

    init() { updateTheme() }

    func setTheme(_ theme: Theme) {
        selectedTheme = theme.rawValue
        currentTheme = theme
        applyAppearance(for: theme)
    }

    func updateTheme() {
        let theme = Theme(rawValue: selectedTheme) ?? .system
        currentTheme = theme
        applyAppearance(for: theme)
    }

    private func applyAppearance(for theme: Theme) {
        switch theme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
    }
}


extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

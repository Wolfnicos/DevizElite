import SwiftUI

enum UITheme {
    // MARK: - Color Palette (2025)
    static let primaryBlue = Color(red: 0/255, green: 102/255, blue: 255/255)
    static let primaryDark = Color(red: 0/255, green: 26/255, blue: 61/255)
    static let accentGreen = Color(red: 0/255, green: 200/255, blue: 150/255)
    static let accentOrange = Color(red: 255/255, green: 107/255, blue: 53/255)
    static let accentPurple = Color(red: 123/255, green: 97/255, blue: 255/255)

    static let gray50 = Color(nsColor: .controlBackgroundColor)
    static let gray100 = Color(white: 0.96)
    static let gray200 = Color(white: 0.93)
    static let gray300 = Color(white: 0.88)
    static let gray400 = Color(white: 0.74)
    static let gray500 = Color(white: 0.62)
    static let gray600 = Color(white: 0.46)
    static let gray700 = Color(white: 0.38)
    static let gray800 = Color(white: 0.26)
    static let gray900 = Color(white: 0.13)

    static let successGreen = Color(red: 76/255, green: 175/255, blue: 80/255)
    static let warningYellow = Color(red: 255/255, green: 193/255, blue: 7/255)
    static let errorRed = Color(red: 244/255, green: 67/255, blue: 54/255)
    static let infoBlue = Color(red: 33/255, green: 150/255, blue: 243/255)
    enum Mode: String, CaseIterable { case system, light, dark }
    static var mode: Mode {
        get { Mode(rawValue: UserDefaults.standard.string(forKey: "ThemeMode") ?? "system") ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "ThemeMode") }
    }
    static let accent = primaryBlue
    static let cardBackground = gray50
    static let cardStroke = Color.black.opacity(0.06)
    static let subtleShadow = Color.black.opacity(0.08)

    struct Card: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(12)
                .background(UITheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(UITheme.cardStroke))
                .cornerRadius(10)
                .shadow(color: UITheme.subtleShadow, radius: 6, x: 0, y: 2)
        }
    }

    struct PrimaryButton: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(UITheme.accent)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: UITheme.subtleShadow, radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.15), value: UUID())
        }
    }
}

extension View {
    func themedCard() -> some View { modifier(UITheme.Card()) }
    func primaryButton() -> some View { modifier(UITheme.PrimaryButton()) }
}



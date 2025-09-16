import SwiftUI

// MARK: - Modern Design System for Construction Invoicing App
// Premium, clean, and professional design inspired by 2024 trends

public struct DesignSystem {
    
    // MARK: - Colors
    public struct Colors {
        // Primary Brand Colors
        public static let primary = Color(hex: "1E40AF")      // Deep Blue
        public static let primaryLight = Color(hex: "3B82F6") // Bright Blue
        public static let primaryDark = Color(hex: "1E3A8A")  // Navy Blue
        
        // Accent Colors
        public static let accent = Color("AccentColor")
        public static let success = Color.green
        public static let warning = Color(hex: "F59E0B")      // Amber
        public static let danger = Color(hex: "EF4444")       // Red
        public static let info = Color(hex: "6366F1")         // Indigo
        
        // Neutral Colors
        public static let background = Color(.windowBackgroundColor)
        public static let surface = Color.white
        public static let surfaceSecondary = Color(hex: "F3F4F6")
        public static let border = Color(hex: "E5E7EB")
        public static let borderLight = Color(hex: "F3F4F6")
        
        // Text Colors
        public static let textPrimary = Color(hex: "111827")
        public static let textSecondary = Color(hex: "6B7280")
        public static let textTertiary = Color(hex: "9CA3AF")
        public static let textOnPrimary = Color.white
        
        // Status Colors
        public static let statusDraft = Color(hex: "6B7280")
        public static let statusPending = Color(hex: "F59E0B")
        public static let statusPaid = Color(hex: "10B981")
        public static let statusOverdue = Color(hex: "EF4444")
        public static let statusCancelled = Color(hex: "9CA3AF")
    }
    
    // MARK: - Typography
    public struct Typography {
        // Headers
        public static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        public static let title1 = Font.system(size: 28, weight: .semibold, design: .rounded)
        public static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        public static let title3 = Font.system(size: 20, weight: .medium, design: .rounded)
        
        // Body
        public static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        public static let body = Font.system(size: 15, weight: .regular, design: .default)
        public static let bodyBold = Font.system(size: 15, weight: .semibold, design: .default)
        public static let callout = Font.system(size: 14, weight: .regular, design: .default)
        public static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        public static let caption = Font.system(size: 12, weight: .regular, design: .default)
        public static let captionBold = Font.system(size: 12, weight: .medium, design: .default)
        
        // Monospace for numbers
        public static let numberLarge = Font.system(size: 24, weight: .semibold, design: .monospaced)
        public static let numberMedium = Font.system(size: 18, weight: .medium, design: .monospaced)
        public static let numberSmall = Font.system(size: 14, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Spacing
    public struct Spacing {
        public static let xxxs: CGFloat = 2
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    public struct CornerRadius {
        public static let small: CGFloat = 6
        public static let medium: CGFloat = 10
        public static let large: CGFloat = 14
        public static let xlarge: CGFloat = 20
        public static let full: CGFloat = 999
    }
    
    // MARK: - Shadows
    public struct Shadows {
        public static let small = (color: Color.black.opacity(0.05), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        public static let medium = (color: Color.black.opacity(0.08), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        public static let large = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        public static let xlarge = (color: Color.black.opacity(0.15), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
    
    // MARK: - Animation
    public struct Animation {
        public static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        public static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        public static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom View Modifiers
struct CardStyle: ViewModifier {
    var isHovered: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(
                color: Color.black.opacity(isHovered ? 0.12 : 0.08),
                radius: isHovered ? 12 : 8,
                x: 0,
                y: isHovered ? 6 : 4
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(DesignSystem.Animation.fast, value: isHovered)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyBold)
            .foregroundColor(DesignSystem.Colors.textOnPrimary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(configuration.isPressed ? 
                          DesignSystem.Colors.primaryDark : 
                          DesignSystem.Colors.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyBold)
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(configuration.isPressed ? 
                                  DesignSystem.Colors.primary.opacity(0.1) : 
                                  Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .foregroundColor(configuration.isPressed ? 
                           DesignSystem.Colors.primaryDark : 
                           DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(configuration.isPressed ? 
                          DesignSystem.Colors.primary.opacity(0.1) : 
                          Color.clear)
            )
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(isHovered: Bool = false) -> some View {
        self.modifier(CardStyle(isHovered: isHovered))
    }
    
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func ghostButton() -> some View {
        self.buttonStyle(GhostButtonStyle())
    }
}

// MARK: - Status Badge Component
struct StatusBadge: View {
    let status: InvoiceStatus
    
    var backgroundColor: Color {
        switch status {
        case .all: return DesignSystem.Colors.surface
        case .draft: return DesignSystem.Colors.statusDraft.opacity(0.1)
        case .pending: return DesignSystem.Colors.statusPending.opacity(0.1)
        case .paid: return DesignSystem.Colors.statusPaid.opacity(0.1)
        case .overdue: return DesignSystem.Colors.statusOverdue.opacity(0.1)
        case .cancelled: return DesignSystem.Colors.statusCancelled.opacity(0.1)
        }
    }
    
    var textColor: Color {
        switch status {
        case .all: return DesignSystem.Colors.textPrimary
        case .draft: return DesignSystem.Colors.info
        case .pending: return DesignSystem.Colors.warning
        case .paid: return DesignSystem.Colors.success
        case .overdue: return DesignSystem.Colors.statusOverdue
        case .cancelled: return DesignSystem.Colors.statusCancelled
        }
    }
    
    var icon: String {
        switch status {
        case .all: return "doc.text.magnifyingglass"
        case .draft: return "pencil.circle.fill"
        case .pending: return "hourglass.circle.fill"
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(status.displayName)
                .font(DesignSystem.Typography.captionBold)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
    }
}

// MARK: - Invoice Status Enum
enum InvoiceStatus: String, CaseIterable, Codable {
    case all = "All"
    case draft = "Draft"
    case pending = "Pending"
    case paid = "Paid"
    case overdue = "Overdue"
    case cancelled = "Cancelled"
    
    var displayName: String {
        switch self {
        case .all: return L10n.t("All")
        case .draft: return L10n.t("Draft")
        case .pending: return L10n.t("Pending")
        case .paid: return L10n.t("Paid")
        case .overdue: return L10n.t("Overdue")
        case .cancelled: return L10n.t("Cancelled")
        }
    }
}

public struct ModernTextFieldStyle: TextFieldStyle {
    var compact: Bool = false
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(compact ? 8 : 12)
    }
}

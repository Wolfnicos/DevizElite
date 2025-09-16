import SwiftUI

struct ModernSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var i18n: LocalizationService
    @StateObject private var themeManager = ThemeManager()
    
    // Company Info
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("companyTaxId") private var companyTaxId = ""
    @AppStorage("companyAddress") private var companyAddress = ""
    @AppStorage("companyCity") private var companyCity = ""
    @AppStorage("companyPhone") private var companyPhone = ""
    @AppStorage("companyEmail") private var companyEmail = ""
    @AppStorage("companyIBAN") private var companyIBAN = ""
    @AppStorage("companyBank") private var companyBank = ""
    
    @State private var selectedTab = 0
    // Invoicing defaults
    @AppStorage("defaultVATRate") private var defaultVATRate: Double = 20.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Tab Selection
            tabSelector
            
            // Content
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    switch selectedTab {
                    case 0:
                        generalSettings
                    case 1:
                        companySettings
                    case 2:
                        invoiceSettings
                    default:
                        generalSettings
                    }
                }
                .padding(DesignSystem.Spacing.xl)
            }
            
            Divider()
            
            // Footer with Save
            footerView
        }
        .frame(width: 700, height: 600)
        .background(DesignSystem.Colors.background)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("Settings"))
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(L10n.t("Configure the app to your preferences"))
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .background(Circle().fill(DesignSystem.Colors.surface))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.surface)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "General", icon: "gearshape", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: L10n.t("Company"), icon: "building.2", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabButton(title: L10n.t("Invoicing"), icon: "doc.text", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.surface)
    }
    
    // MARK: - General Settings
    private var generalSettings: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Language Section
            SettingSection(title: L10n.t("Language"), icon: "globe") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    ForEach([
                        ("en", "🇬🇧", "English"),
                        ("fr", "🇫🇷", "Français")
                    ], id: \.0) { code, flag, name in
                        LanguageOption(
                            flag: flag,
                            name: name,
                            isSelected: i18n.languageCode == code
                        ) {
                            i18n.setLanguage(code)
                        }
                    }
                }
            }
            
            // Theme Section
            SettingSection(title: L10n.t("Theme"), icon: "paintbrush") {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ThemeOption(
                        title: L10n.t("System"),
                        icon: "laptopcomputer",
                        isSelected: themeManager.selectedTheme == "system"
                    ) {
                        themeManager.setTheme(.system)
                    }
                    
                    ThemeOption(
                        title: L10n.t("Light"),
                        icon: "sun.max",
                        isSelected: themeManager.selectedTheme == "light"
                    ) {
                        themeManager.setTheme(.light)
                    }
                    
                    ThemeOption(
                        title: L10n.t("Dark"),
                        icon: "moon",
                        isSelected: themeManager.selectedTheme == "dark"
                    ) {
                        themeManager.setTheme(.dark)
                    }
                }
            }
        }
    }
    
    // MARK: - Company Settings
    private var companySettings: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            SettingSection(title: L10n.t("Company Information"), icon: "building.2") {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ModernTextField(
                        label: L10n.t("Company Name"),
                        text: $companyName,
                        placeholder: L10n.t("Ex: Company Ltd")
                    )
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ModernTextField(
                            label: L10n.t("VAT / Tax ID"),
                            text: $companyTaxId,
                            placeholder: L10n.t("FR123456789")
                        )
                        
                        ModernTextField(
                            label: L10n.t("Phone"),
                            text: $companyPhone,
                            placeholder: "+33 1 23 45 67 89"
                        )
                    }
                    
                    ModernTextField(
                        label: L10n.t("Email"),
                        text: $companyEmail,
                        placeholder: "contact@example.com"
                    )
                    
                    ModernTextField(
                        label: L10n.t("Address"),
                        text: $companyAddress,
                        placeholder: L10n.t("Street and number")
                    )
                    
                    ModernTextField(
                        label: L10n.t("City"),
                        text: $companyCity,
                        placeholder: "Paris"
                    )
                }
            }
            
            SettingSection(title: L10n.t("Bank Information"), icon: "creditcard") {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ModernTextField(
                        label: "IBAN",
                        text: $companyIBAN,
                        placeholder: "FR76 3000 4008 0400 0123 4567 890"
                    )
                    
                    ModernTextField(
                        label: L10n.t("Bank"),
                        text: $companyBank,
                        placeholder: "BNP Paribas"
                    )
                }
            }
        }
    }
    
    // MARK: - Invoice Settings
    private var invoiceSettings: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            SettingSection(title: L10n.t("Invoicing Settings"), icon: "doc.text") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    // Invoice prefix
                    ModernTextField(
                        label: L10n.t("Invoice Prefix"),
                        text: .constant("INV"),
                        placeholder: "INV"
                    )
                    .disabled(true)
                    
                    // Estimate prefix
                    ModernTextField(
                        label: L10n.t("Quote Prefix"),
                        text: .constant("EST"),
                        placeholder: "EST"
                    )
                    .disabled(true)
                    
                    // Default payment terms
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(L10n.t("Default Payment Terms"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Picker("", selection: .constant(30)) {
                            Text("15 days").tag(15)
                            Text("30 days").tag(30)
                            Text("45 days").tag(45)
                            Text("60 days").tag(60)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                    }
                }
            }
            
            SettingSection(title: L10n.t("Default VAT"), icon: "percent") {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ForEach([0.0, 5.5, 10.0, 20.0], id: \.self) { rate in
                        VATOption(
                            rate: rate,
                            isSelected: rate == defaultVATRate
                        ) {
                            defaultVATRate = rate
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Button(L10n.t("Cancel")) {
                dismiss()
            }
            .secondaryButton()
            
            Spacer()
            
            Button(L10n.t("Save")) {
                saveSettings()
            }
            .primaryButton()
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.surface)
    }
    
    private func saveSettings() {
        // Settings are automatically saved via @AppStorage
        dismiss()
    }
}

// MARK: - Supporting Views
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                VStack {
                    Spacer()
                    if isSelected {
                        Rectangle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(height: 2)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Label(title, systemImage: icon)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            content()
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.CornerRadius.medium)
        }
    }
}

struct LanguageOption: View {
    let flag: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(flag)
                    .font(.system(size: 24))
                Text(name)
                    .font(DesignSystem.Typography.body)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(DesignSystem.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemeOption: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VATOption: View {
    let rate: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(rate.clean)%")
                .font(DesignSystem.Typography.bodyBold)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .frame(width: 60, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceSecondary)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernTextField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.surfaceSecondary)
                .cornerRadius(DesignSystem.CornerRadius.small)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.6 : 1.0)
        }
    }
}

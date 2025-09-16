import SwiftUI
import CoreData
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var i18n: LocalizationService
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "OpenExchangeRatesAPIKey") ?? ""

    var body: some View {
        Form {
            Section(header: Text(L10n.t("Language"))) {
                Menu {
                    Button(action: { changeLang("fr") }) { Text("🇫🇷 Français") ; if i18n.languageCode.hasPrefix("fr") { Image(systemName: "checkmark") } }
                    Button(action: { changeLang("en") }) { Text("🇬🇧 English") ; if i18n.languageCode.hasPrefix("en") { Image(systemName: "checkmark") } }
                    Button(action: { changeLang("ro") }) { Text("🇷🇴 Română") ; if i18n.languageCode.hasPrefix("ro") { Image(systemName: "checkmark") } }
                    Button(action: { changeLang("es") }) { Text("🇪🇸 Español") ; if i18n.languageCode.hasPrefix("es") { Image(systemName: "checkmark") } }
                    Button(action: { changeLang("de") }) { Text("🇩🇪 Deutsch") ; if i18n.languageCode.hasPrefix("de") { Image(systemName: "checkmark") } }
                } label: {
                    HStack { Text(L10n.t("App Language")); Spacer(); Text(displayLang(i18n.languageCode)) }
                }
            }
            Section(header: Text(L10n.t("Appearance"))) {
                Picker(L10n.t("Theme"), selection: Binding(
                    get: { themeManager.currentTheme.rawValue },
                    set: { themeManager.setTheme(ThemeManager.Theme(rawValue: $0) ?? .system) }
                )) {
                    ForEach(ThemeManager.Theme.allCases) { t in
                        Text(t.displayName).tag(t.rawValue)
                    }
                }
            }
            Section(header: Text(L10n.t("Currency"))) {
                TextField(L10n.t("OpenExchangeRates API Key"), text: $apiKey)
                    .onSubmit { UserDefaults.standard.set(apiKey, forKey: "OpenExchangeRatesAPIKey") }
            }
            Section(header: Text(L10n.t("Backup"))) {
                HStack {
                    Button(L10n.t("Export Backup")) { exportBackup() }
                    Button(L10n.t("Import Backup")) { importBackup() }
                }
            }
            Section(header: Text(L10n.t("Notifications"))) {
                Toggle(L10n.t("Enable Notifications"), isOn: Binding(get: { NotificationService.shared.enabled }, set: { newVal in
                    NotificationService.shared.enabled = newVal
                    if newVal { NotificationService.shared.requestAuthorization(); NotificationService.shared.scheduleDueNotifications(context: viewContext) }
                }))
                Stepper(value: Binding(get: { NotificationService.shared.daysBeforeDue }, set: { NotificationService.shared.daysBeforeDue = $0; NotificationService.shared.scheduleDueNotifications(context: viewContext) }), in: 1...14) {
                    Text("\(L10n.t("Days before due")): \(NotificationService.shared.daysBeforeDue)")
                }
                Button(L10n.t("Send Test Notification")) { NotificationService.shared.requestAuthorization(); NotificationService.shared.sendTest() }
            }
        }
        .padding(20)
    }

    private func changeLang(_ code: String) {
        i18n.setLanguage(code)
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }

    private func displayLang(_ code: String) -> String {
        if code.hasPrefix("fr") { return "Français" }
        if code.hasPrefix("ro") { return "Română" }
        if code.hasPrefix("es") { return "Español" }
        if code.hasPrefix("de") { return "Deutsch" }
        return "English"
    }

    private func exportBackup() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.database]
        panel.nameFieldStringValue = "InvoiceMasterProBackup.sqlite"
        if panel.runModal() == .OK, let url = panel.url {
            do { try BackupService.shared.exportBackup(to: url, context: viewContext) } catch { print(error) }
        }
    }

    private func importBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.database]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            do { try BackupService.shared.importBackup(from: url, into: viewContext) } catch { print(error) }
        }
    }
}

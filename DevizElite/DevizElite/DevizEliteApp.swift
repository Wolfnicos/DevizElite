import SwiftUI

@main
struct DevizEliteApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var localizationService = LocalizationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .environmentObject(localizationService)
                .preferredColorScheme(themeManager.selectedTheme == "dark" ? .dark : themeManager.selectedTheme == "light" ? .light : nil)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.automatic)
        .commands {
            // File Menu
            CommandGroup(after: .newItem) {
                Button("Factură Nouă") {
                    NotificationCenter.default.post(name: .actionNewInvoice, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("Deviz Nou") {
                    NotificationCenter.default.post(name: .actionNewEstimate, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Salvează") {
                    NotificationCenter.default.post(name: .actionSave, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command])
                
                Button("Exportă PDF") {
                    NotificationCenter.default.post(name: .actionExportPDF, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command])
            }
            
            // Edit Menu
            CommandGroup(after: .pasteboard) {
                Divider()
                Button("Duplică") {
                    NotificationCenter.default.post(name: .actionDuplicate, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command])
            }
            
            // View Menu
            CommandMenu("Vizualizare") {
                Button("Dashboard") {
                    NotificationCenter.default.post(name: .actionDashboard, object: nil)
                }
                .keyboardShortcut("1", modifiers: [.command])
                
                Button("Facturi") {
                    NotificationCenter.default.post(name: .actionInvoices, object: nil)
                }
                .keyboardShortcut("2", modifiers: [.command])
                
                Button("Devize") {
                    NotificationCenter.default.post(name: .actionEstimates, object: nil)
                }
                .keyboardShortcut("3", modifiers: [.command])
                
                Button("Clienți") {
                    NotificationCenter.default.post(name: .actionClients, object: nil)
                }
                .keyboardShortcut("4", modifiers: [.command])
                
                Divider()
                
                Button("Previzualizare") {
                    NotificationCenter.default.post(name: .actionPreview, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command])
            }
        }
    }
}
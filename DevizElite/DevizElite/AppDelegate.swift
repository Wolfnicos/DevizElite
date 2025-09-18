import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register for language change notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: .languageChanged, object: nil)
        
        // Fix for NSWindowRestoration warning - register window restoration
        UserDefaults.standard.register(defaults: [
            "NSApplicationCrashOnExceptions": true
        ])
        
        // Disable window restoration to prevent className null warning
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @objc private func handleLanguageChange() {
        let alert = NSAlert()
        alert.messageText = L10n.t("Language Change")
        alert.informativeText = L10n.t("The application needs to restart for the language change to take effect.")
        alert.addButton(withTitle: L10n.t("Restart Now"))
        alert.addButton(withTitle: L10n.t("Later"))
        if alert.runModal() == .alertFirstButtonReturn {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [Bundle.main.bundlePath]
            try? task.run()
            exit(0)
        }
    }
}



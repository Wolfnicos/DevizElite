import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: .languageChanged, object: nil)
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



import Foundation
import UserNotifications
import CoreData

final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var enabled: Bool {
        didSet { UserDefaults.standard.set(enabled, forKey: "notificationsEnabled") }
    }
    @Published var daysBeforeDue: Int {
        didSet { UserDefaults.standard.set(daysBeforeDue, forKey: "notificationsDaysBefore") }
    }

    private init() {
        self.enabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        let saved = UserDefaults.standard.integer(forKey: "notificationsDaysBefore")
        self.daysBeforeDue = saved == 0 ? 2 : saved
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error { NSLog("Notification auth error: \(error)") }
            DispatchQueue.main.async { self.enabled = granted }
        }
    }

    func scheduleDueNotifications(context: NSManagedObjectContext) {
        guard enabled else { return }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let fetch = NSFetchRequest<Document>(entityName: "Document")
        fetch.predicate = NSPredicate(format: "type == %@ AND status != %@ AND dueDate != nil", "invoice", "paid")
        if let docs = try? context.fetch(fetch) {
            for doc in docs {
                guard let due = doc.dueDate else { continue }
                let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBeforeDue, to: due) ?? due
                if triggerDate < Date() { continue }
                let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: triggerDate)
                let content = UNMutableNotificationContent()
                let number = doc.number ?? "#"
                content.title = L10n.t("Invoice Due Soon")
                content.body = String(format: L10n.t("Invoice %@ is due on %@."), number, formatDate(due))
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "invoice-due-\(doc.id?.uuidString ?? UUID().uuidString)"
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(req)
            }
        }
    }

    func sendTest() {
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = L10n.t("Test Notification")
        content.body = L10n.t("This is a test notification from InvoiceMaster Pro.")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let req = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date)
    }
}

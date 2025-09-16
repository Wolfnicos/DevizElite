import Foundation

extension Notification.Name {
    static let actionNewInvoice = Notification.Name("action.newInvoice")
    static let actionSave = Notification.Name("action.save")
    static let actionPreview = Notification.Name("action.preview")
    static let actionOpenSettings = Notification.Name("action.openSettings")
    static let languageChanged = Notification.Name("app.languageChanged")
    static let navigateDashboard = Notification.Name("nav.dashboard")
    static let navigateInvoices = Notification.Name("nav.invoices")
    static let navigateEstimates = Notification.Name("nav.estimates")
    static let navigateClients = Notification.Name("nav.clients")
    static let actionDuplicate = Notification.Name("action.duplicate")
    static let actionDelete = Notification.Name("action.delete")
    static let actionUndo = Notification.Name("action.undo")
    static let actionRedo = Notification.Name("action.redo")
    static let actionDashboard = Notification.Name("action.dashboard")
    static let actionInvoices = Notification.Name("action.invoices")
    static let actionEstimates = Notification.Name("action.estimates")
    static let actionClients = Notification.Name("action.clients")
    static let actionNewEstimate = Notification.Name("action.newEstimate")
    static let actionExportPDF = Notification.Name("action.exportPDF")
}

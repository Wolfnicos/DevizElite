//
//  InvoiceWindowController.swift
//  DevizElite
//
//  Created by App Gemini on 15/09/2025.
//

import AppKit
import SwiftUI
import CoreData

class InvoiceWindowController: NSWindowController, NSWindowDelegate {
    
    convenience init(document: Document?, context: NSManagedObjectContext, i18n: LocalizationService, type: String = "invoice") {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        if type == "estimate" {
            window.title = document == nil ? L10n.t("New Quote") : L10n.t("Edit Quote")
        } else {
            window.title = document == nil ? L10n.t("New Invoice") : L10n.t("Edit Invoice")
        }
        window.minSize = NSSize(width: 1200, height: 800)
        
        self.init(window: window)
        
        // This binding allows the SwiftUI view to close its hosting window.
        let isPresented = Binding<Bool>(
            get: { [weak window] in window?.isVisible ?? false },
            set: { [weak window] in if !$0 { window?.close() } }
        )
        
        let rootView: AnyView
        let documentToEdit: Document
        
        if let existingDocument = document {
            documentToEdit = existingDocument
        } else {
            // Create a new document for a new invoice/quote
            let newDocument = Document(context: context)
            newDocument.id = UUID()
            newDocument.type = type
            newDocument.status = "draft"
            newDocument.issueDate = Date()
            newDocument.number = type == "estimate" ? generateQuoteNumber(context: context) : generateInvoiceNumber(context: context)
            newDocument.currencyCode = "EUR"
            documentToEdit = newDocument
            // Note: We don't save here. The editor is responsible for the first save.
        }

        // Route to appropriate editor based on document type
        if isBTPDocument(documentToEdit) {
            rootView = AnyView(
                BTPDocumentEditorView(document: documentToEdit)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(i18n)
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CloseWindow"))) { _ in
                        window.close()
                    }
            )
        } else {
            rootView = AnyView(
                InvoiceEditorView(document: documentToEdit, isPresented: isPresented)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(i18n)
            )
        }
        
        window.contentView = NSHostingView(rootView: rootView)
        window.delegate = self
    }
    
    private func generateInvoiceNumber(context: NSManagedObjectContext) -> String {
        let year = Calendar.current.component(.year, from: Date())
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND number BEGINSWITH[c] %@", "invoice", "FA-\(year)")
        
        do {
            let count = try context.count(for: request)
            return "FA-\(year)-\(String(format: "%03d", count + 1))"
        } catch {
            // Fallback for safety
            return "FA-\(year)-\(String(format: "%03d", Int.random(in: 1...999)))"
        }
    }

    private func generateQuoteNumber(context: NSManagedObjectContext) -> String {
        let year = Calendar.current.component(.year, from: Date())
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND number BEGINSWITH[c] %@", "estimate", "DV-\(year)")
        do {
            let count = try context.count(for: request)
            return "DV-\(year)-\(String(format: "%04d", count + 1))"
        } catch {
            return "DV-\(year)-\(Int.random(in: 1000...9999))"
        }
    }
    
    // MARK: - Helper Methods
    
    private func isBTPDocument(_ document: Document) -> Bool {
        // Check if document has BTP-specific fields or settings
        if document.typeTravaux != nil { return true }
        if document.zoneTravaux != nil { return true }
        if document.projectName != nil && !(document.projectName?.isEmpty ?? true) { return true }
        if document.siteAddress != nil && !(document.siteAddress?.isEmpty ?? true) { return true }
        if document.permitNumber != nil && !(document.permitNumber?.isEmpty ?? true) { return true }
        
        // Check if any line items have BTP-specific properties
        if let lineItems = document.lineItems?.allObjects as? [LineItem] {
            for item in lineItems {
                if item.corpsEtat != nil { return true }
                if item.uniteBTP != nil { return true }
                if item.lotNumber != nil && !(item.lotNumber?.isEmpty ?? true) { return true }
            }
        }
        
        // Check template style preference for BTP templates
        let templateStyle = UserDefaults.standard.string(forKey: "templateStyle") ?? ""
        if templateStyle.contains("BTP") || templateStyle.contains("Construction") || templateStyle.contains("FR") { return true }
        
        return false
    }
    
    // MARK: - NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        // Here you could add logic to check for unsaved changes before closing.
        // For now, we just allow the window to close.
        self.window = nil
    }
}

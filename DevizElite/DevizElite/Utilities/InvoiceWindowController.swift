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

        rootView = AnyView(
            InvoiceEditorView(document: documentToEdit, isPresented: isPresented)
                .environment(\.managedObjectContext, context)
                .environmentObject(i18n)
        )
        
        window.contentView = NSHostingView(rootView: rootView)
        window.delegate = self
    }
    
    private func generateInvoiceNumber(context: NSManagedObjectContext) -> String {
        let year = Calendar.current.component(.year, from: Date())
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND number BEGINSWITH[c] %@", "invoice", "INV-\(year)")
        
        do {
            let count = try context.count(for: request)
            return "INV-\(year)-\(String(format: "%04d", count + 1))"
        } catch {
            // Fallback for safety
            return "INV-\(year)-\(Int.random(in: 1000...9999))"
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
    
    // MARK: - NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        // Here you could add logic to check for unsaved changes before closing.
        // For now, we just allow the window to close.
        self.window = nil
    }
}

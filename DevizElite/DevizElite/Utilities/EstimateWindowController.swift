//
//  EstimateWindowController.swift
//  DevizElite
//
//  Created by Claude Code on 17/09/2025.
//

import AppKit
import SwiftUI
import CoreData

class EstimateWindowController: NSWindowController, NSWindowDelegate {
    
    convenience init(document: Document?, context: NSManagedObjectContext, i18n: LocalizationService) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = document == nil ? L10n.t("Nouveau Devis") : L10n.t("Modifier Devis")
        window.minSize = NSSize(width: 1200, height: 800)
        
        self.init(window: window)
        
        let documentToEdit: Document
        
        if let existingDocument = document {
            documentToEdit = existingDocument
        } else {
            // Create a new document for a new estimate
            let newDocument = Document(context: context)
            newDocument.id = UUID()
            newDocument.type = "estimate" // IMPORTANT: Force type to estimate
            newDocument.status = "draft"
            newDocument.issueDate = Date()
            newDocument.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) // Validity: 30 days
            newDocument.number = generateEstimateNumber(context: context)
            newDocument.currencyCode = "EUR"
            documentToEdit = newDocument
        }

        // Use BTPDocumentEditorView for estimates (supports all BTP features)
        let rootView = AnyView(
            BTPDocumentEditorView(document: documentToEdit)
                .environment(\.managedObjectContext, context)
                .environmentObject(i18n)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CloseWindow"))) { _ in
                    window.close()
                }
        )
        
        window.contentView = NSHostingView(rootView: rootView)
        window.delegate = self
    }
    
    private func generateEstimateNumber(context: NSManagedObjectContext) -> String {
        let year = Calendar.current.component(.year, from: Date())
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND number BEGINSWITH[c] %@", "estimate", "DV-\(year)")
        
        do {
            let count = try context.count(for: request)
            return "DV-\(year)-\(String(format: "%03d", count + 1))"
        } catch {
            // Fallback for safety
            return "DV-\(year)-\(String(format: "%03d", Int.random(in: 1...999)))"
        }
    }
    
    // MARK: - NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        self.window = nil
    }
}
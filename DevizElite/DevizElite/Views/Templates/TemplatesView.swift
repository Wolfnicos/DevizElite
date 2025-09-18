import SwiftUI
import CoreData
import AppKit

struct TemplatesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var manager = TemplateManager.shared
    @State private var logoImage: NSImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t("Templates")).font(.title)
            HStack(alignment: .top, spacing: 16) {
                // Preview grid
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(manager.templates) { t in
                            VStack(spacing: 8) {
                                TemplatePreviewCard(template: t, isSelected: manager.selectedTemplateId == t.id)
                                    .onTapGesture { manager.selectedTemplateId = t.id; manager.applySelectedTemplateFor(documentType: "invoice") }
                                Text(t.name).font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                Spacer()
                // Logo controls
                VStack(alignment: .leading, spacing: 8) {
                    if let img = logoImage { Image(nsImage: img).resizable().frame(width: 120, height: 120).cornerRadius(8) }
                    HStack {
                        Button(L10n.t("Upload Logo")) { pickLogo() }
                        Button(L10n.t("Remove Logo")) { logoImage = nil; saveLogo(nil) }
                    }
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.t("Preview")).font(.headline)
                TemplateLivePreviewNew()
                    .frame(width: 400, height: 566)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
            }
            Button(L10n.t("Save")) { manager.applySelectedTemplateFor(documentType: "invoice"); save() }
        }
        .padding(20)
        .onAppear { load() }
    }

    private func pickLogo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
            logoImage = img
            saveLogo(img)
        }
    }

    private func saveLogo(_ image: NSImage?) {
        guard let image = image else {
            // Clear on active user
            if let user = try? viewContext.fetch(NSFetchRequest<User>(entityName: "User")).first {
                user.logoData = nil
                try? viewContext.save()
            }
            return
        }
        if let tiff = image.tiffRepresentation { 
            if let user = try? viewContext.fetch(NSFetchRequest<User>(entityName: "User")).first {
                user.logoData = tiff
                try? viewContext.save()
            }
        }
    }

    private func load() {
        if let user = try? viewContext.fetch(NSFetchRequest<User>(entityName: "User")).first, let data = user.logoData, let img = NSImage(data: data) {
            logoImage = img
        }
    }

    private func save() {
        UserDefaults.standard.set(manager.selectedTemplateId, forKey: "templateStyle")
    }
}

enum TemplateStyle: String, CaseIterable { case Classic, Modern, Minimal, FRModernInvoice, BEProfessionalInvoice, FRModernQuote, BEProfessionalQuote, BTP2025Invoice, BTP2025Quote, ModernBTPInvoice, ModernBTPQuote, BEModernBTPInvoice, BEModernBTPQuote }

private struct TemplatePreviewCard: View {
    let template: InvoiceTemplateModel
    let isSelected: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(radius: isSelected ? 8 : 4)
            VStack(spacing: 4) {
                Rectangle().fill(template.colorScheme.primary.opacity(0.2)).frame(height: 30)
                VStack(spacing: 2) { ForEach(0..<5, id: \.self) { _ in Rectangle().fill(Color.gray.opacity(0.1)).frame(height: 8) } }.padding(8)
                Rectangle().fill(template.colorScheme.secondary.opacity(0.1)).frame(height: 20)
            }
        }
        .frame(width: 150, height: 200)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2))
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

private struct TemplateLivePreview: View {
    @Environment(\.managedObjectContext) private var viewContext
    var body: some View {
        let doc = sampleDocument()
        let styleRaw = UserDefaults.standard.string(forKey: "templateStyle") ?? TemplateStyle.Classic.rawValue
        let style = TemplateStyle(rawValue: styleRaw) ?? .Classic
        PDFService.shared.sharedView(for: style, document: doc)
    }

    private func sampleDocument() -> Document {
        let request = NSFetchRequest<Document>(entityName: "Document")
        request.fetchLimit = 1
        if let existing = try? viewContext.fetch(request).first { 
            // Update existing with BTP data for preview
            updateDocumentWithBTPData(existing)
            return existing 
        }
        
        let d = Document(context: viewContext)
        d.id = UUID()
        d.type = "invoice"
        d.number = "PREV-2024-001"
        d.issueDate = Date()
        d.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        d.currencyCode = "EUR"
        d.status = "draft"
        
        // Add BTP-specific data
        updateDocumentWithBTPData(d)
        
        // Add a sample client with BTP data
        let c = Client(context: viewContext)
        c.id = UUID()
        c.name = "Entreprise Martin SARL"
        c.address = "15 Avenue des Champs\n75008 Paris\nFrance"
        c.contactEmail = "contact@martin-btp.fr"
        c.phone = "+33 1 42 86 33 22"
        c.taxId = "FR85123456789"
        d.client = c
        
        // Sample BTP line items with corps d'état
        let btpItems = [
            ("Terrassement fondations", 45.0, "m³", 35.0, 10.0, 0.0, "terrassement"),
            ("Maçonnerie murs porteurs", 120.0, "m²", 85.0, 20.0, 5.0, "maconnerie"),
            ("Charpente traditionnelle", 1.0, "forfait", 4500.0, 20.0, 0.0, "charpente"),
            ("Couverture tuiles", 95.0, "m²", 45.0, 20.0, 0.0, "couverture"),
            ("Plomberie sanitaire", 8.0, "poste", 350.0, 20.0, 10.0, "plomberie"),
            ("Électricité complète", 12.0, "circuit", 280.0, 20.0, 0.0, "electricite")
        ]
        
        for (idx, row) in btpItems.enumerated() {
            let li = LineItem(context: viewContext)
            li.id = UUID()
            li.itemDescription = row.0
            li.quantity = NSDecimalNumber(value: row.1)
            li.setValue(row.2, forKey: "unit")
            li.unitPrice = NSDecimalNumber(value: row.3)
            li.taxRate = row.4
            li.discount = row.5
            li.position = Int16(idx)
            li.document = d
            
            // Add BTP corps d'état
            if let corpsEtat = CorpsEtat(rawValue: row.6.capitalized) {
                li.setValue(corpsEtat.rawValue, forKey: "btpCorpsEtat")
            }
            if let uniteBTP = UniteBTP(rawValue: row.2) {
                li.setValue(uniteBTP.rawValue, forKey: "btpUnite")
            }
        }
        
        try? viewContext.save()
        return d
    }
    
    private func updateDocumentWithBTPData(_ document: Document) {
        // Use safe BTP extensions instead of setValue
        document.siteAddress = "123 Rue du Chantier, 75012 Paris"
        document.setValue("Construction maison individuelle", forKey: "projectName")
    }
}




import SwiftUI
import AppKit
import PDFKit

// MARK: - BTP Template Preview for AppKit-based templates
struct BTPTemplatePreview: NSViewRepresentable {
    let document: Document
    let style: TemplateStyle
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.white.cgColor
        
        // Generate PDF data and convert to image for preview
        if let pdfData = generatePDFData() {
            if let imageView = createImageFromPDF(pdfData) {
                containerView.addSubview(imageView)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                    imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                ])
            }
        }
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Clear existing content
        nsView.subviews.forEach { $0.removeFromSuperview() }
        
        // Generate fresh preview
        if let pdfData = generatePDFData() {
            if let imageView = createImageFromPDF(pdfData) {
                nsView.addSubview(imageView)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: nsView.topAnchor),
                    imageView.leadingAnchor.constraint(equalTo: nsView.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: nsView.trailingAnchor),
                    imageView.bottomAnchor.constraint(equalTo: nsView.bottomAnchor)
                ])
            }
        }
    }
    
    private func generatePDFData() -> Data? {
        let generator = ProfessionalPDFGenerator()
        let isQuote = document.type?.lowercased() == "estimate"
        return generator.generate(document: document, isQuote: isQuote)
    }
    
    private func createImageFromPDF(_ pdfData: Data) -> NSImageView? {
        guard let pdfDoc = PDFDocument(data: pdfData),
              let page = pdfDoc.page(at: 0) else { return nil }
        
        // Create thumbnail with appropriate size for preview
        let previewSize = CGSize(width: 400, height: 566) // A4 ratio scaled down
        let thumbnail = page.thumbnail(of: previewSize, for: .mediaBox)
        
        let imageView = NSImageView()
        imageView.image = thumbnail
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        
        return imageView
    }
}

// MARK: - Updated Template Live Preview
struct TemplateLivePreviewNew: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var manager = TemplateManager.shared
    
    var body: some View {
        let doc = sampleDocument()
        let styleRaw = UserDefaults.standard.string(forKey: "templateStyle") ?? TemplateStyle.Classic.rawValue
        let style = TemplateStyle(rawValue: styleRaw) ?? .Classic
        
        Group {
            switch style {
            case .ModernBTPInvoice, .ModernBTPQuote, .BEModernBTPInvoice, .BEModernBTPQuote:
                // Use AppKit preview for new BTP templates
                BTPTemplatePreview(document: doc, style: style)
                    .frame(width: 400, height: 566)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
            default:
                // Use SwiftUI preview for legacy templates
                PDFService.shared.sharedView(for: style, document: doc)
                    .frame(width: 400, height: 566)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
            }
        }
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
            ("Terrassement fondations", 45.0, "m³", 35.0, 10.0, 0.0, "Terrassement"),
            ("Maçonnerie murs porteurs", 120.0, "m²", 85.0, 20.0, 5.0, "Maçonnerie"),
            ("Charpente traditionnelle", 1.0, "forfait", 4500.0, 20.0, 0.0, "Charpente"),
            ("Couverture tuiles", 95.0, "m²", 45.0, 20.0, 0.0, "Couverture"),
            ("Plomberie sanitaire", 8.0, "poste", 350.0, 20.0, 10.0, "Plomberie"),
            ("Électricité complète", 12.0, "circuit", 280.0, 20.0, 0.0, "Électricité")
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
            
            // Don't set BTP data here - will be handled by extensions
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
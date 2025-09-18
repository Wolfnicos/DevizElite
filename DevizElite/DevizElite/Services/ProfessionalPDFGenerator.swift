import Foundation
import AppKit
import PDFKit
import CoreGraphics

// MARK: - Professional PDF Generator - macOS Compatible
// Unified template system supporting construction-specific templates for France/Belgium

final class ProfessionalPDFGenerator {
    
    // Entry point: determine template type and generate PDF
    func generate(document: Document, isQuote: Bool) -> Data? {
        // Get current template style from user defaults
        let styleRaw = UserDefaults.standard.string(forKey: "templateStyle") ?? TemplateStyle.Classic.rawValue
        let style = TemplateStyle(rawValue: styleRaw) ?? .Classic
        
        // Determine which template to use based on style and document type
        switch (style, isQuote) {
        // New Modern BTP templates (PRIMARY)
        case (.ModernBTPInvoice, false):
            return ModernBTPInvoiceTemplate().generate(document: document)
        case (.ModernBTPQuote, true):
            return ModernBTPQuoteTemplate().generate(document: document)
        case (.BEModernBTPInvoice, false):
            return BEModernBTPInvoiceTemplate().generate(document: document)
        case (.BEModernBTPQuote, true):
            return BEModernBTPQuoteTemplate().generate(document: document)
            
        // Legacy templates
        case (.FRModernInvoice, false), (.BTP2025Invoice, false):
            return FRConstructionInvoiceTemplate().generate(document: document)
        case (.FRModernQuote, true), (.BTP2025Quote, true):
            return FRConstructionQuoteTemplate().generate(document: document)
        case (.BEProfessionalInvoice, false):
            return BEConstructionInvoiceTemplate().generate(document: document)
        case (.BEProfessionalQuote, true):
            return BEConstructionQuoteTemplate().generate(document: document)
            
        default:
            // Fallback to original BTP 2025 template for other styles
            return generateBTP2025PDF(document: document, isQuote: isQuote)
        }
    }
    
    // Original BTP 2025 template (kept as fallback)
    private func generateBTP2025PDF(document: Document, isQuote: Bool) -> Data? {
        let pageSize = CGSize(width: 595, height: 842) // A4 @ 72dpi
        let margin: CGFloat = 40
        let primaryBlue = NSColor(calibratedRed: 0.114, green: 0.471, blue: 0.843, alpha: 1.0)
        let orangeColor = NSColor(calibratedRed: 1.0, green: 0.647, blue: 0.0, alpha: 1.0)
        let lightGray = NSColor(calibratedWhite: 0.96, alpha: 1.0)
        let lightBlue = NSColor(calibratedRed: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        let greenColor = NSColor(calibratedRed: 0.133, green: 0.545, blue: 0.133, alpha: 1.0)

        let company = ProCompany(
            name: (UserDefaults.standard.string(forKey: "companyName") ?? "MettaConcept").trimmingCharacters(in: .whitespacesAndNewlines),
            address: (UserDefaults.standard.string(forKey: "companyAddress") ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            phone: nil,
            email: nil,
            vatNumber: UserDefaults.standard.string(forKey: "companyTaxId"),
            siret: nil
        )

        let inv = ProInvoice(
            number: document.number ?? "-",
            date: document.issueDate ?? Date(),
            type: isQuote ? .quote : .invoice,
            projectAddress: (document.value(forKey: "siteAddress") as? String) ?? "",
            projectType: (document.value(forKey: "projectName") as? String) ?? "",
            vatRate: 0
        )

        var cli: ProClient? = nil
        if let c = document.safeClient {
            cli = ProClient(
                name: c.name ?? "",
                address: c.address,
                email: c.contactEmail,
                phone: c.phone,
                vatNumber: c.taxId
            )
        }

        let itemsSet: Set<LineItem> = (document.lineItems as? Set<LineItem>) ?? []
        let items = itemsSet.sorted { $0.position < $1.position }.map { li in
            ProInvoiceItem(
                description: li.itemDescription ?? "",
                unit: (li.value(forKey: "unit") as? String) ?? "",
                quantity: ((li.quantity as NSDecimalNumber?) ?? 0).doubleValue,
                unitPrice: (li.unitPrice ?? 0).doubleValue,
                discount: Double(li.discount),
                taxRate: Double(li.taxRate)
            )
        }

        let view = ProPDFPageView(
            frame: CGRect(origin: .zero, size: pageSize),
            margin: margin,
            primaryBlue: primaryBlue,
            orangeColor: orangeColor,
            lightGray: lightGray,
            lightBlue: lightBlue,
            greenColor: greenColor,
            invoice: inv,
            client: cli,
            company: company,
            items: items
        )
        return view.dataWithPDF(inside: view.bounds)
    }

}

// MARK: - NSView that draws the BTP 2025 page
private final class ProPDFPageView: NSView {
    private let margin: CGFloat
    private let primaryBlue: NSColor
    private let orangeColor: NSColor
    private let lightGray: NSColor
    private let lightBlue: NSColor
    private let greenColor: NSColor
    private let invoice: ProInvoice
    private let client: ProClient?
    private let company: ProCompany
    private let items: [ProInvoiceItem]

    init(frame: CGRect,
         margin: CGFloat,
         primaryBlue: NSColor,
         orangeColor: NSColor,
         lightGray: NSColor,
         lightBlue: NSColor,
         greenColor: NSColor,
         invoice: ProInvoice,
         client: ProClient?,
         company: ProCompany,
         items: [ProInvoiceItem]) {
        self.margin = margin
        self.primaryBlue = primaryBlue
        self.orangeColor = orangeColor
        self.lightGray = lightGray
        self.lightBlue = lightBlue
        self.greenColor = greenColor
        self.invoice = invoice
        self.client = client
        self.company = company
        self.items = items
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        var currentY: CGFloat = margin
        currentY = drawHeader(ctx: ctx, startY: currentY)
        drawBlueLine(ctx: ctx, y: currentY)
        currentY += 10
        currentY = drawEmetteurClientBoxes(ctx: ctx, startY: currentY)
        currentY = drawDescriptionProjet(ctx: ctx, startY: currentY + 20)
        currentY = drawDescriptionTravaux(ctx: ctx, startY: currentY + 20)
        currentY = drawTotalsBox(ctx: ctx, startY: currentY + 10)
        if invoice.type != .quote {
            currentY = drawConditionsRealisation(ctx: ctx, startY: currentY + 30)
            currentY = drawGaranties(ctx: ctx, startY: currentY + 30)
        }
        _ = drawSignatureAreas(ctx: ctx, startY: currentY + 30)
        drawFooter(ctx: ctx)
    }

    // MARK: Sections
    private func drawHeader(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let logoRect = CGRect(x: margin, y: y, width: 100, height: 60)
        // Rounded blue box
        let path = NSBezierPath(roundedRect: logoRect, xRadius: 8, yRadius: 8)
        primaryBlue.setFill(); path.fill()
        // "Metta"
        let mettaAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 18),
            .foregroundColor: NSColor.white
        ]
        ("Metta" as NSString).draw(at: CGPoint(x: logoRect.midX - 25, y: logoRect.midY - 20), withAttributes: mettaAttrs)
        // "Concept"
        let conceptAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.white
        ]
        ("Concept" as NSString).draw(at: CGPoint(x: logoRect.midX - 28, y: logoRect.midY), withAttributes: conceptAttrs)

        // Title DEVIS/FACTURE
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 32),
            .foregroundColor: orangeColor
        ]
        let docType = invoice.type == .quote ? "DEVIS" : "FACTURE"
        let titleText = docType as NSString
        let titleSize = titleText.size(withAttributes: titleAttrs)
        titleText.draw(at: CGPoint(x: bounds.width - margin - titleSize.width, y: y), withAttributes: titleAttrs)

        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.darkGray
        ]
        ("N° \(invoice.number)" as NSString).draw(at: CGPoint(x: bounds.width - margin - 120, y: y + 38), withAttributes: infoAttrs)

        let df = DateFormatter(); df.locale = Locale(identifier: "fr_FR"); df.dateFormat = "d MMMM yyyy"
        ("Date : \(df.string(from: invoice.date))" as NSString).draw(at: CGPoint(x: bounds.width - margin - 120, y: y + 55), withAttributes: infoAttrs)
        ("Validité : 30 jours" as NSString).draw(at: CGPoint(x: bounds.width - margin - 120, y: y + 72), withAttributes: infoAttrs)
        return y + 95
    }

    private func drawBlueLine(ctx: CGContext, y: CGFloat) {
        ctx.setStrokeColor(primaryBlue.cgColor)
        ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: margin, y: y))
        ctx.addLine(to: CGPoint(x: bounds.width - margin, y: y))
        ctx.strokePath()
    }

    private func drawEmetteurClientBoxes(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth = (bounds.width - margin * 2 - 20) / 2
        let boxHeight: CGFloat = 90

        let leftRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        lightBlue.setFill(); ctx.fill(leftRect)

        let rightRect = CGRect(x: margin + boxWidth + 20, y: y, width: boxWidth, height: boxHeight)
        NSColor.white.setFill(); ctx.fill(rightRect)
        NSColor.lightGray.setStroke(); ctx.setLineWidth(1); ctx.stroke(rightRect)

        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.darkGray
        ]
        ("Émetteur" as NSString).draw(at: CGPoint(x: margin + 10, y: y + 10), withAttributes: headerAttrs)
        ("Client" as NSString).draw(at: CGPoint(x: margin + boxWidth + 30, y: y + 10), withAttributes: headerAttrs)

        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.black
        ]
        let emetteurInfo = "\(company.name)\n\(company.address)" as NSString
        emetteurInfo.draw(in: CGRect(x: margin + 10, y: y + 30, width: boxWidth - 20, height: 50), withAttributes: contentAttrs)

        if let c = client, !c.name.isEmpty {
            let clientInfo = "\(c.name)\n\(c.address ?? "")" as NSString
            clientInfo.draw(in: CGRect(x: margin + boxWidth + 30, y: y + 30, width: boxWidth - 20, height: 50), withAttributes: contentAttrs)
        } else {
            let placeholder: [NSAttributedString.Key: Any] = [ .font: NSFontManager.shared.font(withFamily: NSFont.systemFont(ofSize: 11).familyName ?? "Helvetica", traits: .italicFontMask, weight: 5, size: 11) ?? NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.gray ]
            ("À renseigner" as NSString).draw(at: CGPoint(x: margin + boxWidth + 30, y: y + 30), withAttributes: placeholder)
        }
        return y + boxHeight
    }

    private func drawDescriptionProjet(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let titleAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.boldSystemFont(ofSize: 14), .foregroundColor: primaryBlue ]
        ("Description du projet   📋" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 25
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 70)
        lightGray.setFill(); ctx.fill(boxRect)

        let labelAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.gray ]
        let valueAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.black ]
        ("Adresse chantier :" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 10), withAttributes: labelAttrs)
        ((invoice.projectAddress.isEmpty ? "-" : invoice.projectAddress) as NSString).draw(at: CGPoint(x: margin + 200, y: y + 10), withAttributes: valueAttrs)
        ("Nature des travaux :" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 30), withAttributes: labelAttrs)
        ((invoice.projectType.isEmpty ? "-" : invoice.projectType) as NSString).draw(at: CGPoint(x: margin + 200, y: y + 30), withAttributes: valueAttrs)
        ("Période d'exécution :" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 50), withAttributes: labelAttrs)
        ("-" as NSString).draw(at: CGPoint(x: margin + 200, y: y + 50), withAttributes: valueAttrs)
        return y + 75
    }

    private func drawDescriptionTravaux(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let tableWidth = bounds.width - margin * 2
        let headerHeight: CGFloat = 40
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: headerHeight)
        primaryBlue.setFill(); ctx.fill(headerRect)

        let headerAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.boldSystemFont(ofSize: 11), .foregroundColor: NSColor.white ]
        ("Description des travaux" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 12), withAttributes: headerAttrs)
        ("Unité" as NSString).draw(at: CGPoint(x: bounds.width - 280, y: y + 12), withAttributes: headerAttrs)
        ("Quantité" as NSString).draw(at: CGPoint(x: bounds.width - 200, y: y + 12), withAttributes: headerAttrs)
        ("P.U. HT (€)" as NSString).draw(at: CGPoint(x: bounds.width - 120, y: y + 12), withAttributes: headerAttrs)
        ("Total HT (€)" as NSString).draw(at: CGPoint(x: bounds.width - margin - 80, y: y + 12), withAttributes: headerAttrs)
        y += headerHeight

        let rowHeight: CGFloat = 45
        // Reserve space at bottom for totals box + signatures + footer
        let bottomReserve: CGFloat = 170
        let maxBodyHeight = max(0, bounds.height - bottomReserve - y)
        let desiredBodyHeight: CGFloat = items.isEmpty ? 150 : CGFloat(items.count) * rowHeight
        let bodyHeight: CGFloat = min(desiredBodyHeight, maxBodyHeight)
        NSColor.white.setFill(); ctx.fill(CGRect(x: margin, y: y, width: tableWidth, height: bodyHeight))

        if !items.isEmpty {
            let itemAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray ]
            let rowsThatFit = Int(floor(bodyHeight / rowHeight))
            for (idx, it) in items.prefix(rowsThatFit).enumerated() {
                let rowY = y + CGFloat(idx) * rowHeight
                if idx % 2 == 1 { lightGray.setFill(); ctx.fill(CGRect(x: margin, y: rowY, width: tableWidth, height: rowHeight)) }
                let lotAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.boldSystemFont(ofSize: 9), .foregroundColor: primaryBlue ]
                ("LOT \(String(format: "%02d", idx))" as NSString).draw(at: CGPoint(x: margin + 15, y: rowY + 5), withAttributes: lotAttrs)
                (it.description as NSString).draw(at: CGPoint(x: margin + 15, y: rowY + 22), withAttributes: itemAttrs)
                (it.unit as NSString).draw(at: CGPoint(x: bounds.width - 280, y: rowY + 15), withAttributes: itemAttrs)
                ("\(Int(it.quantity))" as NSString).draw(at: CGPoint(x: bounds.width - 180, y: rowY + 15), withAttributes: itemAttrs)
                (String(format: "%.2f €", it.unitPrice) as NSString).draw(at: CGPoint(x: bounds.width - 120, y: rowY + 15), withAttributes: itemAttrs)
                (String(format: "%.2f €", it.net) as NSString).draw(at: CGPoint(x: bounds.width - margin - 80, y: rowY + 15), withAttributes: itemAttrs)
            }
        }
        return y + bodyHeight
    }

    private func drawTotalsBox(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let boxWidth: CGFloat = 250
        let x = bounds.width - margin - boxWidth
        var y = startY
        let subtotal = items.reduce(0.0) { $0 + $1.net }
        let vat = items.reduce(0.0) { $0 + ($1.net * ($1.taxRate/100.0)) }
        let total = subtotal + vat

        let yellowBoxHeight: CGFloat = vat > 0 ? 90 : 60
        // Keep totals above reserved bottom area
        let bottomReserve: CGFloat = 130
        y = min(y, bounds.height - bottomReserve - yellowBoxHeight - 40)
        let yellowBox = CGRect(x: x, y: y, width: boxWidth, height: yellowBoxHeight)
        NSColor(calibratedRed: 1, green: 0.98, blue: 0.9, alpha: 1).setFill(); ctx.fill(yellowBox)
        NSColor(calibratedRed: 1, green: 0.9, blue: 0.7, alpha: 1).setStroke(); ctx.setLineWidth(1); ctx.stroke(yellowBox)

        let normal: [NSAttributedString.Key: Any] = [ .font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.darkGray ]
        let bold: [NSAttributedString.Key: Any] = [ .font: NSFont.boldSystemFont(ofSize: 12), .foregroundColor: NSColor.black ]
        var lineY = y + 15
        ("TOTAL HT :" as NSString).draw(at: CGPoint(x: x + 15, y: lineY), withAttributes: bold)
        (String(format: "%.2f €", subtotal) as NSString).draw(at: CGPoint(x: x + boxWidth - 80, y: lineY), withAttributes: bold)
        lineY += 25
        if vat > 0 {
            ("TVA :" as NSString).draw(at: CGPoint(x: x + 15, y: lineY), withAttributes: normal)
            (String(format: "%.2f €", vat) as NSString).draw(at: CGPoint(x: x + boxWidth - 80, y: lineY), withAttributes: normal)
            lineY += 30
        }
        let ttcRect = CGRect(x: x, y: lineY, width: boxWidth, height: 35)
        primaryBlue.setFill(); ctx.fill(ttcRect)
        let ttcAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.boldSystemFont(ofSize: 14), .foregroundColor: NSColor.white ]
        ("TOTAL TTC :" as NSString).draw(at: CGPoint(x: x + 15, y: lineY + 8), withAttributes: ttcAttrs)
        (String(format: "%.2f €", total) as NSString).draw(at: CGPoint(x: x + boxWidth - 90, y: lineY + 8), withAttributes: ttcAttrs)
        return y + yellowBoxHeight + 40
    }

    private func drawConditionsRealisation(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let titleAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.boldSystemFont(ofSize: 14), .foregroundColor: greenColor ]
        ("Conditions de réalisation" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 25
        let termAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.darkGray ]
        let columnWidth = (bounds.width - margin * 2) / 2
        ("1 Acompte signature : 30%" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: termAttrs)
        ("2 Début travaux : 35%" as NSString).draw(at: CGPoint(x: margin + columnWidth, y: y), withAttributes: termAttrs)
        ("3 Mi-parcours : 25%" as NSString).draw(at: CGPoint(x: margin, y: y + 20), withAttributes: termAttrs)
        ("4 Réception : 10%" as NSString).draw(at: CGPoint(x: margin + columnWidth, y: y + 20), withAttributes: termAttrs)
        return y + 45
    }

    private func drawGaranties(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let titleAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.boldSystemFont(ofSize: 14), .foregroundColor: greenColor ]
        ("Nos garanties et engagements" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 25
        let wAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray ]
        let columnWidth = (bounds.width - margin * 2) / 2
        ("✓ Garantie décennale tous corps d'état" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: wAttrs)
        ("✓ Assurance dommages-ouvrage proposée" as NSString).draw(at: CGPoint(x: margin + columnWidth, y: y), withAttributes: wAttrs)
        ("✓ Respect des délais contractuels" as NSString).draw(at: CGPoint(x: margin, y: y + 20), withAttributes: wAttrs)
        ("✓ Certification RGE (aides fiscales possibles)" as NSString).draw(at: CGPoint(x: margin + columnWidth, y: y + 20), withAttributes: wAttrs)
        ("✓ Conducteur de travaux dédié" as NSString).draw(at: CGPoint(x: margin, y: y + 40), withAttributes: wAttrs)
        ("✓ Nettoyage quotidien du chantier" as NSString).draw(at: CGPoint(x: margin + columnWidth, y: y + 40), withAttributes: wAttrs)
        return y + 65
    }

    private func drawSignatureAreas(ctx: CGContext, startY: CGFloat) -> CGFloat {
        // Keep signatures safely above footer. If content is short, anchor to a fixed top
        // relative to the bottom area to avoid overlapping footer pills/text.
        let minTopFromBottom: CGFloat = bounds.height - 160
        var y = max(startY, minTopFromBottom)
        let boxWidth = (bounds.width - margin * 2 - 40) / 2
        let boxHeight: CGFloat = 80
        let headerAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.boldSystemFont(ofSize: 12), .foregroundColor: NSColor.darkGray ]
        ("Le Client" as NSString).draw(at: CGPoint(x: margin + boxWidth/2 - 25, y: y), withAttributes: headerAttrs)
        ("L'Entreprise" as NSString).draw(at: CGPoint(x: bounds.width - margin - boxWidth/2 - 35, y: y), withAttributes: headerAttrs)
        y += 20
        NSColor.darkGray.setStroke(); ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: margin, y: y + 40)); ctx.addLine(to: CGPoint(x: margin + boxWidth, y: y + 40)); ctx.strokePath()
        ctx.move(to: CGPoint(x: bounds.width - margin - boxWidth, y: y + 40)); ctx.addLine(to: CGPoint(x: bounds.width - margin, y: y + 40)); ctx.strokePath()
        let noteAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.gray ]
        ("Précédé de 'Bon pour accord'" as NSString).draw(at: CGPoint(x: margin, y: y + 50), withAttributes: noteAttrs)
        ("Date et signature" as NSString).draw(at: CGPoint(x: margin, y: y + 65), withAttributes: noteAttrs)
        ("Cachet entreprise" as NSString).draw(at: CGPoint(x: bounds.width - margin - boxWidth, y: y + 65), withAttributes: noteAttrs)
        return y + boxHeight
    }

    private func drawFooter(ctx: CGContext) {
        let footerY = bounds.height - 60
        if invoice.type == .quote {
            let validity = CGRect(x: margin, y: footerY - 25, width: 200, height: 20)
            NSColor(calibratedRed: 1, green: 0.98, blue: 0.85, alpha: 1).setFill(); ctx.fill(validity)
            let attrs: [NSAttributedString.Key: Any] = [ .font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.darkGray ]
            ("Validité du devis : 30 jours" as NSString).draw(at: CGPoint(x: margin + 10, y: footerY - 22), withAttributes: attrs)
        }
        let footerAttrs: [NSAttributedString.Key: Any] = [ .font: NSFont.systemFont(ofSize: 9), .foregroundColor: NSColor.gray ]
        let text = "\(company.name) — \(company.address)" as NSString
        let para = NSMutableParagraphStyle(); para.alignment = .center
        var attrs = footerAttrs; attrs[.paragraphStyle] = para
        // Slightly lower to keep distance from signature lines
        text.draw(in: CGRect(x: margin, y: footerY + 18, width: bounds.width - margin * 2, height: 20), withAttributes: attrs)
    }
}

// MARK: - Data Models (lightweight, independent of Core Data)
struct ProCompany: Codable { let name: String; let address: String; let phone: String?; let email: String?; let vatNumber: String?; let siret: String? }

struct ProInvoice: Codable {
    let number: String
    let date: Date
    let type: InvoiceType
    let projectAddress: String
    let projectType: String
    let vatRate: Double
    enum InvoiceType: String, Codable { case quote = "DEVIS"; case invoice = "FACTURE" }
}

struct ProClient: Codable { let name: String; let address: String?; let email: String?; let phone: String?; let vatNumber: String? }

struct ProInvoiceItem: Codable {
    let description: String
    let unit: String
    let quantity: Double
    let unitPrice: Double
    let discount: Double
    let taxRate: Double
    var net: Double { quantity * unitPrice * (1.0 - max(0.0, min(100.0, discount))/100.0) }
}



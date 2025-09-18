import Foundation
import AppKit
import PDFKit

// MARK: - French Construction Invoice Template
final class FRConstructionInvoiceTemplate {
    private let pageSize = CGSize(width: 595, height: 842) // A4
    private let margin: CGFloat = 40
    
    // French construction color scheme
    private let primaryBlue = NSColor(calibratedRed: 0.051, green: 0.278, blue: 0.631, alpha: 1.0) // #0D47A1
    private let accentOrange = NSColor(calibratedRed: 1.0, green: 0.341, blue: 0.133, alpha: 1.0) // #FF5722
    private let lightGray = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
    private let darkGray = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    
    func generate(document: Document) -> Data? {
        let view = FRInvoiceView(
            frame: CGRect(origin: .zero, size: pageSize),
            document: document,
            margin: margin,
            primaryBlue: primaryBlue,
            accentOrange: accentOrange,
            lightGray: lightGray,
            darkGray: darkGray
        )
        return view.dataWithPDF(inside: view.bounds)
    }
}

private final class FRInvoiceView: NSView {
    private let document: Document
    private let margin: CGFloat
    private let primaryBlue: NSColor
    private let accentOrange: NSColor
    private let lightGray: NSColor
    private let darkGray: NSColor
    
    init(frame: CGRect, document: Document, margin: CGFloat, primaryBlue: NSColor, accentOrange: NSColor, lightGray: NSColor, darkGray: NSColor) {
        self.document = document
        self.margin = margin
        self.primaryBlue = primaryBlue
        self.accentOrange = accentOrange
        self.lightGray = lightGray
        self.darkGray = darkGray
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
    }
    
    required init?(coder: NSCoder) { fatalError() }
    override var isFlipped: Bool { true }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        
        var currentY: CGFloat = margin
        currentY = drawHeader(ctx: ctx, startY: currentY)
        currentY = drawCompanyAndClient(ctx: ctx, startY: currentY + 20)
        currentY = drawProjectInfo(ctx: ctx, startY: currentY + 20)
        currentY = drawItemsTable(ctx: ctx, startY: currentY + 20)
        currentY = drawTotals(ctx: ctx, startY: currentY + 20)
        currentY = drawPaymentInfo(ctx: ctx, startY: currentY + 20)
        currentY = drawLegalMentions(ctx: ctx, startY: currentY + 20)
        drawFooter(ctx: ctx)
    }
    
    private func drawHeader(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        
        // Company logo/name
        let logoRect = CGRect(x: margin, y: y, width: 120, height: 80)
        let path = NSBezierPath(roundedRect: logoRect, xRadius: 10, yRadius: 10)
        primaryBlue.setFill()
        path.fill()
        
        // Get company info
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? "Entreprise BTP"
        let companyAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 20),
            .foregroundColor: NSColor.white
        ]
        let nameSize = (companyName as NSString).size(withAttributes: companyAttrs)
        (companyName as NSString).draw(
            at: CGPoint(x: logoRect.midX - nameSize.width/2, y: logoRect.midY - nameSize.height/2),
            withAttributes: companyAttrs
        )
        
        // Document title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 36),
            .foregroundColor: primaryBlue
        ]
        let title = "FACTURE" as NSString
        let titleSize = title.size(withAttributes: titleAttrs)
        title.draw(at: CGPoint(x: bounds.width - margin - titleSize.width, y: y), withAttributes: titleAttrs)
        
        // Document info
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: darkGray
        ]
        
        let number = "N° \(document.number ?? "-")" as NSString
        number.draw(at: CGPoint(x: bounds.width - margin - 150, y: y + 45), withAttributes: infoAttrs)
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_FR")
        df.dateFormat = "d MMMM yyyy"
        let dateStr = "Date : \(df.string(from: document.issueDate ?? Date()))" as NSString
        dateStr.draw(at: CGPoint(x: bounds.width - margin - 150, y: y + 65), withAttributes: infoAttrs)
        
        // Draw separator line
        y += 100
        ctx.setStrokeColor(primaryBlue.cgColor)
        ctx.setLineWidth(2)
        ctx.move(to: CGPoint(x: margin, y: y))
        ctx.addLine(to: CGPoint(x: bounds.width - margin, y: y))
        ctx.strokePath()
        
        return y
    }
    
    private func drawCompanyAndClient(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth = (bounds.width - margin * 2 - 30) / 2
        let boxHeight: CGFloat = 120
        
        // Émetteur box
        let emitterRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        lightGray.setFill()
        ctx.fill(emitterRect)
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryBlue
        ]
        ("ÉMETTEUR" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 10), withAttributes: headerAttrs)
        
        // Company details
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        var contentY = y + 35
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? ""
        if !companyName.isEmpty {
            (companyName as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        let companyAddress = UserDefaults.standard.string(forKey: "companyAddress") ?? ""
        if !companyAddress.isEmpty {
            (companyAddress as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        let companyTaxId = UserDefaults.standard.string(forKey: "companyTaxId") ?? ""
        if !companyTaxId.isEmpty {
            ("TVA Intra : \(companyTaxId)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        let siret = UserDefaults.standard.string(forKey: "companySIRET") ?? ""
        if !siret.isEmpty {
            ("SIRET : \(siret)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
        }
        
        // Client box
        let clientRect = CGRect(x: margin + boxWidth + 30, y: y, width: boxWidth, height: boxHeight)
        NSColor.white.setFill()
        ctx.fill(clientRect)
        primaryBlue.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(clientRect)
        
        ("CLIENT" as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: y + 10), withAttributes: headerAttrs)
        
        // Client details
        if let client = document.safeClient {
            contentY = y + 35
            if let name = client.name, !name.isEmpty {
                (name as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
                contentY += 18
            }
            if let address = client.address, !address.isEmpty {
                (address as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
                contentY += 18
            }
            if let city = client.city, !city.isEmpty {
                (city as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
                contentY += 18
            }
            if let taxId = client.taxId, !taxId.isEmpty {
                ("TVA : \(taxId)" as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
            }
        }
        
        return y + boxHeight
    }
    
    private func drawProjectInfo(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Project info box
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 80)
        let gradient = NSGradient(colors: [lightGray, NSColor.white])
        gradient?.draw(in: boxRect, angle: 90)
        
        primaryBlue.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(boxRect)
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryBlue
        ]
        ("INFORMATIONS CHANTIER 🏗️" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 10), withAttributes: titleAttrs)
        
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray.withAlphaComponent(0.8)
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        // Site address
        ("Adresse du chantier :" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 35), withAttributes: labelAttrs)
        let siteAddress = (document.value(forKey: "siteAddress") as? String) ?? "-"
        (siteAddress as NSString).draw(at: CGPoint(x: margin + 180, y: y + 35), withAttributes: valueAttrs)
        
        // Project name
        ("Nature des travaux :" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 55), withAttributes: labelAttrs)
        let projectName = (document.value(forKey: "projectName") as? String) ?? "-"
        (projectName as NSString).draw(at: CGPoint(x: margin + 180, y: y + 55), withAttributes: valueAttrs)
        
        return y + 80
    }
    
    private func drawItemsTable(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let tableWidth = bounds.width - margin * 2
        
        // Table header
        let headerHeight: CGFloat = 40
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: headerHeight)
        primaryBlue.setFill()
        ctx.fill(headerRect)
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        
        // Column headers
        ("Désignation" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 12), withAttributes: headerAttrs)
        ("Unité" as NSString).draw(at: CGPoint(x: margin + 250, y: y + 12), withAttributes: headerAttrs)
        ("Qté" as NSString).draw(at: CGPoint(x: margin + 310, y: y + 12), withAttributes: headerAttrs)
        ("P.U. HT" as NSString).draw(at: CGPoint(x: margin + 360, y: y + 12), withAttributes: headerAttrs)
        ("TVA" as NSString).draw(at: CGPoint(x: margin + 430, y: y + 12), withAttributes: headerAttrs)
        ("Total HT" as NSString).draw(at: CGPoint(x: margin + 480, y: y + 12), withAttributes: headerAttrs)
        
        y += headerHeight
        
        // Items
        let items = (document.lineItems as? Set<LineItem> ?? []).sorted { $0.position < $1.position }
        let rowHeight: CGFloat = 35
        
        for (index, item) in items.enumerated() {
            let rowRect = CGRect(x: margin, y: y, width: tableWidth, height: rowHeight)
            if index % 2 == 0 {
                lightGray.withAlphaComponent(0.3).setFill()
                ctx.fill(rowRect)
            }
            
            let itemAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: darkGray
            ]
            
            // Description
            if let desc = item.itemDescription {
                (desc as NSString).draw(in: CGRect(x: margin + 15, y: y + 10, width: 230, height: 20), withAttributes: itemAttrs)
            }
            
            // Unit
            let unit = (item.value(forKey: "unit") as? String) ?? ""
            (unit as NSString).draw(at: CGPoint(x: margin + 250, y: y + 10), withAttributes: itemAttrs)
            
            // Quantity
            let qty = formatNumber(item.quantity ?? 0)
            (qty as NSString).draw(at: CGPoint(x: margin + 310, y: y + 10), withAttributes: itemAttrs)
            
            // Unit price
            let unitPrice = formatCurrency(item.unitPrice ?? 0, currency: document.currencyCode ?? "EUR")
            (unitPrice as NSString).draw(at: CGPoint(x: margin + 360, y: y + 10), withAttributes: itemAttrs)
            
            // Tax rate
            let taxRate = String(format: "%.0f%%", item.taxRate)
            (taxRate as NSString).draw(at: CGPoint(x: margin + 430, y: y + 10), withAttributes: itemAttrs)
            
            // Line total
            let lineTotal = calculateLineTotal(item)
            let total = formatCurrency(lineTotal, currency: document.currencyCode ?? "EUR")
            (total as NSString).draw(at: CGPoint(x: margin + 480, y: y + 10), withAttributes: itemAttrs)
            
            y += rowHeight
        }
        
        // Table border
        primaryBlue.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: margin, y: startY + headerHeight, width: tableWidth, height: y - startY - headerHeight))
        
        return y
    }
    
    private func drawTotals(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth: CGFloat = 280
        let x = bounds.width - margin - boxWidth
        
        // Calculate totals
        let subtotal = document.subtotal ?? 0
        let taxTotal = document.taxTotal ?? 0
        let total = document.total ?? 0
        let currency = document.currencyCode ?? "EUR"
        
        // Background box
        let bgRect = CGRect(x: x, y: y, width: boxWidth, height: 120)
        lightGray.setFill()
        ctx.fill(bgRect)
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: darkGray
        ]
        let _: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: darkGray
        ]
        
        // Subtotal
        ("Total HT :" as NSString).draw(at: CGPoint(x: x + 20, y: y + 15), withAttributes: normalAttrs)
        (formatCurrency(subtotal, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 100, y: y + 15),
            withAttributes: normalAttrs
        )
        
        // Tax
        ("TVA :" as NSString).draw(at: CGPoint(x: x + 20, y: y + 40), withAttributes: normalAttrs)
        (formatCurrency(taxTotal, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 100, y: y + 40),
            withAttributes: normalAttrs
        )
        
        // Total line
        ctx.setStrokeColor(darkGray.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: x + 20, y: y + 65))
        ctx.addLine(to: CGPoint(x: x + boxWidth - 20, y: y + 65))
        ctx.strokePath()
        
        // Total TTC
        let totalRect = CGRect(x: x, y: y + 75, width: boxWidth, height: 45)
        primaryBlue.setFill()
        ctx.fill(totalRect)
        
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        ("TOTAL TTC :" as NSString).draw(at: CGPoint(x: x + 20, y: y + 85), withAttributes: totalAttrs)
        (formatCurrency(total, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 120, y: y + 85),
            withAttributes: totalAttrs
        )
        
        return y + 120
    }
    
    private func drawPaymentInfo(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Payment conditions box
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 100)
        NSColor(calibratedRed: 0.95, green: 0.98, blue: 0.95, alpha: 1.0).setFill()
        ctx.fill(boxRect)
        
        NSColor(calibratedRed: 0.4, green: 0.8, blue: 0.4, alpha: 1.0).setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(boxRect)
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: NSColor(calibratedRed: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        ]
        ("CONDITIONS DE RÈGLEMENT" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 10), withAttributes: titleAttrs)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        // Payment terms
        var contentY = y + 35
        if let dueDate = document.dueDate {
            let df = DateFormatter()
            df.locale = Locale(identifier: "fr_FR")
            df.dateFormat = "d MMMM yyyy"
            ("📅 Échéance : \(df.string(from: dueDate))" as NSString).draw(
                at: CGPoint(x: margin + 15, y: contentY),
                withAttributes: contentAttrs
            )
            contentY += 20
        }
        
        // IBAN
        let iban = UserDefaults.standard.string(forKey: "companyIBAN") ?? ""
        if !iban.isEmpty {
            ("🏦 IBAN : \(iban)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 20
        }
        
        // Penalties
        ("⚠️ Pénalités de retard : 3 × taux légal • Indemnité forfaitaire : 40 €" as NSString).draw(
            at: CGPoint(x: margin + 15, y: contentY),
            withAttributes: contentAttrs
        )
        
        return y + 100
    }
    
    private func drawLegalMentions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: darkGray
        ]
        ("MENTIONS LÉGALES" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: darkGray.withAlphaComponent(0.8)
        ]
        
        y += 20
        let mentions = [
            "• Travaux réalisés conformément aux règles de l'art et DTU en vigueur",
            "• Garantie de parfait achèvement : 1 an",
            "• Garantie décennale : 10 ans (gros œuvre) - Assurance n° \(UserDefaults.standard.string(forKey: "insuranceNumber") ?? "XXX")",
            "• Escompte pour paiement anticipé : néant",
            "• En cas de retard de paiement : application article L441-10 du Code de Commerce",
            "• Réserve de propriété : les matériaux restent notre propriété jusqu'au paiement intégral",
            "• Tribunal compétent : Tribunal de Commerce de \(UserDefaults.standard.string(forKey: "companyCity") ?? "Paris")"
        ]
        
        for mention in mentions {
            (mention as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: contentAttrs)
            y += 15
        }
        
        return y
    }
    
    private func drawFooter(ctx: CGContext) {
        let footerY = bounds.height - 30
        
        ctx.setFillColor(lightGray.cgColor)
        ctx.fill(CGRect(x: 0, y: footerY - 10, width: bounds.width, height: 40))
        
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: darkGray
        ]
        
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? ""
        let companyAddress = UserDefaults.standard.string(forKey: "companyAddress") ?? ""
        let siret = UserDefaults.standard.string(forKey: "companySIRET") ?? ""
        
        var footerText = "\(companyName) - \(companyAddress)"
        if !siret.isEmpty {
            footerText += " - SIRET: \(siret)"
        }
        
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        var attrs = footerAttrs
        attrs[.paragraphStyle] = para
        
        (footerText as NSString).draw(
            in: CGRect(x: margin, y: footerY, width: bounds.width - margin * 2, height: 20),
            withAttributes: attrs
        )
    }
    
    // Helper functions
    private func formatCurrency(_ value: NSDecimalNumber, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: value) ?? "0,00 €"
    }
    
    private func formatNumber(_ value: NSDecimalNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value) ?? "0"
    }
    
    private func calculateLineTotal(_ item: LineItem) -> NSDecimalNumber {
        let qty = item.quantity ?? 0
        let unitPrice = item.unitPrice ?? 0
        let lineTotal = qty.multiplying(by: unitPrice)
        
        // Apply discount if any
        let discountRate = NSDecimalNumber(value: max(0, min(100, item.discount)))
        let discountAmount = lineTotal.multiplying(by: discountRate).dividing(by: 100)
        let netAmount = lineTotal.subtracting(discountAmount)
        
        return netAmount
    }
}

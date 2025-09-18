import Foundation
import AppKit
import PDFKit

// MARK: - Belgian Construction Invoice Template
final class BEConstructionInvoiceTemplate {
    private let pageSize = CGSize(width: 595, height: 842) // A4
    private let margin: CGFloat = 40
    
    // Belgian construction color scheme
    private let primaryBlack = NSColor(calibratedWhite: 0.1, alpha: 1.0)
    private let accentYellow = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // #FFCC00
    private let accentRed = NSColor(calibratedRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0) // #CC0000
    private let lightGray = NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
    private let mediumGray = NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    
    func generate(document: Document) -> Data? {
        let view = BEInvoiceView(
            frame: CGRect(origin: .zero, size: pageSize),
            document: document,
            margin: margin,
            primaryBlack: primaryBlack,
            accentYellow: accentYellow,
            accentRed: accentRed,
            lightGray: lightGray,
            mediumGray: mediumGray
        )
        return view.dataWithPDF(inside: view.bounds)
    }
}

private final class BEInvoiceView: NSView {
    private let document: Document
    private let margin: CGFloat
    private let primaryBlack: NSColor
    private let accentYellow: NSColor
    private let accentRed: NSColor
    private let lightGray: NSColor
    private let mediumGray: NSColor
    
    init(frame: CGRect, document: Document, margin: CGFloat, primaryBlack: NSColor, accentYellow: NSColor, accentRed: NSColor, lightGray: NSColor, mediumGray: NSColor) {
        self.document = document
        self.margin = margin
        self.primaryBlack = primaryBlack
        self.accentYellow = accentYellow
        self.accentRed = accentRed
        self.lightGray = lightGray
        self.mediumGray = mediumGray
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
        currentY = drawBilingualInfo(ctx: ctx, startY: currentY + 15)
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
        
        // Belgian flag colors accent
        let flagWidth: CGFloat = 4
        let flagHeight: CGFloat = 80
        
        // Black stripe
        primaryBlack.setFill()
        ctx.fill(CGRect(x: margin, y: y, width: flagWidth, height: flagHeight))
        
        // Yellow stripe
        accentYellow.setFill()
        ctx.fill(CGRect(x: margin + flagWidth, y: y, width: flagWidth, height: flagHeight))
        
        // Red stripe
        accentRed.setFill()
        ctx.fill(CGRect(x: margin + flagWidth * 2, y: y, width: flagWidth, height: flagHeight))
        
        // Company logo area
        let logoX = margin + flagWidth * 3 + 10
        let logoRect = CGRect(x: logoX, y: y, width: 140, height: 80)
        lightGray.setFill()
        ctx.fill(logoRect)
        
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? "Entreprise BTP"
        let companyAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 18),
            .foregroundColor: primaryBlack
        ]
        let nameSize = (companyName as NSString).size(withAttributes: companyAttrs)
        (companyName as NSString).draw(
            at: CGPoint(x: logoRect.midX - nameSize.width/2, y: logoRect.midY - nameSize.height/2),
            withAttributes: companyAttrs
        )
        
        // FACTURE / FACTUUR title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 36),
            .foregroundColor: primaryBlack
        ]
        let title = "FACTURE" as NSString
        let titleSize = title.size(withAttributes: titleAttrs)
        title.draw(at: CGPoint(x: bounds.width - margin - titleSize.width, y: y), withAttributes: titleAttrs)
        
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24),
            .foregroundColor: mediumGray
        ]
        let subtitle = "FACTUUR" as NSString
        subtitle.draw(at: CGPoint(x: bounds.width - margin - 100, y: y + 40), withAttributes: subtitleAttrs)
        
        // Invoice info
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: primaryBlack
        ]
        
        let number = "N° / Nr. \(document.number ?? "-")" as NSString
        number.draw(at: CGPoint(x: bounds.width - margin - 150, y: y + 70), withAttributes: infoAttrs)
        
        // Belgian flag line separator
        y += 100
        let lineY = y
        primaryBlack.setFill()
        ctx.fill(CGRect(x: margin, y: lineY, width: (bounds.width - margin * 2) / 3, height: 2))
        accentYellow.setFill()
        ctx.fill(CGRect(x: margin + (bounds.width - margin * 2) / 3, y: lineY, width: (bounds.width - margin * 2) / 3, height: 2))
        accentRed.setFill()
        ctx.fill(CGRect(x: margin + 2 * (bounds.width - margin * 2) / 3, y: lineY, width: (bounds.width - margin * 2) / 3, height: 2))
        
        return y
    }
    
    private func drawBilingualInfo(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: mediumGray
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        
        // Date
        ("Date / Datum :" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttrs)
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_BE")
        df.dateFormat = "d MMMM yyyy"
        let dateStr = df.string(from: document.issueDate ?? Date())
        (dateStr as NSString).draw(at: CGPoint(x: margin + 120, y: y), withAttributes: valueAttrs)
        
        // Due date
        if let dueDate = document.dueDate {
            ("Échéance / Vervaldatum :" as NSString).draw(at: CGPoint(x: margin + 300, y: y), withAttributes: labelAttrs)
            (df.string(from: dueDate) as NSString).draw(at: CGPoint(x: margin + 450, y: y), withAttributes: valueAttrs)
        }
        
        return y + 20
    }
    
    private func drawCompanyAndClient(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth = (bounds.width - margin * 2 - 30) / 2
        let boxHeight: CGFloat = 140
        
        // Émetteur / Verstuurder box
        let emitterRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        lightGray.setFill()
        ctx.fill(emitterRect)
        
        // Black accent bar
        primaryBlack.setFill()
        ctx.fill(CGRect(x: margin, y: y, width: 4, height: boxHeight))
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryBlack
        ]
        ("ÉMETTEUR / VERSTUURDER" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 10), withAttributes: headerAttrs)
        
        // Company details
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        
        var contentY = y + 35
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? ""
        if !companyName.isEmpty {
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 12),
                .foregroundColor: primaryBlack
            ]
            (companyName as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: boldAttrs)
            contentY += 20
        }
        
        let companyAddress = UserDefaults.standard.string(forKey: "companyAddress") ?? ""
        if !companyAddress.isEmpty {
            (companyAddress as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        let companyTaxId = UserDefaults.standard.string(forKey: "companyTaxId") ?? ""
        if !companyTaxId.isEmpty {
            ("TVA/BTW : \(companyTaxId)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        let bce = UserDefaults.standard.string(forKey: "companyBCE") ?? ""
        if !bce.isEmpty {
            ("BCE/KBO : \(bce)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        let bank = UserDefaults.standard.string(forKey: "companyBank") ?? ""
        let iban = UserDefaults.standard.string(forKey: "companyIBAN") ?? ""
        if !iban.isEmpty {
            ("IBAN : \(iban)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            if !bank.isEmpty {
                contentY += 18
                ("Bank/Banque : \(bank)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            }
        }
        
        // Client / Klant box
        let clientRect = CGRect(x: margin + boxWidth + 30, y: y, width: boxWidth, height: boxHeight)
        NSColor.white.setFill()
        ctx.fill(clientRect)
        primaryBlack.setStroke()
        ctx.setLineWidth(2)
        ctx.stroke(clientRect)
        
        // Yellow accent bar
        accentYellow.setFill()
        ctx.fill(CGRect(x: margin + boxWidth + 30 + boxWidth - 4, y: y, width: 4, height: boxHeight))
        
        ("CLIENT / KLANT" as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: y + 10), withAttributes: headerAttrs)
        
        // Client details
        if let client = document.safeClient {
            contentY = y + 35
            if let name = client.name, !name.isEmpty {
                let boldAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 12),
                    .foregroundColor: primaryBlack
                ]
                (name as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: boldAttrs)
                contentY += 20
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
                ("TVA/BTW : \(taxId)" as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
            }
        }
        
        return y + boxHeight
    }
    
    private func drawProjectInfo(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Project info box with Belgian style
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 90)
        NSColor.white.setFill()
        ctx.fill(boxRect)
        
        // Tri-color border
        ctx.setLineWidth(3)
        primaryBlack.setStroke()
        ctx.stroke(CGRect(x: margin, y: y, width: (bounds.width - margin * 2) / 3, height: 1))
        accentYellow.setStroke()
        ctx.stroke(CGRect(x: margin + (bounds.width - margin * 2) / 3, y: y, width: (bounds.width - margin * 2) / 3, height: 1))
        accentRed.setStroke()
        ctx.stroke(CGRect(x: margin + 2 * (bounds.width - margin * 2) / 3, y: y, width: (bounds.width - margin * 2) / 3, height: 1))
        
        lightGray.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: margin, y: y + 1, width: bounds.width - margin * 2, height: 89))
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryBlack
        ]
        ("INFORMATIONS CHANTIER / WERFGEGEVENS 🏗️" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 10), withAttributes: titleAttrs)
        
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: mediumGray
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        
        // Site address
        ("Adresse chantier / Werfadres :" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 35), withAttributes: labelAttrs)
        let siteAddress = (document.value(forKey: "siteAddress") as? String) ?? "-"
        (siteAddress as NSString).draw(at: CGPoint(x: margin + 220, y: y + 35), withAttributes: valueAttrs)
        
        // Project name
        ("Nature des travaux / Aard werken :" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 55), withAttributes: labelAttrs)
        let projectName = (document.value(forKey: "projectName") as? String) ?? "-"
        (projectName as NSString).draw(at: CGPoint(x: margin + 220, y: y + 55), withAttributes: valueAttrs)
        
        // Reference
        let reference = (document.value(forKey: "reference") as? String) ?? ""
        if !reference.isEmpty {
            ("Référence / Referentie :" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 75), withAttributes: labelAttrs)
            (reference as NSString).draw(at: CGPoint(x: margin + 220, y: y + 75), withAttributes: valueAttrs)
        }
        
        return y + 90
    }
    
    private func drawItemsTable(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let tableWidth = bounds.width - margin * 2
        
        // Table header with gradient
        let headerHeight: CGFloat = 45
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: headerHeight)
        let gradient = NSGradient(colors: [primaryBlack, primaryBlack.blended(withFraction: 0.2, of: .white)!])
        gradient?.draw(in: headerRect, angle: 90)
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.white
        ]
        
        // Bilingual column headers
        ("Description / Omschrijving" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 8), withAttributes: headerAttrs)
        ("Unité" as NSString).draw(at: CGPoint(x: margin + 240, y: y + 8), withAttributes: headerAttrs)
        ("Eenheid" as NSString).draw(at: CGPoint(x: margin + 240, y: y + 23), withAttributes: [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)
        ])
        ("Qté" as NSString).draw(at: CGPoint(x: margin + 300, y: y + 8), withAttributes: headerAttrs)
        ("Hoev." as NSString).draw(at: CGPoint(x: margin + 300, y: y + 23), withAttributes: [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)
        ])
        ("P.U. HT" as NSString).draw(at: CGPoint(x: margin + 350, y: y + 8), withAttributes: headerAttrs)
        ("Eenh. excl" as NSString).draw(at: CGPoint(x: margin + 350, y: y + 23), withAttributes: [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)
        ])
        ("TVA/BTW" as NSString).draw(at: CGPoint(x: margin + 420, y: y + 15), withAttributes: headerAttrs)
        ("Total HT" as NSString).draw(at: CGPoint(x: margin + 480, y: y + 8), withAttributes: headerAttrs)
        ("Tot. excl" as NSString).draw(at: CGPoint(x: margin + 480, y: y + 23), withAttributes: [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)
        ])
        
        y += headerHeight
        
        // Items
        let items = (document.lineItems as? Set<LineItem> ?? []).sorted { $0.position < $1.position }
        let rowHeight: CGFloat = 40
        
        for (index, item) in items.enumerated() {
            let rowRect = CGRect(x: margin, y: y, width: tableWidth, height: rowHeight)
            if index % 2 == 0 {
                lightGray.withAlphaComponent(0.5).setFill()
                ctx.fill(rowRect)
            }
            
            let itemAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: primaryBlack
            ]
            
            // Description
            if let desc = item.itemDescription {
                let para = NSMutableParagraphStyle()
                para.lineBreakMode = .byWordWrapping
                var attrs = itemAttrs
                attrs[.paragraphStyle] = para
                (desc as NSString).draw(in: CGRect(x: margin + 15, y: y + 10, width: 220, height: 30), withAttributes: attrs)
            }
            
            // Unit
            let unit = (item.value(forKey: "unit") as? String) ?? ""
            (unit as NSString).draw(at: CGPoint(x: margin + 240, y: y + 15), withAttributes: itemAttrs)
            
            // Quantity
            let qty = formatNumber(item.quantity ?? 0)
            (qty as NSString).draw(at: CGPoint(x: margin + 300, y: y + 15), withAttributes: itemAttrs)
            
            // Unit price
            let unitPrice = formatCurrency(item.unitPrice ?? 0, currency: document.currencyCode ?? "EUR")
            (unitPrice as NSString).draw(at: CGPoint(x: margin + 350, y: y + 15), withAttributes: itemAttrs)
            
            // Tax rate
            let taxRate = getTaxRateDisplay(item.taxRate)
            (taxRate as NSString).draw(at: CGPoint(x: margin + 420, y: y + 15), withAttributes: itemAttrs)
            
            // Line total
            let lineTotal = calculateLineTotal(item)
            let total = formatCurrency(lineTotal, currency: document.currencyCode ?? "EUR")
            (total as NSString).draw(at: CGPoint(x: margin + 480, y: y + 15), withAttributes: itemAttrs)
            
            y += rowHeight
        }
        
        // Table border
        primaryBlack.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: margin, y: startY + headerHeight, width: tableWidth, height: y - startY - headerHeight))
        
        return y
    }
    
    private func drawTotals(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth: CGFloat = 320
        let x = bounds.width - margin - boxWidth
        
        // Calculate totals by tax rate
        let items = (document.lineItems as? Set<LineItem> ?? [])
        var totalsByRate: [Double: (ht: NSDecimalNumber, tva: NSDecimalNumber)] = [:]
        
        for item in items {
            let net = calculateLineTotal(item)
            let rate = Double(item.taxRate)
            let tva = net.multiplying(by: NSDecimalNumber(value: rate)).dividing(by: 100)
            
            if let existing = totalsByRate[rate] {
                totalsByRate[rate] = (existing.ht.adding(net), existing.tva.adding(tva))
            } else {
                totalsByRate[rate] = (net, tva)
            }
        }
        
        // Background box
        let bgHeight = CGFloat(120 + totalsByRate.count * 25)
        let bgRect = CGRect(x: x, y: y, width: boxWidth, height: bgHeight)
        lightGray.setFill()
        ctx.fill(bgRect)
        
        primaryBlack.setStroke()
        ctx.setLineWidth(2)
        ctx.stroke(bgRect)
        
        let currency = document.currencyCode ?? "EUR"
        var currentY = y + 20
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: primaryBlack
        ]
        
        // Subtotal
        let totalHT = totalsByRate.values.reduce(NSDecimalNumber.zero) { $0.adding($1.ht) }
        ("Total HT / Totaal excl. BTW :" as NSString).draw(at: CGPoint(x: x + 20, y: currentY), withAttributes: normalAttrs)
        (formatCurrency(totalHT, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 110, y: currentY),
            withAttributes: normalAttrs
        )
        currentY += 25
        
        // Tax details
        for (rate, totals) in totalsByRate.sorted(by: { $0.key < $1.key }) {
            let rateText = getTaxRateDisplay(rate)
            ("TVA/BTW \(rateText) :" as NSString).draw(at: CGPoint(x: x + 20, y: currentY), withAttributes: normalAttrs)
            (formatCurrency(totals.tva, currency: currency) as NSString).draw(
                at: CGPoint(x: x + boxWidth - 110, y: currentY),
                withAttributes: normalAttrs
            )
            currentY += 25
        }
        
        // Separator line
        ctx.setStrokeColor(primaryBlack.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: x + 20, y: currentY))
        ctx.addLine(to: CGPoint(x: x + boxWidth - 20, y: currentY))
        ctx.strokePath()
        currentY += 10
        
        // Total TTC
        let totalTVA = totalsByRate.values.reduce(NSDecimalNumber.zero) { $0.adding($1.tva) }
        let totalTTC = totalHT.adding(totalTVA)
        
        let totalRect = CGRect(x: x, y: currentY, width: boxWidth, height: 45)
        primaryBlack.setFill()
        ctx.fill(totalRect)
        
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        ("TOTAL TTC / TOTAAL incl. BTW :" as NSString).draw(at: CGPoint(x: x + 20, y: currentY + 10), withAttributes: totalAttrs)
        (formatCurrency(totalTTC, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 130, y: currentY + 10),
            withAttributes: totalAttrs
        )
        
        return y + bgHeight
    }
    
    private func drawPaymentInfo(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Payment conditions box with Belgian colors
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 120)
        NSColor.white.setFill()
        ctx.fill(boxRect)
        
        // Colored left border
        let borderWidth: CGFloat = 5
        primaryBlack.setFill()
        ctx.fill(CGRect(x: margin, y: y, width: borderWidth, height: 40))
        accentYellow.setFill()
        ctx.fill(CGRect(x: margin, y: y + 40, width: borderWidth, height: 40))
        accentRed.setFill()
        ctx.fill(CGRect(x: margin, y: y + 80, width: borderWidth, height: 40))
        
        mediumGray.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: margin + borderWidth, y: y, width: bounds.width - margin * 2 - borderWidth, height: 120))
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryBlack
        ]
        ("CONDITIONS DE PAIEMENT / BETALINGSVOORWAARDEN" as NSString).draw(
            at: CGPoint(x: margin + 20, y: y + 10),
            withAttributes: titleAttrs
        )
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        
        var contentY = y + 35
        
        // Payment terms
        if let dueDate = document.dueDate {
            let df = DateFormatter()
            df.locale = Locale(identifier: "fr_BE")
            df.dateFormat = "d MMMM yyyy"
            ("📅 Échéance / Vervaldatum : \(df.string(from: dueDate))" as NSString).draw(
                at: CGPoint(x: margin + 20, y: contentY),
                withAttributes: contentAttrs
            )
            contentY += 20
        }
        
        // Bank details
        let iban = UserDefaults.standard.string(forKey: "companyIBAN") ?? ""
        if !iban.isEmpty {
            ("🏦 IBAN : \(iban)" as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: contentAttrs)
            contentY += 20
            
            let bank = UserDefaults.standard.string(forKey: "companyBank") ?? ""
            if !bank.isEmpty {
                ("Bank / Banque : \(bank)" as NSString).draw(at: CGPoint(x: margin + 40, y: contentY), withAttributes: contentAttrs)
                contentY += 20
            }
        }
        
        // Structured communication for Belgium
        let communication = generateStructuredCommunication(document.number ?? "")
        ("📝 Communication structurée / Gestructureerde mededeling : \(communication)" as NSString).draw(
            at: CGPoint(x: margin + 20, y: contentY),
            withAttributes: contentAttrs
        )
        contentY += 20
        
        // Penalties
        ("⚠️ Pénalités de retard / Verwijlinteresten : 10% • Frais de recouvrement / Invorderingskosten : 40 €" as NSString).draw(
            at: CGPoint(x: margin + 20, y: contentY),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 10),
                .foregroundColor: accentRed
            ]
        )
        
        return y + 120
    }
    
    private func drawLegalMentions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: primaryBlack
        ]
        ("MENTIONS LÉGALES / WETTELIJKE VERMELDINGEN" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: mediumGray
        ]
        
        y += 20
        let mentions = [
            "• Travaux conformes aux normes belges (NBN) et européennes (CE) / Werken conform Belgische (NBN) en Europese (CE) normen",
            "• Garantie décennale : 10 ans (gros œuvre) / Tienjarige aansprakelijkheid: 10 jaar (ruwbouw)",
            "• TVA applicable selon taux en vigueur (6% rénovation >10 ans, 21% neuf) / BTW volgens geldende tarieven",
            "• Facture payable au grand comptant sauf accord contraire / Factuur contant betaalbaar tenzij anders overeengekomen",
            "• Réserve de propriété jusqu'au paiement complet / Eigendomsvoorbehoud tot volledige betaling",
            "• Tribunal compétent : \(UserDefaults.standard.string(forKey: "companyCity") ?? "Bruxelles") / Bevoegde rechtbank: \(UserDefaults.standard.string(forKey: "companyCity") ?? "Brussel")"
        ]
        
        for mention in mentions {
            (mention as NSString).draw(in: CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 30), withAttributes: contentAttrs)
            y += 25
        }
        
        return y
    }
    
    private func drawFooter(ctx: CGContext) {
        let footerY = bounds.height - 40
        
        // Footer with Belgian flag colors
        primaryBlack.setFill()
        ctx.fill(CGRect(x: 0, y: footerY, width: bounds.width / 3, height: 40))
        accentYellow.setFill()
        ctx.fill(CGRect(x: bounds.width / 3, y: footerY, width: bounds.width / 3, height: 40))
        accentRed.setFill()
        ctx.fill(CGRect(x: 2 * bounds.width / 3, y: footerY, width: bounds.width / 3, height: 40))
        
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: NSColor.white
        ]
        
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? ""
        let bce = UserDefaults.standard.string(forKey: "companyBCE") ?? ""
        let insurance = UserDefaults.standard.string(forKey: "insuranceNumber") ?? ""
        
        var footerText = companyName
        if !bce.isEmpty { footerText += " • BCE/KBO: \(bce)" }
        if !insurance.isEmpty { footerText += " • Assurance RC: \(insurance)" }
        
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        var attrs = footerAttrs
        attrs[.paragraphStyle] = para
        
        (footerText as NSString).draw(
            in: CGRect(x: margin, y: footerY + 15, width: bounds.width - margin * 2, height: 20),
            withAttributes: attrs
        )
    }
    
    // Helper functions
    private func formatCurrency(_ value: NSDecimalNumber, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "fr_BE")
        return formatter.string(from: value) ?? "0,00 €"
    }
    
    private func formatNumber(_ value: NSDecimalNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_BE")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value) ?? "0"
    }
    
    private func calculateLineTotal(_ item: LineItem) -> NSDecimalNumber {
        let qty = item.quantity ?? 0
        let unitPrice = item.unitPrice ?? 0
        let lineTotal = qty.multiplying(by: unitPrice)
        
        // Apply discount
        let discountRate = NSDecimalNumber(value: max(0, min(100, item.discount)))
        let discountAmount = lineTotal.multiplying(by: discountRate).dividing(by: 100)
        return lineTotal.subtracting(discountAmount)
    }
    
    private func getTaxRateDisplay(_ rate: Double) -> String {
        switch rate {
        case 0: return "0%"
        case 6: return "6% (rénov.)"
        case 21: return "21%"
        default: return "\(Int(rate))%"
        }
    }
    
    private func generateStructuredCommunication(_ invoiceNumber: String) -> String {
        // Generate Belgian structured communication (OGM/VCS)
        let numbers = invoiceNumber.compactMap { $0.isNumber ? String($0) : nil }.joined()
        let padded = String(repeating: "0", count: max(0, 10 - numbers.count)) + numbers
        let truncated = String(padded.prefix(10))
        
        // Calculate modulo 97
        if let num = Int(truncated) {
            let checkDigit = 97 - (num % 97)
            let formatted = "+++\(truncated.prefix(3))/\(truncated.dropFirst(3).prefix(4))/\(truncated.suffix(3))\(String(format: "%02d", checkDigit))+++"
            return formatted
        }
        return "+++000/0000/00000+++"
    }
}

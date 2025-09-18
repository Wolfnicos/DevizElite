import Foundation
import AppKit
import PDFKit

// MARK: - Belgian Construction Quote (Devis/Offerte) Template
final class BEConstructionQuoteTemplate {
    private let pageSize = CGSize(width: 595, height: 842) // A4
    private let margin: CGFloat = 40
    
    // Belgian construction color scheme
    private let primaryBlack = NSColor(calibratedWhite: 0.1, alpha: 1.0)
    private let accentYellow = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // #FFCC00
    private let accentRed = NSColor(calibratedRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0) // #CC0000
    private let lightGray = NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
    private let mediumGray = NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    
    func generate(document: Document) -> Data? {
        let view = BEQuoteView(
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

private final class BEQuoteView: NSView {
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
        currentY = drawProjectDescription(ctx: ctx, startY: currentY + 20)
        currentY = drawItemsTable(ctx: ctx, startY: currentY + 20)
        currentY = drawTotals(ctx: ctx, startY: currentY + 20)
        currentY = drawOptions(ctx: ctx, startY: currentY + 20)
        currentY = drawConditions(ctx: ctx, startY: currentY + 20)
        currentY = drawGuarantees(ctx: ctx, startY: currentY + 20)
        currentY = drawSignatures(ctx: ctx, startY: currentY + 30)
        drawFooter(ctx: ctx)
    }
    
    private func drawHeader(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        
        // Belgian flag design element
        let flagWidth: CGFloat = bounds.width - margin * 2
        let flagHeight: CGFloat = 8
        
        primaryBlack.setFill()
        ctx.fill(CGRect(x: margin, y: y, width: flagWidth / 3, height: flagHeight))
        accentYellow.setFill()
        ctx.fill(CGRect(x: margin + flagWidth / 3, y: y, width: flagWidth / 3, height: flagHeight))
        accentRed.setFill()
        ctx.fill(CGRect(x: margin + 2 * flagWidth / 3, y: y, width: flagWidth / 3, height: flagHeight))
        
        y += 20
        
        // Company logo area with gradient
        let logoRect = CGRect(x: margin, y: y, width: 160, height: 80)
        let gradient = NSGradient(colors: [lightGray, NSColor.white])
        gradient?.draw(in: logoRect, angle: 90)
        
        primaryBlack.setStroke()
        ctx.setLineWidth(2)
        ctx.stroke(logoRect)
        
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? "Entreprise BTP"
        let companyAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 20),
            .foregroundColor: primaryBlack
        ]
        let nameSize = (companyName as NSString).size(withAttributes: companyAttrs)
        (companyName as NSString).draw(
            at: CGPoint(x: logoRect.midX - nameSize.width/2, y: logoRect.midY - nameSize.height/2),
            withAttributes: companyAttrs
        )
        
        // DEVIS / OFFERTE title
        let titleFrAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 42),
            .foregroundColor: primaryBlack
        ]
        let titleNlAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 28),
            .foregroundColor: mediumGray
        ]
        
        let titleFr = "DEVIS" as NSString
        let titleFrSize = titleFr.size(withAttributes: titleFrAttrs)
        titleFr.draw(at: CGPoint(x: bounds.width - margin - titleFrSize.width, y: y), withAttributes: titleFrAttrs)
        
        let titleNl = "OFFERTE" as NSString
        let titleNlSize = titleNl.size(withAttributes: titleNlAttrs)
        titleNl.draw(at: CGPoint(x: bounds.width - margin - titleNlSize.width, y: y + 45), withAttributes: titleNlAttrs)
        
        // Quote info with badge
        let infoY = y + 80
        let badgeRect = CGRect(x: bounds.width - margin - 160, y: infoY, width: 150, height: 30)
        accentYellow.withAlphaComponent(0.3).setFill()
        let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 15, yRadius: 15)
        badgePath.fill()
        
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: primaryBlack
        ]
        let number = "N° \(document.number ?? "-")" as NSString
        let numberSize = number.size(withAttributes: infoAttrs)
        number.draw(at: CGPoint(x: badgeRect.midX - numberSize.width/2, y: badgeRect.midY - numberSize.height/2), withAttributes: infoAttrs)
        
        return y + 120
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
        
        // Validity
        let validityDays = (document.value(forKey: "validityDays") as? Int16) ?? 30
        ("Validité / Geldigheid :" as NSString).draw(at: CGPoint(x: margin + 300, y: y), withAttributes: labelAttrs)
        ("\(validityDays) jours/dagen" as NSString).draw(at: CGPoint(x: margin + 450, y: y), withAttributes: valueAttrs)
        
        return y + 20
    }
    
    private func drawCompanyAndClient(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth = (bounds.width - margin * 2 - 30) / 2
        let boxHeight: CGFloat = 150
        
        // Émetteur / Verstuurder box with professional design
        let emitterRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        
        // Gradient background
        let emitterGradient = NSGradient(colors: [lightGray, lightGray.blended(withFraction: 0.5, of: .white)!])
        emitterGradient?.draw(in: emitterRect, angle: 90)
        
        // Black accent bar
        primaryBlack.setFill()
        ctx.fill(CGRect(x: margin, y: y, width: 6, height: boxHeight))
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryBlack
        ]
        
        // Icon + title
        ("🏢 ENTREPRISE / ONDERNEMING" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 10), withAttributes: headerAttrs)
        
        // Company details
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        
        var contentY = y + 35
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? ""
        if !companyName.isEmpty {
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: primaryBlack
            ]
            (companyName as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: boldAttrs)
            contentY += 22
        }
        
        let companyAddress = UserDefaults.standard.string(forKey: "companyAddress") ?? ""
        if !companyAddress.isEmpty {
            (companyAddress as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        // Contact info
        let phone = UserDefaults.standard.string(forKey: "companyPhone") ?? ""
        if !phone.isEmpty {
            ("📞 \(phone)" as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        let email = UserDefaults.standard.string(forKey: "companyEmail") ?? ""
        if !email.isEmpty {
            ("✉️ \(email)" as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        // Tax info
        let taxId = UserDefaults.standard.string(forKey: "companyTaxId") ?? ""
        if !taxId.isEmpty {
            ("TVA/BTW : \(taxId)" as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: contentAttrs)
        }
        
        // Client / Klant box
        let clientRect = CGRect(x: margin + boxWidth + 30, y: y, width: boxWidth, height: boxHeight)
        NSColor.white.setFill()
        ctx.fill(clientRect)
        
        // Double border effect
        accentYellow.setStroke()
        ctx.setLineWidth(3)
        ctx.stroke(clientRect)
        primaryBlack.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(clientRect.insetBy(dx: 3, dy: 3))
        
        // Yellow accent bar
        accentYellow.setFill()
        ctx.fill(CGRect(x: margin + boxWidth + 30 + boxWidth - 6, y: y, width: 6, height: boxHeight))
        
        ("👤 CLIENT / KLANT" as NSString).draw(at: CGPoint(x: margin + boxWidth + 50, y: y + 10), withAttributes: headerAttrs)
        
        // Client details
        if let client = document.safeClient {
            contentY = y + 35
            if let name = client.name, !name.isEmpty {
                let boldAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 13),
                    .foregroundColor: primaryBlack
                ]
                (name as NSString).draw(at: CGPoint(x: margin + boxWidth + 50, y: contentY), withAttributes: boldAttrs)
                contentY += 22
            }
            
            let clientDetails = [
                client.address,
                client.city,
                client.country,
                client.phone.map { "📞 \($0)" },
                client.taxId.map { "TVA/BTW : \($0)" }
            ].compactMap { $0 }.filter { !$0.isEmpty }
            
            for detail in clientDetails {
                (detail as NSString).draw(at: CGPoint(x: margin + boxWidth + 50, y: contentY), withAttributes: contentAttrs)
                contentY += 18
            }
        } else {
            // Placeholder
            let placeholderAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11).with(traits: .italicFontMask),
                .foregroundColor: mediumGray
            ]
            ("À compléter / In te vullen" as NSString).draw(
                at: CGPoint(x: margin + boxWidth + 50, y: y + 70),
                withAttributes: placeholderAttrs
            )
        }
        
        return y + boxHeight
    }
    
    private func drawProjectDescription(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Project description box with icons
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 120)
        
        // Gradient background
        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.94, alpha: 1.0),
            NSColor.white
        ])
        gradient?.draw(in: boxRect, angle: 90)
        
        // Belgian tri-color top border
        ctx.setLineWidth(3)
        primaryBlack.setStroke()
        ctx.stroke(CGRect(x: margin, y: y, width: (bounds.width - margin * 2) / 3, height: 1))
        accentYellow.setStroke()
        ctx.stroke(CGRect(x: margin + (bounds.width - margin * 2) / 3, y: y, width: (bounds.width - margin * 2) / 3, height: 1))
        accentRed.setStroke()
        ctx.stroke(CGRect(x: margin + 2 * (bounds.width - margin * 2) / 3, y: y, width: (bounds.width - margin * 2) / 3, height: 1))
        
        primaryBlack.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: margin, y: y + 3, width: bounds.width - margin * 2, height: 117))
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: primaryBlack
        ]
        ("DESCRIPTION DU PROJET / PROJECTOMSCHRIJVING 📋" as NSString).draw(
            at: CGPoint(x: margin + 20, y: y + 15),
            withAttributes: titleAttrs
        )
        
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: mediumGray
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        
        // Site address
        ("🏗️ Adresse chantier / Werfadres :" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 45), withAttributes: labelAttrs)
        let siteAddress = (document.value(forKey: "siteAddress") as? String) ?? "À définir / Te bepalen"
        (siteAddress as NSString).draw(at: CGPoint(x: margin + 250, y: y + 45), withAttributes: valueAttrs)
        
        // Project type
        ("🔨 Nature des travaux / Aard werken :" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 70), withAttributes: labelAttrs)
        let projectName = (document.value(forKey: "projectName") as? String) ?? "À définir / Te bepalen"
        (projectName as NSString).draw(at: CGPoint(x: margin + 250, y: y + 70), withAttributes: valueAttrs)
        
        // Duration
        ("📅 Durée estimée / Geschatte duur :" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 95), withAttributes: labelAttrs)
        let duration = (document.value(forKey: "estimatedDuration") as? String) ?? "À convenir / Overeen te komen"
        (duration as NSString).draw(at: CGPoint(x: margin + 250, y: y + 95), withAttributes: valueAttrs)
        
        return y + 120
    }
    
    private func drawItemsTable(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let tableWidth = bounds.width - margin * 2
        
        // Table header with Belgian styling
        let headerHeight: CGFloat = 50
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: headerHeight)
        
        // Header gradient
        let headerGradient = NSGradient(colors: [primaryBlack, primaryBlack.blended(withFraction: 0.1, of: accentYellow)!])
        headerGradient?.draw(in: headerRect, angle: 90)
        
        // Yellow accent line at top
        accentYellow.setFill()
        ctx.fill(CGRect(x: margin, y: y, width: tableWidth, height: 3))
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.white
        ]
        let subHeaderAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)
        ]
        
        // Bilingual headers
        ("Description des travaux" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 10), withAttributes: headerAttrs)
        ("Omschrijving werken" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 25), withAttributes: subHeaderAttrs)
        
        ("Unité" as NSString).draw(at: CGPoint(x: margin + 280, y: y + 10), withAttributes: headerAttrs)
        ("Eenh." as NSString).draw(at: CGPoint(x: margin + 280, y: y + 25), withAttributes: subHeaderAttrs)
        
        ("Quantité" as NSString).draw(at: CGPoint(x: margin + 340, y: y + 10), withAttributes: headerAttrs)
        ("Hoeveel." as NSString).draw(at: CGPoint(x: margin + 340, y: y + 25), withAttributes: subHeaderAttrs)
        
        ("P.U. HT" as NSString).draw(at: CGPoint(x: margin + 410, y: y + 10), withAttributes: headerAttrs)
        ("Eenh. excl" as NSString).draw(at: CGPoint(x: margin + 410, y: y + 25), withAttributes: subHeaderAttrs)
        
        ("Total HT" as NSString).draw(at: CGPoint(x: margin + 490, y: y + 10), withAttributes: headerAttrs)
        ("Tot. excl" as NSString).draw(at: CGPoint(x: margin + 490, y: y + 25), withAttributes: subHeaderAttrs)
        
        y += headerHeight
        
        // Items with phase grouping
        let items = (document.lineItems as? Set<LineItem> ?? []).sorted { $0.position < $1.position }
        let rowHeight: CGFloat = 55
        
        for (index, item) in items.enumerated() {
            let rowRect = CGRect(x: margin, y: y, width: tableWidth, height: rowHeight)
            
            // Alternating row colors
            if index % 2 == 0 {
                lightGray.withAlphaComponent(0.3).setFill()
            } else {
                NSColor.white.setFill()
            }
            ctx.fill(rowRect)
            
            // Phase/LOT indicator
            let phaseRect = CGRect(x: margin + 5, y: y + 5, width: 60, height: 25)
            let phaseColor = index < 3 ? accentRed : (index < 6 ? accentYellow : primaryBlack)
            phaseColor.withAlphaComponent(0.2).setFill()
            let phasePath = NSBezierPath(roundedRect: phaseRect, xRadius: 12, yRadius: 12)
            phasePath.fill()
            
            let phaseAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 10),
                .foregroundColor: phaseColor
            ]
            let phaseText = "PHASE \(index / 3 + 1)" as NSString
            let phaseSize = phaseText.size(withAttributes: phaseAttrs)
            phaseText.draw(at: CGPoint(x: phaseRect.midX - phaseSize.width/2, y: phaseRect.midY - phaseSize.height/2), withAttributes: phaseAttrs)
            
            // Description
            let descAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: primaryBlack
            ]
            if let desc = item.itemDescription {
                let para = NSMutableParagraphStyle()
                para.lineBreakMode = .byWordWrapping
                var attrs = descAttrs
                attrs[.paragraphStyle] = para
                (desc as NSString).draw(in: CGRect(x: margin + 15, y: y + 33, width: 250, height: 20), withAttributes: attrs)
            }
            
            // Other columns
            let unit = (item.value(forKey: "unit") as? String) ?? ""
            (unit as NSString).draw(at: CGPoint(x: margin + 280, y: y + 20), withAttributes: descAttrs)
            
            let qty = formatNumber(item.quantity ?? 0)
            (qty as NSString).draw(at: CGPoint(x: margin + 340, y: y + 20), withAttributes: descAttrs)
            
            let unitPrice = formatCurrency(item.unitPrice ?? 0, currency: document.currencyCode ?? "EUR")
            (unitPrice as NSString).draw(at: CGPoint(x: margin + 410, y: y + 20), withAttributes: descAttrs)
            
            let lineTotal = calculateLineTotal(item)
            let totalAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 11),
                .foregroundColor: primaryBlack
            ]
            let total = formatCurrency(lineTotal, currency: document.currencyCode ?? "EUR")
            (total as NSString).draw(at: CGPoint(x: margin + 490, y: y + 20), withAttributes: totalAttrs)
            
            y += rowHeight
        }
        
        // Table border
        primaryBlack.setStroke()
        ctx.setLineWidth(1.5)
        ctx.stroke(CGRect(x: margin, y: startY + headerHeight, width: tableWidth, height: y - startY - headerHeight))
        
        return y
    }
    
    private func drawTotals(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth: CGFloat = 340
        let x = bounds.width - margin - boxWidth
        
        // Calculate totals
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
        
        // Professional shadow effect
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 3, height: 3), blur: 8, color: NSColor.black.withAlphaComponent(0.2).cgColor)
        
        let bgHeight = CGFloat(160 + totalsByRate.count * 25)
        let bgRect = CGRect(x: x, y: y, width: boxWidth, height: bgHeight)
        NSColor.white.setFill()
        ctx.fill(bgRect)
        ctx.restoreGState()
        
        // Border with accent
        primaryBlack.setStroke()
        ctx.setLineWidth(2)
        ctx.stroke(bgRect)
        
        // Yellow accent stripe
        accentYellow.setFill()
        ctx.fill(CGRect(x: x, y: y, width: boxWidth, height: 5))
        
        let currency = document.currencyCode ?? "EUR"
        var currentY = y + 25
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryBlack
        ]
        ("RÉCAPITULATIF / SAMENVATTING" as NSString).draw(at: CGPoint(x: x + 20, y: currentY), withAttributes: titleAttrs)
        currentY += 30
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: primaryBlack
        ]
        
        // Subtotals by tax rate
        for (rate, totals) in totalsByRate.sorted(by: { $0.key < $1.key }) {
            let rateText = getTaxRateDisplay(rate)
            ("Montant HT (TVA/BTW \(rateText)) :" as NSString).draw(at: CGPoint(x: x + 20, y: currentY), withAttributes: normalAttrs)
            (formatCurrency(totals.ht, currency: currency) as NSString).draw(
                at: CGPoint(x: x + boxWidth - 120, y: currentY),
                withAttributes: normalAttrs
            )
            currentY += 25
        }
        
        // Separator
        currentY += 5
        ctx.setStrokeColor(mediumGray.cgColor)
        ctx.setLineWidth(1)
        ctx.setLineDash(phase: 0, lengths: [5, 3])
        ctx.move(to: CGPoint(x: x + 20, y: currentY))
        ctx.addLine(to: CGPoint(x: x + boxWidth - 20, y: currentY))
        ctx.strokePath()
        ctx.setLineDash(phase: 0, lengths: [])
        currentY += 10
        
        // Total HT
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: primaryBlack
        ]
        let totalHT = totalsByRate.values.reduce(NSDecimalNumber.zero) { $0.adding($1.ht) }
        ("TOTAL HT / TOTAAL excl. BTW :" as NSString).draw(at: CGPoint(x: x + 20, y: currentY), withAttributes: boldAttrs)
        (formatCurrency(totalHT, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 120, y: currentY),
            withAttributes: boldAttrs
        )
        currentY += 30
        
        // TVA amounts
        for (rate, totals) in totalsByRate.sorted(by: { $0.key < $1.key }) {
            if rate > 0 {
                let rateText = getTaxRateDisplay(rate)
                ("TVA/BTW \(rateText) :" as NSString).draw(at: CGPoint(x: x + 20, y: currentY), withAttributes: normalAttrs)
                (formatCurrency(totals.tva, currency: currency) as NSString).draw(
                    at: CGPoint(x: x + boxWidth - 120, y: currentY),
                    withAttributes: normalAttrs
                )
                currentY += 20
            }
        }
        
        // Total TTC box
        let totalRect = CGRect(x: x, y: y + bgHeight - 50, width: boxWidth, height: 50)
        let totalGradient = NSGradient(colors: [primaryBlack, primaryBlack.blended(withFraction: 0.2, of: accentRed)!])
        totalGradient?.draw(in: totalRect, angle: 90)
        
        let totalTVA = totalsByRate.values.reduce(NSDecimalNumber.zero) { $0.adding($1.tva) }
        let totalTTC = totalHT.adding(totalTVA)
        
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        ("TOTAL TTC / TOTAAL incl. :" as NSString).draw(at: CGPoint(x: x + 20, y: y + bgHeight - 35), withAttributes: totalAttrs)
        (formatCurrency(totalTTC, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 140, y: y + bgHeight - 35),
            withAttributes: totalAttrs
        )
        
        return y + bgHeight
    }
    
    private func drawOptions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Options box with Belgian styling
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 120)
        
        // Light background
        NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.95, alpha: 1.0).setFill()
        ctx.fill(boxRect)
        
        // Dashed border
        accentYellow.setStroke()
        ctx.setLineWidth(2)
        ctx.setLineDash(phase: 0, lengths: [10, 5])
        let path = NSBezierPath(roundedRect: boxRect, xRadius: 8, yRadius: 8)
        path.stroke()
        ctx.setLineDash(phase: 0, lengths: [])
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryBlack
        ]
        ("💡 OPTIONS SUPPLÉMENTAIRES / BIJKOMENDE OPTIES" as NSString).draw(
            at: CGPoint(x: margin + 20, y: y + 10),
            withAttributes: titleAttrs
        )
        
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10).with(traits: .italicFontMask),
            .foregroundColor: mediumGray
        ]
        ("(Non incluses dans ce devis / Niet inbegrepen in deze offerte)" as NSString).draw(
            at: CGPoint(x: margin + 20, y: y + 30),
            withAttributes: subtitleAttrs
        )
        
        let optionAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        
        let options = [
            "• Pompe à chaleur air/eau (PAC) / Lucht-water warmtepomp : 8.500,00 € HTVA/excl. BTW",
            "• Panneaux photovoltaïques 5kWc / Zonnepanelen 5kWc : 7.000,00 € HTVA/excl. BTW",
            "• Système domotique KNX / KNX domotica systeem : 5.000,00 € HTVA/excl. BTW",
            "• Récupération eau de pluie / Regenwater recuperatie : 4.500,00 € HTVA/excl. BTW"
        ]
        
        var optionY = y + 50
        for option in options {
            (option as NSString).draw(at: CGPoint(x: margin + 25, y: optionY), withAttributes: optionAttrs)
            optionY += 18
        }
        
        return y + 120
    }
    
    private func drawConditions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Two-column layout for conditions and planning
        let columnWidth = (bounds.width - margin * 2 - 20) / 2
        let boxHeight: CGFloat = 140
        
        // Payment conditions
        let conditionsRect = CGRect(x: margin, y: y, width: columnWidth, height: boxHeight)
        NSColor.white.setFill()
        ctx.fill(conditionsRect)
        
        // Green gradient border
        let greenGradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.2, green: 0.6, blue: 0.2, alpha: 1.0),
            NSColor(calibratedRed: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        ])
        let borderPath = NSBezierPath(roundedRect: conditionsRect, xRadius: 8, yRadius: 8)
        borderPath.lineWidth = 3
        ctx.saveGState()
        borderPath.addClip()
        greenGradient?.draw(in: conditionsRect, angle: 45)
        ctx.restoreGState()
        
        // Inner white fill
        let innerRect = conditionsRect.insetBy(dx: 3, dy: 3)
        NSColor.white.setFill()
        let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: 5, yRadius: 5)
        innerPath.fill()
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: NSColor(calibratedRed: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        ]
        ("CONDITIONS DE PAIEMENT" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 10), withAttributes: titleAttrs)
        ("BETALINGSVOORWAARDEN" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 28), withAttributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: mediumGray
        ])
        
        let conditionAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        
        let conditions = [
            "1️⃣ Acompte/Voorschot : 30%",
            "2️⃣ Début/Start : 35%",
            "3️⃣ Mi-parcours/Halfweg : 25%",
            "4️⃣ Réception/Oplevering : 10%"
        ]
        
        var condY = y + 50
        for condition in conditions {
            (condition as NSString).draw(at: CGPoint(x: margin + 15, y: condY), withAttributes: conditionAttrs)
            condY += 20
        }
        
        // Planning box
        let planningRect = CGRect(x: margin + columnWidth + 20, y: y, width: columnWidth, height: boxHeight)
        NSColor.white.setFill()
        ctx.fill(planningRect)
        
        // Blue border
        primaryBlack.setStroke()
        ctx.setLineWidth(2)
        ctx.stroke(planningRect)
        
        // Corner accents
        accentRed.setFill()
        ctx.fill(CGRect(x: planningRect.minX, y: planningRect.minY, width: 20, height: 3))
        ctx.fill(CGRect(x: planningRect.minX, y: planningRect.minY, width: 3, height: 20))
        ctx.fill(CGRect(x: planningRect.maxX - 20, y: planningRect.maxY - 3, width: 20, height: 3))
        ctx.fill(CGRect(x: planningRect.maxX - 3, y: planningRect.maxY - 20, width: 3, height: 20))
        
        ("PLANNING INDICATIF" as NSString).draw(
            at: CGPoint(x: planningRect.minX + 15, y: y + 10),
            withAttributes: [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: primaryBlack
            ]
        )
        ("INDICATIEVE PLANNING" as NSString).draw(
            at: CGPoint(x: planningRect.minX + 15, y: y + 28),
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: mediumGray
            ]
        )
        
        let planning = [
            "📅 Sem./Week 1-2 : Préparation",
            "📅 Sem./Week 3-8 : Gros œuvre",
            "📅 Sem./Week 9-14 : Techniques",
            "📅 Sem./Week 15-16 : Finitions"
        ]
        
        var planY = y + 50
        for plan in planning {
            (plan as NSString).draw(at: CGPoint(x: planningRect.minX + 15, y: planY), withAttributes: conditionAttrs)
            planY += 20
        }
        
        return y + boxHeight
    }
    
    private func drawGuarantees(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Guarantees box with premium design
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 120)
        
        // Gradient background
        let bgGradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.98, green: 0.98, blue: 1.0, alpha: 1.0),
            NSColor.white
        ])
        bgGradient?.draw(in: boxRect, angle: 90)
        
        // Multiple border effect
        primaryBlack.setStroke()
        ctx.setLineWidth(0.5)
        ctx.stroke(boxRect.insetBy(dx: 0, dy: 0))
        ctx.stroke(boxRect.insetBy(dx: 2, dy: 2))
        ctx.stroke(boxRect.insetBy(dx: 4, dy: 4))
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryBlack
        ]
        ("🛡️ NOS GARANTIES & CERTIFICATIONS / ONZE WAARBORGEN & CERTIFICATEN" as NSString).draw(
            at: CGPoint(x: margin + 20, y: y + 10),
            withAttributes: titleAttrs
        )
        
        let guaranteeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        
        let leftGuarantees = [
            "✅ Garantie décennale / Tienjarige aansprakelijkheid",
            "✅ Certification ISO 9001 / ISO 9001 certificaat",
            "✅ Label Construction Durable / Label Duurzaam Bouwen"
        ]
        
        let rightGuarantees = [
            "✅ Assurance RC professionnelle / Beroeps BA verzekering",
            "✅ Agrément entrepreneur / Erkenning aannemer",
            "✅ Personnel qualifié VCA / VCA gekwalificeerd personeel"
        ]
        
        var guaranteeY = y + 40
        for guarantee in leftGuarantees {
            (guarantee as NSString).draw(at: CGPoint(x: margin + 20, y: guaranteeY), withAttributes: guaranteeAttrs)
            guaranteeY += 22
        }
        
        guaranteeY = y + 40
        for guarantee in rightGuarantees {
            (guarantee as NSString).draw(at: CGPoint(x: margin + 320, y: guaranteeY), withAttributes: guaranteeAttrs)
            guaranteeY += 22
        }
        
        return y + 120
    }
    
    private func drawSignatures(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let boxWidth = (bounds.width - margin * 2 - 60) / 2
        
        // Signature areas with professional styling
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: primaryBlack
        ]
        
        ("LE CLIENT / DE KLANT" as NSString).draw(at: CGPoint(x: margin + boxWidth/2 - 60, y: y), withAttributes: titleAttrs)
        ("L'ENTREPRISE / HET BEDRIJF" as NSString).draw(at: CGPoint(x: bounds.width - margin - boxWidth/2 - 80, y: y), withAttributes: titleAttrs)
        
        y += 30
        
        // Signature boxes
        let clientBox = CGRect(x: margin, y: y, width: boxWidth, height: 80)
        let companyBox = CGRect(x: bounds.width - margin - boxWidth, y: y, width: boxWidth, height: 80)
        
        lightGray.setFill()
        ctx.fill(clientBox)
        ctx.fill(companyBox)
        
        // Signature lines
        ctx.setStrokeColor(primaryBlack.cgColor)
        ctx.setLineWidth(1)
        ctx.setLineDash(phase: 0, lengths: [8, 4])
        
        ctx.move(to: CGPoint(x: margin + 20, y: y + 50))
        ctx.addLine(to: CGPoint(x: margin + boxWidth - 20, y: y + 50))
        ctx.strokePath()
        
        ctx.move(to: CGPoint(x: bounds.width - margin - boxWidth + 20, y: y + 50))
        ctx.addLine(to: CGPoint(x: bounds.width - margin - 20, y: y + 50))
        ctx.strokePath()
        
        ctx.setLineDash(phase: 0, lengths: [])
        
        let noteAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: mediumGray
        ]
        
        ("Précédé de « Bon pour accord »" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 60), withAttributes: noteAttrs)
        ("Voorafgegaan door « Goed voor akkoord »" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 72), withAttributes: noteAttrs)
        
        ("Cachet et signature" as NSString).draw(at: CGPoint(x: bounds.width - margin - boxWidth + 20, y: y + 60), withAttributes: noteAttrs)
        ("Stempel en handtekening" as NSString).draw(at: CGPoint(x: bounds.width - margin - boxWidth + 20, y: y + 72), withAttributes: noteAttrs)
        
        return y + 100
    }
    
    private func drawFooter(ctx: CGContext) {
        let footerY = bounds.height - 60
        
        // Footer with Belgian flag wave effect
        let waveHeight: CGFloat = 20
        let _ = CGRect(x: 0, y: footerY, width: bounds.width, height: waveHeight)
        
        // Draw wave pattern with flag colors
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 0, y: footerY + 10))
        
        // Create wave
        for x in stride(from: 0, to: bounds.width, by: 20) {
            let y = footerY + 10 + sin(x * 0.05) * 5
            path.line(to: CGPoint(x: x, y: y))
        }
        
        path.line(to: CGPoint(x: bounds.width, y: footerY + waveHeight))
        path.line(to: CGPoint(x: 0, y: footerY + waveHeight))
        path.close()
        
        // Fill with gradient
        let flagGradient = NSGradient(colors: [primaryBlack, accentYellow, accentRed])
        flagGradient?.draw(in: path, angle: 0)
        
        // Footer text
        let footerRect = CGRect(x: 0, y: footerY + waveHeight, width: bounds.width, height: 40)
        NSColor.white.setFill()
        ctx.fill(footerRect)
        
        // Validity reminder badge
        let validityRect = CGRect(x: margin, y: footerY + waveHeight + 5, width: 220, height: 30)
        accentYellow.withAlphaComponent(0.2).setFill()
        let validityPath = NSBezierPath(roundedRect: validityRect, xRadius: 15, yRadius: 15)
        validityPath.fill()
        
        accentYellow.setStroke()
        ctx.setLineWidth(2)
        validityPath.stroke()
        
        let validityDays = (document.value(forKey: "validityDays") as? Int16) ?? 30
        let validityAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: primaryBlack
        ]
        ("⏰ Validité/Geldigheid : \(validityDays) jours/dagen" as NSString).draw(
            at: CGPoint(x: margin + 20, y: footerY + waveHeight + 13),
            withAttributes: validityAttrs
        )
        
        // Company info
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: primaryBlack
        ]
        
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? ""
        let bce = UserDefaults.standard.string(forKey: "companyBCE") ?? ""
        
        var footerText = companyName
        if !bce.isEmpty { footerText += " • BCE/KBO: \(bce)" }
        
        let para = NSMutableParagraphStyle()
        para.alignment = .right
        var attrs = footerAttrs
        attrs[.paragraphStyle] = para
        
        (footerText as NSString).draw(
            in: CGRect(x: margin, y: footerY + waveHeight + 10, width: bounds.width - margin * 2, height: 20),
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
        
        let discountRate = NSDecimalNumber(value: max(0, min(100, item.discount)))
        let discountAmount = lineTotal.multiplying(by: discountRate).dividing(by: 100)
        return lineTotal.subtracting(discountAmount)
    }
    
    private func getTaxRateDisplay(_ rate: Double) -> String {
        switch rate {
        case 0: return "0%"
        case 6: return "6%"
        case 21: return "21%"
        default: return "\(Int(rate))%"
        }
    }
}

// NSFont extension for font traits
extension NSFont {
    func with(traits: NSFontTraitMask) -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(NSFontDescriptor.SymbolicTraits(rawValue: UInt32(traits.rawValue)))
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}

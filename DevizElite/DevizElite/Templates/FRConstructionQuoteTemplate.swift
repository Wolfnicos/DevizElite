import Foundation
import AppKit
import PDFKit

// MARK: - French Construction Quote (Devis) Template
final class FRConstructionQuoteTemplate {
    private let pageSize = CGSize(width: 595, height: 842) // A4
    private let margin: CGFloat = 40
    
    // French construction color scheme for quotes
    private let primaryOrange = NSColor(calibratedRed: 1.0, green: 0.396, blue: 0.0, alpha: 1.0) // #FF6500
    private let secondaryBlue = NSColor(calibratedRed: 0.051, green: 0.278, blue: 0.631, alpha: 1.0) // #0D47A1
    private let lightGray = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
    private let darkGray = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    private let lightOrange = NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
    
    func generate(document: Document) -> Data? {
        let view = FRQuoteView(
            frame: CGRect(origin: .zero, size: pageSize),
            document: document,
            margin: margin,
            primaryOrange: primaryOrange,
            secondaryBlue: secondaryBlue,
            lightGray: lightGray,
            darkGray: darkGray,
            lightOrange: lightOrange
        )
        return view.dataWithPDF(inside: view.bounds)
    }
}

private final class FRQuoteView: NSView {
    private let document: Document
    private let margin: CGFloat
    private let primaryOrange: NSColor
    private let secondaryBlue: NSColor
    private let lightGray: NSColor
    private let darkGray: NSColor
    private let lightOrange: NSColor
    
    init(frame: CGRect, document: Document, margin: CGFloat, primaryOrange: NSColor, secondaryBlue: NSColor, lightGray: NSColor, darkGray: NSColor, lightOrange: NSColor) {
        self.document = document
        self.margin = margin
        self.primaryOrange = primaryOrange
        self.secondaryBlue = secondaryBlue
        self.lightGray = lightGray
        self.darkGray = darkGray
        self.lightOrange = lightOrange
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
        
        // Company logo/name with gradient
        let logoRect = CGRect(x: margin, y: y, width: 140, height: 80)
        let gradient = NSGradient(colors: [secondaryBlue, secondaryBlue.blended(withFraction: 0.2, of: .black)!])
        let path = NSBezierPath(roundedRect: logoRect, xRadius: 12, yRadius: 12)
        gradient?.draw(in: path, angle: -45)
        
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? "Entreprise BTP"
        let companyAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 22),
            .foregroundColor: NSColor.white
        ]
        let nameSize = (companyName as NSString).size(withAttributes: companyAttrs)
        (companyName as NSString).draw(
            at: CGPoint(x: logoRect.midX - nameSize.width/2, y: logoRect.midY - nameSize.height/2),
            withAttributes: companyAttrs
        )
        
        // DEVIS title with shadow
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 42),
            .foregroundColor: primaryOrange
        ]
        let title = "DEVIS" as NSString
        let titleSize = title.size(withAttributes: titleAttrs)
        
        // Shadow
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 2, height: 2), blur: 4, color: NSColor.black.withAlphaComponent(0.2).cgColor)
        title.draw(at: CGPoint(x: bounds.width - margin - titleSize.width, y: y), withAttributes: titleAttrs)
        ctx.restoreGState()
        
        // Quote info
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: darkGray
        ]
        
        let number = "N° \(document.number ?? "-")" as NSString
        number.draw(at: CGPoint(x: bounds.width - margin - 150, y: y + 50), withAttributes: infoAttrs)
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_FR")
        df.dateFormat = "d MMMM yyyy"
        let dateStr = "Date : \(df.string(from: document.issueDate ?? Date()))" as NSString
        dateStr.draw(at: CGPoint(x: bounds.width - margin - 150, y: y + 70), withAttributes: infoAttrs)
        
        // Validity badge
        let validityRect = CGRect(x: bounds.width - margin - 150, y: y + 90, width: 140, height: 25)
        lightOrange.setFill()
        let validityPath = NSBezierPath(roundedRect: validityRect, xRadius: 12, yRadius: 12)
        validityPath.fill()
        
        let validityDays = (document.value(forKey: "validityDays") as? Int16) ?? 30
        let validityAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: primaryOrange
        ]
        ("✓ Validité : \(validityDays) jours" as NSString).draw(
            at: CGPoint(x: validityRect.midX - 45, y: validityRect.midY - 8),
            withAttributes: validityAttrs
        )
        
        // Decorative line
        y += 125
        let gradientLine = NSGradient(colors: [primaryOrange, secondaryBlue])
        gradientLine?.draw(in: CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 3), angle: 0)
        
        return y
    }
    
    private func drawCompanyAndClient(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth = (bounds.width - margin * 2 - 30) / 2
        let boxHeight: CGFloat = 130
        
        // Émetteur box with gradient background
        let emitterRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        let emitterGradient = NSGradient(colors: [lightGray, NSColor.white])
        emitterGradient?.draw(in: emitterRect, angle: 90)
        
        secondaryBlue.setStroke()
        ctx.setLineWidth(2)
        ctx.stroke(emitterRect)
        
        // Blue accent bar
        secondaryBlue.setFill()
        ctx.fill(CGRect(x: margin, y: y, width: 5, height: boxHeight))
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: secondaryBlue
        ]
        ("ENTREPRISE" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 10), withAttributes: headerAttrs)
        
        // Company details
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        var contentY = y + 35
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? ""
        if !companyName.isEmpty {
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 12),
                .foregroundColor: darkGray
            ]
            (companyName as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: boldAttrs)
            contentY += 20
        }
        
        let companyAddress = UserDefaults.standard.string(forKey: "companyAddress") ?? ""
        if !companyAddress.isEmpty {
            (companyAddress as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        let phone = UserDefaults.standard.string(forKey: "companyPhone") ?? ""
        if !phone.isEmpty {
            ("📞 \(phone)" as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        let email = UserDefaults.standard.string(forKey: "companyEmail") ?? ""
        if !email.isEmpty {
            ("✉️ \(email)" as NSString).draw(at: CGPoint(x: margin + 20, y: contentY), withAttributes: contentAttrs)
        }
        
        // Client box
        let clientRect = CGRect(x: margin + boxWidth + 30, y: y, width: boxWidth, height: boxHeight)
        NSColor.white.setFill()
        ctx.fill(clientRect)
        primaryOrange.setStroke()
        ctx.setLineWidth(2)
        ctx.stroke(clientRect)
        
        // Orange accent bar
        primaryOrange.setFill()
        ctx.fill(CGRect(x: margin + boxWidth + 30 + boxWidth - 5, y: y, width: 5, height: boxHeight))
        
        ("CLIENT" as NSString).draw(at: CGPoint(x: margin + boxWidth + 50, y: y + 10), withAttributes: [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryOrange
        ])
        
        // Client details
        if let client = document.safeClient {
            contentY = y + 35
            if let name = client.name, !name.isEmpty {
                let boldAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 12),
                    .foregroundColor: darkGray
                ]
                (name as NSString).draw(at: CGPoint(x: margin + boxWidth + 50, y: contentY), withAttributes: boldAttrs)
                contentY += 20
            }
            if let address = client.address, !address.isEmpty {
                (address as NSString).draw(at: CGPoint(x: margin + boxWidth + 50, y: contentY), withAttributes: contentAttrs)
                contentY += 18
            }
            if let city = client.city, !city.isEmpty {
                (city as NSString).draw(at: CGPoint(x: margin + boxWidth + 50, y: contentY), withAttributes: contentAttrs)
                contentY += 18
            }
            if let phone = client.phone, !phone.isEmpty {
                ("📞 \(phone)" as NSString).draw(at: CGPoint(x: margin + boxWidth + 50, y: contentY), withAttributes: contentAttrs)
            }
        }
        
        return y + boxHeight
    }
    
    private func drawProjectDescription(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Project description box with icon
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 100)
        let gradient = NSGradient(colors: [lightOrange, NSColor.white])
        gradient?.draw(in: boxRect, angle: 90)
        
        primaryOrange.setStroke()
        ctx.setLineWidth(1.5)
        let path = NSBezierPath(roundedRect: boxRect, xRadius: 8, yRadius: 8)
        path.stroke()
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: primaryOrange
        ]
        ("DESCRIPTION DU PROJET 📋" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 15), withAttributes: titleAttrs)
        
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray.withAlphaComponent(0.7)
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        // Site address
        ("Adresse du chantier :" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 45), withAttributes: labelAttrs)
        let siteAddress = (document.value(forKey: "siteAddress") as? String) ?? "À définir"
        (siteAddress as NSString).draw(at: CGPoint(x: margin + 180, y: y + 45), withAttributes: valueAttrs)
        
        // Project type
        ("Nature des travaux :" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 70), withAttributes: labelAttrs)
        let projectName = (document.value(forKey: "projectName") as? String) ?? "À définir"
        (projectName as NSString).draw(at: CGPoint(x: margin + 180, y: y + 70), withAttributes: valueAttrs)
        
        return y + 100
    }
    
    private func drawItemsTable(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let tableWidth = bounds.width - margin * 2
        
        // Table header with gradient
        let headerHeight: CGFloat = 45
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: headerHeight)
        let headerGradient = NSGradient(colors: [secondaryBlue, secondaryBlue.blended(withFraction: 0.15, of: .black)!])
        headerGradient?.draw(in: headerRect, angle: 90)
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        
        // Column headers
        ("Description des travaux" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 15), withAttributes: headerAttrs)
        ("Unité" as NSString).draw(at: CGPoint(x: margin + 280, y: y + 15), withAttributes: headerAttrs)
        ("Quantité" as NSString).draw(at: CGPoint(x: margin + 340, y: y + 15), withAttributes: headerAttrs)
        ("P.U. HT" as NSString).draw(at: CGPoint(x: margin + 410, y: y + 15), withAttributes: headerAttrs)
        ("Total HT" as NSString).draw(at: CGPoint(x: margin + 490, y: y + 15), withAttributes: headerAttrs)
        
        y += headerHeight
        
        // Items with LOT numbering
        let items = (document.lineItems as? Set<LineItem> ?? []).sorted { $0.position < $1.position }
        let rowHeight: CGFloat = 50
        
        for (index, item) in items.enumerated() {
            let rowRect = CGRect(x: margin, y: y, width: tableWidth, height: rowHeight)
            
            // Alternating row colors
            if index % 2 == 0 {
                lightGray.withAlphaComponent(0.3).setFill()
            } else {
                NSColor.white.setFill()
            }
            ctx.fill(rowRect)
            
            // LOT number badge
            let lotRect = CGRect(x: margin + 10, y: y + 5, width: 50, height: 20)
            primaryOrange.withAlphaComponent(0.2).setFill()
            let lotPath = NSBezierPath(roundedRect: lotRect, xRadius: 10, yRadius: 10)
            lotPath.fill()
            
            let lotAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 10),
                .foregroundColor: primaryOrange
            ]
            let lotText = "LOT \(String(format: "%02d", index + 1))" as NSString
            let lotSize = lotText.size(withAttributes: lotAttrs)
            lotText.draw(at: CGPoint(x: lotRect.midX - lotSize.width/2, y: lotRect.midY - lotSize.height/2), withAttributes: lotAttrs)
            
            // Description
            let descAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: darkGray
            ]
            if let desc = item.itemDescription {
                (desc as NSString).draw(in: CGRect(x: margin + 15, y: y + 28, width: 250, height: 20), withAttributes: descAttrs)
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
                .foregroundColor: darkGray
            ]
            let total = formatCurrency(lineTotal, currency: document.currencyCode ?? "EUR")
            (total as NSString).draw(at: CGPoint(x: margin + 490, y: y + 20), withAttributes: totalAttrs)
            
            y += rowHeight
        }
        
        // Table border
        secondaryBlue.setStroke()
        ctx.setLineWidth(1.5)
        ctx.stroke(CGRect(x: margin, y: startY + headerHeight, width: tableWidth, height: y - startY - headerHeight))
        
        return y
    }
    
    private func drawTotals(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth: CGFloat = 300
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
        
        // Background box with shadow
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 2, height: 2), blur: 5, color: NSColor.black.withAlphaComponent(0.1).cgColor)
        let bgRect = CGRect(x: x, y: y, width: boxWidth, height: 180)
        NSColor.white.setFill()
        ctx.fill(bgRect)
        ctx.restoreGState()
        
        secondaryBlue.setStroke()
        ctx.setLineWidth(2)
        ctx.stroke(bgRect)
        
        let currency = document.currencyCode ?? "EUR"
        var currentY = y + 20
        
        // Subtotals by tax rate
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: darkGray
        ]
        
        for (rate, totals) in totalsByRate.sorted(by: { $0.key < $1.key }) {
            let rateText = rate == 0 ? "Total HT (TVA 0%) :" : "Total HT (TVA \(Int(rate))%) :"
            (rateText as NSString).draw(at: CGPoint(x: x + 20, y: currentY), withAttributes: normalAttrs)
            (formatCurrency(totals.ht, currency: currency) as NSString).draw(
                at: CGPoint(x: x + boxWidth - 110, y: currentY),
                withAttributes: normalAttrs
            )
            currentY += 25
        }
        
        // Total HT line
        currentY += 5
        ctx.setStrokeColor(lightGray.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: x + 20, y: currentY))
        ctx.addLine(to: CGPoint(x: x + boxWidth - 20, y: currentY))
        ctx.strokePath()
        currentY += 10
        
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: darkGray
        ]
        
        let totalHT = totalsByRate.values.reduce(NSDecimalNumber.zero) { $0.adding($1.ht) }
        ("TOTAL HT :" as NSString).draw(at: CGPoint(x: x + 20, y: currentY), withAttributes: boldAttrs)
        (formatCurrency(totalHT, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 110, y: currentY),
            withAttributes: boldAttrs
        )
        
        // TVA amounts
        currentY += 30
        for (rate, totals) in totalsByRate.sorted(by: { $0.key < $1.key }) {
            if rate > 0 {
                ("TVA \(Int(rate))% :" as NSString).draw(at: CGPoint(x: x + 20, y: currentY), withAttributes: normalAttrs)
                (formatCurrency(totals.tva, currency: currency) as NSString).draw(
                    at: CGPoint(x: x + boxWidth - 110, y: currentY),
                    withAttributes: normalAttrs
                )
                currentY += 20
            }
        }
        
        // Total TTC
        let totalRect = CGRect(x: x, y: y + 140, width: boxWidth, height: 40)
        let totalGradient = NSGradient(colors: [primaryOrange, primaryOrange.blended(withFraction: 0.15, of: .black)!])
        totalGradient?.draw(in: totalRect, angle: 90)
        
        let totalTVA = totalsByRate.values.reduce(NSDecimalNumber.zero) { $0.adding($1.tva) }
        let totalTTC = totalHT.adding(totalTVA)
        
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        ("TOTAL TTC :" as NSString).draw(at: CGPoint(x: x + 20, y: y + 150), withAttributes: totalAttrs)
        (formatCurrency(totalTTC, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 130, y: y + 150),
            withAttributes: totalAttrs
        )
        
        return y + 180
    }
    
    private func drawOptions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Options box
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 100)
        lightOrange.withAlphaComponent(0.3).setFill()
        ctx.fill(boxRect)
        
        primaryOrange.setStroke()
        ctx.setLineWidth(1)
        let path = NSBezierPath(roundedRect: boxRect, xRadius: 8, yRadius: 8)
        path.stroke()
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryOrange
        ]
        ("+ OPTIONS SUPPLÉMENTAIRES (non incluses dans ce devis)" as NSString).draw(
            at: CGPoint(x: margin + 15, y: y + 10),
            withAttributes: titleAttrs
        )
        
        let optionAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        let options = [
            "• Pompe à chaleur air/eau haute performance (COP > 4) : 8 500,00 € HT",
            "• Isolation thermique par l'extérieur (ITE) : 120 €/m² HT",
            "• Panneaux solaires photovoltaïques 3kWc : 6 000,00 € HT",
            "• Récupération eau de pluie avec cuve enterrée 5000L : 4 500,00 € HT"
        ]
        
        var optionY = y + 35
        for option in options {
            (option as NSString).draw(at: CGPoint(x: margin + 15, y: optionY), withAttributes: optionAttrs)
            optionY += 18
        }
        
        return y + 100
    }
    
    private func drawConditions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Payment conditions
        let boxRect = CGRect(x: margin, y: y, width: (bounds.width - margin * 2 - 20) / 2, height: 120)
        let gradient = NSGradient(colors: [NSColor(calibratedRed: 0.92, green: 0.98, blue: 0.94, alpha: 1.0), NSColor.white])
        gradient?.draw(in: boxRect, angle: 90)
        
        NSColor(calibratedRed: 0.4, green: 0.8, blue: 0.4, alpha: 1.0).setStroke()
        ctx.setLineWidth(1.5)
        ctx.stroke(boxRect)
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: NSColor(calibratedRed: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        ]
        ("CONDITIONS DE RÉALISATION" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 10), withAttributes: titleAttrs)
        
        let conditionAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        let conditions = [
            "1️⃣ Acompte à la signature : 30%",
            "2️⃣ Au début des travaux : 35%",
            "3️⃣ À mi-parcours : 25%",
            "4️⃣ À la réception : 10%"
        ]
        
        var condY = y + 35
        for condition in conditions {
            (condition as NSString).draw(at: CGPoint(x: margin + 15, y: condY), withAttributes: conditionAttrs)
            condY += 20
        }
        
        // Planning box
        let planningRect = CGRect(x: margin + boxRect.width + 20, y: y, width: boxRect.width, height: 120)
        NSColor.white.setFill()
        ctx.fill(planningRect)
        secondaryBlue.setStroke()
        ctx.setLineWidth(1.5)
        ctx.stroke(planningRect)
        
        ("PLANNING PRÉVISIONNEL" as NSString).draw(
            at: CGPoint(x: planningRect.minX + 15, y: y + 10),
            withAttributes: [
                .font: NSFont.boldSystemFont(ofSize: 14),
                .foregroundColor: secondaryBlue
            ]
        )
        
        let planning = [
            "📅 Semaines 1-2 : Préparation chantier",
            "📅 Semaines 3-6 : Gros œuvre",
            "📅 Semaines 7-10 : Second œuvre",
            "📅 Semaines 11-12 : Finitions"
        ]
        
        var planY = y + 35
        for plan in planning {
            (plan as NSString).draw(at: CGPoint(x: planningRect.minX + 15, y: planY), withAttributes: conditionAttrs)
            planY += 20
        }
        
        return y + 120
    }
    
    private func drawGuarantees(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Guarantees box
        let boxRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: 100)
        NSColor.white.setFill()
        ctx.fill(boxRect)
        
        // Gradient border
        let borderPath = NSBezierPath(roundedRect: boxRect, xRadius: 8, yRadius: 8)
        let borderGradient = NSGradient(colors: [secondaryBlue, primaryOrange])
        borderPath.lineWidth = 2
        ctx.saveGState()
        borderPath.addClip()
        borderGradient?.draw(in: boxRect, angle: 0)
        ctx.restoreGState()
        
        // Inner white fill
        let innerRect = boxRect.insetBy(dx: 2, dy: 2)
        NSColor.white.setFill()
        let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: 6, yRadius: 6)
        innerPath.fill()
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: secondaryBlue
        ]
        ("NOS GARANTIES & ENGAGEMENTS" as NSString).draw(at: CGPoint(x: margin + 20, y: y + 10), withAttributes: titleAttrs)
        
        let guaranteeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        let leftGuarantees = [
            "✅ Garantie décennale tous corps d'état",
            "✅ Respect des délais contractuels",
            "✅ Équipe qualifiée et certifiée RGE"
        ]
        
        let rightGuarantees = [
            "✅ Matériaux conformes aux normes CE",
            "✅ Nettoyage quotidien du chantier",
            "✅ Suivi personnalisé du projet"
        ]
        
        var guaranteeY = y + 35
        for guarantee in leftGuarantees {
            (guarantee as NSString).draw(at: CGPoint(x: margin + 20, y: guaranteeY), withAttributes: guaranteeAttrs)
            guaranteeY += 20
        }
        
        guaranteeY = y + 35
        for guarantee in rightGuarantees {
            (guarantee as NSString).draw(at: CGPoint(x: margin + 300, y: guaranteeY), withAttributes: guaranteeAttrs)
            guaranteeY += 20
        }
        
        return y + 100
    }
    
    private func drawSignatures(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let boxWidth = (bounds.width - margin * 2 - 40) / 2
        
        // Signature areas
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: darkGray
        ]
        
        ("LE CLIENT" as NSString).draw(at: CGPoint(x: margin + boxWidth/2 - 30, y: y), withAttributes: titleAttrs)
        ("L'ENTREPRISE" as NSString).draw(at: CGPoint(x: bounds.width - margin - boxWidth/2 - 45, y: y), withAttributes: titleAttrs)
        
        y += 25
        
        // Signature lines
        ctx.setStrokeColor(darkGray.cgColor)
        ctx.setLineWidth(1)
        ctx.setLineDash(phase: 0, lengths: [5, 3])
        
        ctx.move(to: CGPoint(x: margin, y: y + 40))
        ctx.addLine(to: CGPoint(x: margin + boxWidth, y: y + 40))
        ctx.strokePath()
        
        ctx.move(to: CGPoint(x: bounds.width - margin - boxWidth, y: y + 40))
        ctx.addLine(to: CGPoint(x: bounds.width - margin, y: y + 40))
        ctx.strokePath()
        
        ctx.setLineDash(phase: 0, lengths: [])
        
        let noteAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: darkGray.withAlphaComponent(0.7)
        ]
        
        ("Précédé de « Bon pour accord »" as NSString).draw(at: CGPoint(x: margin, y: y + 50), withAttributes: noteAttrs)
        ("Date et signature" as NSString).draw(at: CGPoint(x: margin, y: y + 65), withAttributes: noteAttrs)
        
        ("Cachet et signature" as NSString).draw(at: CGPoint(x: bounds.width - margin - boxWidth, y: y + 50), withAttributes: noteAttrs)
        ("de l'entreprise" as NSString).draw(at: CGPoint(x: bounds.width - margin - boxWidth, y: y + 65), withAttributes: noteAttrs)
        
        return y + 80
    }
    
    private func drawFooter(ctx: CGContext) {
        let footerY = bounds.height - 50
        
        // Footer background
        let footerGradient = NSGradient(colors: [lightGray, NSColor.white])
        footerGradient?.draw(in: CGRect(x: 0, y: footerY, width: bounds.width, height: 50), angle: 90)
        
        // Validity reminder
        let validityRect = CGRect(x: margin, y: footerY + 5, width: 200, height: 25)
        lightOrange.setFill()
        let validityPath = NSBezierPath(roundedRect: validityRect, xRadius: 12, yRadius: 12)
        validityPath.fill()
        
        let validityDays = (document.value(forKey: "validityDays") as? Int16) ?? 30
        let validityAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: primaryOrange
        ]
        ("⏰ Validité du devis : \(validityDays) jours" as NSString).draw(
            at: CGPoint(x: margin + 20, y: footerY + 10),
            withAttributes: validityAttrs
        )
        
        // Company footer
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: darkGray
        ]
        
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? ""
        let siret = UserDefaults.standard.string(forKey: "companySIRET") ?? ""
        let insurance = UserDefaults.standard.string(forKey: "insuranceNumber") ?? ""
        
        var footerText = companyName
        if !siret.isEmpty { footerText += " • SIRET: \(siret)" }
        if !insurance.isEmpty { footerText += " • Assurance décennale: \(insurance)" }
        
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        var attrs = footerAttrs
        attrs[.paragraphStyle] = para
        
        (footerText as NSString).draw(
            in: CGRect(x: margin, y: footerY + 35, width: bounds.width - margin * 2, height: 15),
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
        
        // Apply discount
        let discountRate = NSDecimalNumber(value: max(0, min(100, item.discount)))
        let discountAmount = lineTotal.multiplying(by: discountRate).dividing(by: 100)
        return lineTotal.subtracting(discountAmount)
    }
}

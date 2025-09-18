import Foundation
import AppKit
import PDFKit
import SwiftUI

// MARK: - Belgian Modern BTP Quote Template (Compatible with new BTP infrastructure)
final class BEModernBTPQuoteTemplate {
    private let pageSize = CGSize(width: 595, height: 842) // A4
    private let margin: CGFloat = 40
    
    // Belgian BTP quote color scheme (warmer colors for quotes)
    private let primaryBlue = NSColor(calibratedRed: 0.0, green: 0.36, blue: 0.69, alpha: 1.0) // Belgian blue
    private let accentGold = NSColor(calibratedRed: 0.96, green: 0.73, blue: 0.15, alpha: 1.0) // Belgian gold
    private let lightGray = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
    private let darkGray = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    private let trustGreen = NSColor(calibratedRed: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
    
    func generate(document: Document) -> Data? {
        let view = BEModernBTPQuoteView(
            frame: CGRect(origin: .zero, size: pageSize),
            document: document,
            margin: margin,
            primaryBlue: primaryBlue,
            accentGold: accentGold,
            lightGray: lightGray,
            darkGray: darkGray,
            trustGreen: trustGreen
        )
        return view.dataWithPDF(inside: view.bounds)
    }
}

private final class BEModernBTPQuoteView: NSView {
    private let document: Document
    private let margin: CGFloat
    private let primaryBlue: NSColor
    private let accentGold: NSColor
    private let lightGray: NSColor
    private let darkGray: NSColor
    private let trustGreen: NSColor
    
    init(frame: CGRect, document: Document, margin: CGFloat, primaryBlue: NSColor, accentGold: NSColor, lightGray: NSColor, darkGray: NSColor, trustGreen: NSColor) {
        self.document = document
        self.margin = margin
        self.primaryBlue = primaryBlue
        self.accentGold = accentGold
        self.lightGray = lightGray
        self.darkGray = darkGray
        self.trustGreen = trustGreen
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
        currentY = drawBelgianQuoteHeader(ctx: ctx, startY: currentY)
        currentY = drawCompanyAndClientBelgian(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPProjectDescription(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPItemsTable(ctx: ctx, startY: currentY + 20)
        currentY = drawBelgianTotals(ctx: ctx, startY: currentY + 20)
        currentY = drawBelgianQuoteConditions(ctx: ctx, startY: currentY + 20)
        currentY = drawBelgianSignatures(ctx: ctx, startY: currentY + 20)
        drawBelgianFooter(ctx: ctx)
    }
    
    private func drawBelgianQuoteHeader(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Header background with Belgian quote colors
        let headerRect = CGRect(x: 0, y: y, width: bounds.width, height: 120)
        let gradient = NSGradient(colors: [primaryBlue, primaryBlue.blended(withFraction: 0.2, of: .black)!])
        gradient?.draw(in: headerRect, angle: 45)
        
        // Company info section
        let logoRect = CGRect(x: margin, y: y + 20, width: 200, height: 80)
        accentGold.withAlphaComponent(0.2).setFill()
        ctx.fill(logoRect)
        
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? "Entreprise BTP"
        let companyAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.white
        ]
        let nameSize = (companyName as NSString).size(withAttributes: companyAttrs)
        (companyName as NSString).draw(
            at: CGPoint(x: logoRect.midX - nameSize.width/2, y: logoRect.midY - nameSize.height/2),
            withAttributes: companyAttrs
        )
        
        // OFFERTE title (Belgian)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 48),
            .foregroundColor: accentGold
        ]
        let title = "OFFERTE" as NSString
        let titleSize = title.size(withAttributes: titleAttrs)
        title.draw(at: CGPoint(x: bounds.width - margin - titleSize.width, y: y + 30), withAttributes: titleAttrs)
        
        // Document details with Belgian formatting
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.white.withAlphaComponent(0.9)
        ]
        
        let docNumber = "Nr. \(document.number ?? "---")" as NSString
        docNumber.draw(at: CGPoint(x: bounds.width - margin - 200, y: y + 85), withAttributes: infoAttrs)
        
        // Country and language indicators
        let country = document.btpCountry
        let language = document.btpLanguage
        let countryInfo = "\(country.flag) \(country.name) • \(language.name)" as NSString
        countryInfo.draw(at: CGPoint(x: margin, y: y + 85), withAttributes: infoAttrs)
        
        return y + 120
    }
    
    private func drawCompanyAndClientBelgian(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth = (bounds.width - margin * 2 - 30) / 2
        let boxHeight: CGFloat = 140
        
        // Company box
        let companyRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        drawBelgianQuoteBox(ctx: ctx, rect: companyRect, title: "AANNEMER", color: primaryBlue)
        
        var contentY = y + 40
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: darkGray
        ]
        
        // Company details
        if let companyName = UserDefaults.standard.string(forKey: "companyName"), !companyName.isEmpty {
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 12),
                .foregroundColor: darkGray
            ]
            (companyName as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: boldAttrs)
            contentY += 20
        }
        
        if let address = UserDefaults.standard.string(forKey: "companyAddress"), !address.isEmpty {
            (address as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        if let taxId = UserDefaults.standard.string(forKey: "companyTaxId"), !taxId.isEmpty {
            ("BTW-nr : \(taxId)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        if let ondernemingsnummer = UserDefaults.standard.string(forKey: "companySIRET"), !ondernemingsnummer.isEmpty {
            ("Ondernemingsnummer : \(ondernemingsnummer)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
        }
        
        // Client box
        let clientRect = CGRect(x: margin + boxWidth + 30, y: y, width: boxWidth, height: boxHeight)
        drawBelgianQuoteBox(ctx: ctx, rect: clientRect, title: "OPDRACHTGEVER", color: accentGold)
        
        // Client details with BTP extensions
        if let client = document.safeClient {
            contentY = y + 40
            
            if let name = client.name, !name.isEmpty {
                let boldAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 12),
                    .foregroundColor: darkGray
                ]
                (name as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: boldAttrs)
                contentY += 20
            }
            
            // Use BTP client extensions
            let address = client.fullAddress
            if !address.isEmpty {
                let lines = address.components(separatedBy: "\n")
                for line in lines {
                    if !line.isEmpty {
                        (line as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
                        contentY += 16
                    }
                }
            }
            
            // Client type indicator
            let clientTypeText = "👤 \(client.clientType.localized)" as NSString
            clientTypeText.draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
        }
        
        return y + boxHeight
    }
    
    private func drawBTPProjectDescription(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxHeight: CGFloat = 140
        
        let projectRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: boxHeight)
        drawBelgianQuoteBox(ctx: ctx, rect: projectRect, title: "🏗️ PROJECTBESCHRIJVING", color: trustGreen)
        
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray.withAlphaComponent(0.7)
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        var infoY = y + 40
        let leftCol = margin + 15
        let rightCol = margin + (bounds.width - margin * 2) / 2 + 15
        
        // Left column
        ("Projectlocatie :" as NSString).draw(at: CGPoint(x: leftCol, y: infoY), withAttributes: labelAttrs)
        let siteAddress = document.siteAddress ?? "Niet gespecificeerd"
        (siteAddress as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Type werken :" as NSString).draw(at: CGPoint(x: leftCol, y: infoY), withAttributes: labelAttrs)
        let workType = document.typeTravaux?.localized ?? "Niet gespecificeerd"
        (workType as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Geldigheid offerte :" as NSString).draw(at: CGPoint(x: leftCol, y: infoY), withAttributes: labelAttrs)
        let validity = "30 dagen vanaf datering"
        (validity as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        // Right column
        infoY = y + 40
        ("Werkzone :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let workZone = document.zoneTravaux?.localized ?? "Niet gespecificeerd"
        (workZone as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Geschatte duur :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let duration = calculateProjectDuration()
        (duration as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Land/Regelgeving :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let countryInfo = "\(document.btpCountry.flag) \(document.btpCountry.name)"
        (countryInfo as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        return y + boxHeight
    }
    
    private func drawBTPItemsTable(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let tableWidth = bounds.width - margin * 2
        
        // Table header with Belgian quote styling
        let headerHeight: CGFloat = 45
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: headerHeight)
        
        let gradient = NSGradient(colors: [primaryBlue, primaryBlue.blended(withFraction: 0.1, of: .black)!])
        gradient?.draw(in: headerRect, angle: 0)
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.white
        ]
        
        // Belgian BTP quote column headers
        var xPos = margin + 10
        ("Corps d'État" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 100
        ("Omschrijving werken" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 200
        ("Eenheid" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 60
        ("Aantal" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 60
        ("E.P. excl." as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 80
        ("Totaal excl." as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        
        y += headerHeight
        
        // Items grouped by Corps d'État
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else {
            return y
        }
        
        let sortedItems = lineItems.sorted { $0.position < $1.position }
        let rowHeight: CGFloat = 45
        
        for (index, item) in sortedItems.enumerated() {
            let rowRect = CGRect(x: margin, y: y, width: tableWidth, height: rowHeight)
            
            // Alternating row colors
            if index % 2 == 0 {
                lightGray.withAlphaComponent(0.3).setFill()
                ctx.fill(rowRect)
            }
            
            let itemAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10),
                .foregroundColor: darkGray
            ]
            
            xPos = margin + 10
            
            // Corps d'État with color indicator
            if let corpsEtat = item.corpsEtat {
                let colorIndicator = "●"
                let colorAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 14),
                    .foregroundColor: corpsEtatToNSColor(corpsEtat)
                ]
                (colorIndicator as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: colorAttrs)
                
                let corpsText = corpsEtat.rawValue.prefix(8) + (corpsEtat.rawValue.count > 8 ? "..." : "")
                (String(corpsText) as NSString).draw(at: CGPoint(x: xPos + 15, y: y + 18), withAttributes: itemAttrs)
            } else {
                ("Algemeen" as NSString).draw(at: CGPoint(x: xPos, y: y + 18), withAttributes: itemAttrs)
            }
            xPos += 100
            
            // Description (longer for quotes)
            if let desc = item.itemDescription {
                let lines = desc.components(separatedBy: " ")
                var currentLine = ""
                var lineY = y + 15
                
                for word in lines {
                    let testLine = currentLine.isEmpty ? word : "\(currentLine) \(word)"
                    let testSize = (testLine as NSString).size(withAttributes: itemAttrs)
                    
                    if testSize.width > 180 {
                        if !currentLine.isEmpty {
                            (currentLine as NSString).draw(at: CGPoint(x: xPos, y: lineY), withAttributes: itemAttrs)
                            lineY += 12
                            currentLine = word
                        }
                    } else {
                        currentLine = testLine
                    }
                }
                
                if !currentLine.isEmpty {
                    (currentLine as NSString).draw(at: CGPoint(x: xPos, y: lineY), withAttributes: itemAttrs)
                }
            }
            xPos += 200
            
            // Unit
            let unit = item.uniteBTP?.rawValue ?? item.unit ?? "st"
            (unit as NSString).draw(at: CGPoint(x: xPos, y: y + 18), withAttributes: itemAttrs)
            xPos += 60
            
            // Quantity
            let qty = formatNumber(item.quantity ?? 0)
            (qty as NSString).draw(at: CGPoint(x: xPos, y: y + 18), withAttributes: itemAttrs)
            xPos += 60
            
            // Unit price
            let unitPrice = formatCurrency(item.unitPrice ?? 0, currency: document.currencyCode ?? "EUR")
            (unitPrice as NSString).draw(at: CGPoint(x: xPos, y: y + 18), withAttributes: itemAttrs)
            xPos += 80
            
            // Line total
            let lineTotal = calculateLineTotal(item)
            let total = formatCurrency(lineTotal, currency: document.currencyCode ?? "EUR")
            (total as NSString).draw(at: CGPoint(x: xPos, y: y + 18), withAttributes: itemAttrs)
            
            y += rowHeight
        }
        
        // Table border
        primaryBlue.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: margin, y: startY + headerHeight, width: tableWidth, height: y - startY - headerHeight))
        
        return y
    }
    
    private func drawBelgianTotals(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth: CGFloat = 300
        let boxHeight: CGFloat = 140
        let x = bounds.width - margin - boxWidth
        
        let totalsRect = CGRect(x: x, y: y, width: boxWidth, height: boxHeight)
        drawBelgianQuoteBox(ctx: ctx, rect: totalsRect, title: "💰 TOTAALBEDRAG", color: primaryBlue)
        
        // Calculate totals
        let calculations = DocumentCalculations(document: document)
        let currency = document.currencyCode ?? "EUR"
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: darkGray
        ]
        
        var totalY = y + 40
        
        // Subtotal excl. BTW
        ("Subtotaal excl. BTW :" as NSString).draw(at: CGPoint(x: x + 20, y: totalY), withAttributes: normalAttrs)
        (formatCurrency(calculations.subtotal, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 120, y: totalY),
            withAttributes: normalAttrs
        )
        totalY += 25
        
        // Belgian VAT (simplified for quotes - usually shown as one rate)
        ("BTW 21% :" as NSString).draw(at: CGPoint(x: x + 20, y: totalY), withAttributes: normalAttrs)
        (formatCurrency(calculations.totalVAT, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 120, y: totalY),
            withAttributes: normalAttrs
        )
        totalY += 25
        
        // Separator line
        ctx.setStrokeColor(darkGray.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: x + 20, y: totalY + 5))
        ctx.addLine(to: CGPoint(x: x + boxWidth - 20, y: totalY + 5))
        ctx.strokePath()
        totalY += 15
        
        // Total incl. BTW
        let ttcRect = CGRect(x: x + 10, y: totalY, width: boxWidth - 20, height: 35)
        trustGreen.setFill()
        ctx.fill(ttcRect)
        
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        ("TOTAAL INCL. BTW :" as NSString).draw(at: CGPoint(x: x + 20, y: totalY + 8), withAttributes: totalAttrs)
        (formatCurrency(calculations.totalWithVAT, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 140, y: totalY + 8),
            withAttributes: totalAttrs
        )
        
        return y + boxHeight
    }
    
    private func drawBelgianQuoteConditions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxHeight: CGFloat = 120
        
        let conditionsRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: boxHeight)
        drawBelgianQuoteBox(ctx: ctx, rect: conditionsRect, title: "📋 VOORWAARDEN & GARANTIES", color: accentGold)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: darkGray
        ]
        
        var contentY = y + 40
        let leftCol = margin + 15
        let rightCol = margin + (bounds.width - margin * 2) / 2 + 15
        
        // Left column - Conditions
        let leftConditions = [
            "✓ Geldigheid: 30 dagen",
            "✓ Betaling: 30% voorschot, saldo bij oplevering",
            "✓ Prijzen excl. BTW en onvoorziene werken",
            "✓ Wijzigingen schriftelijk bevestigd"
        ]
        
        for condition in leftConditions {
            (condition as NSString).draw(at: CGPoint(x: leftCol, y: contentY), withAttributes: contentAttrs)
            contentY += 15
        }
        
        // Right column - Guarantees
        contentY = y + 40
        let rightConditions = [
            "🛡️ Garantie voltooiing: 1 jaar",
            "🏛️ Tienjarige garantie conform wet",
            "📋 Conform DTU en regels der kunst",
            "🏢 Verzekering: Alle risico's gedekt"
        ]
        
        for condition in rightConditions {
            (condition as NSString).draw(at: CGPoint(x: rightCol, y: contentY), withAttributes: contentAttrs)
            contentY += 15
        }
        
        return y + boxHeight
    }
    
    private func drawBelgianSignatures(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxHeight: CGFloat = 100
        let boxWidth = (bounds.width - margin * 2 - 30) / 2
        
        // Client signature box
        let clientSigRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        drawBelgianQuoteBox(ctx: ctx, rect: clientSigRect, title: "✍️ HANDTEKENING OPDRACHTGEVER", color: primaryBlue)
        
        let signAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: darkGray.withAlphaComponent(0.7)
        ]
        
        ("Gelezen en goedgekeurd," as NSString).draw(at: CGPoint(x: margin + 15, y: y + 40), withAttributes: signAttrs)
        ("\"Goed voor akkoord\"" as NSString).draw(at: CGPoint(x: margin + 15, y: y + 55), withAttributes: signAttrs)
        
        let dateStr = "Datum: _______________"
        (dateStr as NSString).draw(at: CGPoint(x: margin + 15, y: y + 75), withAttributes: signAttrs)
        
        // Company signature box
        let companySigRect = CGRect(x: margin + boxWidth + 30, y: y, width: boxWidth, height: boxHeight)
        drawBelgianQuoteBox(ctx: ctx, rect: companySigRect, title: "✍️ HANDTEKENING AANNEMER", color: accentGold)
        
        let companyName = UserDefaults.standard.string(forKey: "companyName") ?? "Entreprise BTP"
        (companyName as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: y + 40), withAttributes: signAttrs)
        
        ("Functie: Uitvoerder" as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: y + 55), withAttributes: signAttrs)
        (dateStr as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: y + 75), withAttributes: signAttrs)
        
        return y + boxHeight
    }
    
    private func drawBelgianFooter(ctx: CGContext) {
        let footerY = bounds.height - 50
        let footerHeight: CGFloat = 50
        
        // Footer background
        let footerRect = CGRect(x: 0, y: footerY, width: bounds.width, height: footerHeight)
        lightGray.setFill()
        ctx.fill(footerRect)
        
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: darkGray
        ]
        
        let companyInfo = buildCompanyFooterInfo()
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        var attrs = footerAttrs
        attrs[.paragraphStyle] = para
        
        (companyInfo as NSString).draw(
            in: CGRect(x: margin, y: footerY + 15, width: bounds.width - margin * 2, height: 20),
            withAttributes: attrs
        )
        
        // Belgian quote indicator
        let btpIndicator = "🇧🇪 Offerte Template BTP België • Conform Belgische regelgeving"
        (btpIndicator as NSString).draw(
            in: CGRect(x: margin, y: footerY + 30, width: bounds.width - margin * 2, height: 15),
            withAttributes: attrs
        )
    }
    
    // MARK: - Helper Functions
    
    private func drawBelgianQuoteBox(ctx: CGContext, rect: CGRect, title: String, color: NSColor) {
        // Box shadow
        let shadowRect = CGRect(x: rect.origin.x + 2, y: rect.origin.y + 2, width: rect.width, height: rect.height)
        NSColor.black.withAlphaComponent(0.1).setFill()
        ctx.fill(shadowRect)
        
        // Main box
        NSColor.white.setFill()
        ctx.fill(rect)
        
        // Title bar
        let titleRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: 30)
        color.setFill()
        ctx.fill(titleRect)
        
        // Title text
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        (title as NSString).draw(at: CGPoint(x: rect.origin.x + 15, y: rect.origin.y + 8), withAttributes: titleAttrs)
        
        // Border
        color.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(rect)
    }
    
    private func calculateProjectDuration() -> String {
        // Estimate based on number of line items and complexity
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else {
            return "Te bepalen"
        }
        
        let itemCount = lineItems.count
        let estimatedDays = max(5, itemCount * 2)
        let weeks = estimatedDays / 7
        
        if weeks > 0 {
            return "\(weeks) weken"
        } else {
            return "\(estimatedDays) dagen"
        }
    }
    
    private func corpsEtatToNSColor(_ corpsEtat: CorpsEtat) -> NSColor {
        switch corpsEtat.category {
        case .grosOeuvre: return NSColor.brown
        case .secondOeuvre: return NSColor.blue
        case .finitions: return NSColor.purple
        case .techniques: return NSColor.red
        case .exterieur: return NSColor.green
        default: return NSColor.gray
        }
    }
    
    private func buildCompanyFooterInfo() -> String {
        var components: [String] = []
        
        if let name = UserDefaults.standard.string(forKey: "companyName"), !name.isEmpty {
            components.append(name)
        }
        
        if let address = UserDefaults.standard.string(forKey: "companyAddress"), !address.isEmpty {
            components.append(address)
        }
        
        if let ondernemingsnummer = UserDefaults.standard.string(forKey: "companySIRET"), !ondernemingsnummer.isEmpty {
            components.append("Ondernemingsnummer: \(ondernemingsnummer)")
        }
        
        if let taxId = UserDefaults.standard.string(forKey: "companyTaxId"), !taxId.isEmpty {
            components.append("BTW: \(taxId)")
        }
        
        return components.joined(separator: " • ")
    }
    
    private func formatCurrency(_ value: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: document.btpLanguage.localeIdentifier)
        return formatter.string(from: NSNumber(value: value)) ?? "0,00 €"
    }
    
    private func formatCurrency(_ value: NSDecimalNumber, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: document.btpLanguage.localeIdentifier)
        return formatter.string(from: value) ?? "0,00 €"
    }
    
    private func formatNumber(_ value: NSDecimalNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: document.btpLanguage.localeIdentifier)
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value) ?? "0"
    }
    
    private func calculateLineTotal(_ item: LineItem) -> NSDecimalNumber {
        let qty = item.quantity ?? 0
        let unitPrice = item.unitPrice ?? 0
        let lineTotal = qty.multiplying(by: unitPrice)
        
        let discountRate = NSDecimalNumber(value: max(0, min(100, item.discount)))
        let discountAmount = lineTotal.multiplying(by: discountRate).dividing(by: 100)
        let netAmount = lineTotal.subtracting(discountAmount)
        
        return netAmount
    }
}

import Foundation
import AppKit
import PDFKit
import SwiftUI

// MARK: - Modern BTP Quote Template (Compatible with new BTP infrastructure)
final class ModernBTPQuoteTemplate {
    private let pageSize = CGSize(width: 595, height: 842) // A4
    private let margin: CGFloat = 40
    
    // Modern BTP color scheme for quotes
    private let primaryOrange = NSColor(calibratedRed: 1.0, green: 0.396, blue: 0.0, alpha: 1.0) // #FF6500
    private let secondaryBlue = NSColor(calibratedRed: 0.051, green: 0.278, blue: 0.631, alpha: 1.0) // #0D47A1
    private let lightGray = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
    private let darkGray = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    private let lightOrange = NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
    private let successGreen = NSColor(calibratedRed: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
    
    func generate(document: Document) -> Data? {
        let view = ModernBTPQuoteView(
            frame: CGRect(origin: .zero, size: pageSize),
            document: document,
            margin: margin,
            primaryOrange: primaryOrange,
            secondaryBlue: secondaryBlue,
            lightGray: lightGray,
            darkGray: darkGray,
            lightOrange: lightOrange,
            successGreen: successGreen
        )
        return view.dataWithPDF(inside: view.bounds)
    }
}

private final class ModernBTPQuoteView: NSView {
    private let document: Document
    private let margin: CGFloat
    private let primaryOrange: NSColor
    private let secondaryBlue: NSColor
    private let lightGray: NSColor
    private let darkGray: NSColor
    private let lightOrange: NSColor
    private let successGreen: NSColor
    
    init(frame: CGRect, document: Document, margin: CGFloat, primaryOrange: NSColor, secondaryBlue: NSColor, lightGray: NSColor, darkGray: NSColor, lightOrange: NSColor, successGreen: NSColor) {
        self.document = document
        self.margin = margin
        self.primaryOrange = primaryOrange
        self.secondaryBlue = secondaryBlue
        self.lightGray = lightGray
        self.darkGray = darkGray
        self.lightOrange = lightOrange
        self.successGreen = successGreen
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
        currentY = drawModernHeader(ctx: ctx, startY: currentY)
        currentY = drawCompanyAndClientModern(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPProjectDescription(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPItemsTable(ctx: ctx, startY: currentY + 20)
        currentY = drawModernTotals(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPValidityAndConditions(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPGuarantees(ctx: ctx, startY: currentY + 20)
        currentY = drawSignatureSection(ctx: ctx, startY: currentY + 20)
        drawModernFooter(ctx: ctx)
    }
    
    private func drawModernHeader(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Header background with gradient (orange theme for quotes)
        let headerRect = CGRect(x: 0, y: y, width: bounds.width, height: 120)
        let gradient = NSGradient(colors: [primaryOrange, primaryOrange.blended(withFraction: 0.2, of: .black)!])
        gradient?.draw(in: headerRect, angle: 45)
        
        // Company info section
        let logoRect = CGRect(x: margin, y: y + 20, width: 200, height: 80)
        NSColor.white.withAlphaComponent(0.1).setFill()
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
        
        // DEVIS title with modern styling
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 52),
            .foregroundColor: NSColor.white
        ]
        let title = "DEVIS" as NSString
        let titleSize = title.size(withAttributes: titleAttrs)
        title.draw(at: CGPoint(x: bounds.width - margin - titleSize.width, y: y + 25), withAttributes: titleAttrs)
        
        // Document details
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.white.withAlphaComponent(0.9)
        ]
        
        let docNumber = "N° \(document.number ?? "---")" as NSString
        docNumber.draw(at: CGPoint(x: bounds.width - margin - 200, y: y + 85), withAttributes: infoAttrs)
        
        // Country and language indicators
        let country = document.btpCountry
        let language = document.btpLanguage
        let countryInfo = "\(country.flag) \(country.name) • \(language.name)" as NSString
        countryInfo.draw(at: CGPoint(x: margin, y: y + 85), withAttributes: infoAttrs)
        
        return y + 120
    }
    
    private func drawCompanyAndClientModern(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth = (bounds.width - margin * 2 - 30) / 2
        let boxHeight: CGFloat = 140
        
        // Company box
        let companyRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        drawModernBox(ctx: ctx, rect: companyRect, title: "ÉMETTEUR", color: secondaryBlue)
        
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
            ("TVA Intra : \(taxId)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 18
        }
        
        // Certifications (using BTP models)
        let certifications = document.certifications
        if !certifications.isEmpty {
            let certText = certifications.map { $0.rawValue }.joined(separator: ", ")
            ("🏆 \(certText)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
        }
        
        // Client box
        let clientRect = CGRect(x: margin + boxWidth + 30, y: y, width: boxWidth, height: boxHeight)
        drawModernBox(ctx: ctx, rect: clientRect, title: "CLIENT", color: primaryOrange)
        
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
            if !client.fullAddress.isEmpty {
                let lines = client.fullAddress.components(separatedBy: "\n")
                for line in lines {
                    if !line.isEmpty {
                        (line as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
                        contentY += 16
                    }
                }
            }
            
            // Client type and company registration
            let clientTypeText = "👤 \(client.clientType.localized)"
            if let registration = client.companyRegistration, !registration.isEmpty {
                let fullText = "\(clientTypeText) • \(registration)"
                (fullText as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
            } else {
                (clientTypeText as NSString).draw(at: CGPoint(x: margin + boxWidth + 45, y: contentY), withAttributes: contentAttrs)
            }
        }
        
        return y + boxHeight
    }
    
    private func drawBTPProjectDescription(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxHeight: CGFloat = 140
        
        let projectRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: boxHeight)
        drawModernBox(ctx: ctx, rect: projectRect, title: "🏗️ DESCRIPTION DU PROJET BTP", color: successGreen)
        
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
        ("Adresse du chantier :" as NSString).draw(at: CGPoint(x: leftCol, y: infoY), withAttributes: labelAttrs)
        let siteAddress = document.siteAddress ?? "À définir"
        (siteAddress as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Type de travaux :" as NSString).draw(at: CGPoint(x: leftCol, y: infoY), withAttributes: labelAttrs)
        let workType = document.typeTravaux?.localized ?? "À définir"
        let workTypeWithIcon = "\(document.typeTravaux?.icon ?? "🏗️") \(workType)"
        (workTypeWithIcon as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Durée des travaux :" as NSString).draw(at: CGPoint(x: leftCol, y: infoY), withAttributes: labelAttrs)
        let duration = calculateProjectDuration()
        (duration as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        // Right column
        infoY = y + 40
        ("Zone d'intervention :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let workZone = document.zoneTravaux?.localized ?? "À définir"
        (workZone as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Réglementation :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let countryInfo = "\(document.btpCountry.flag) \(document.btpCountry.name)"
        (countryInfo as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Validité du devis :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let validityText = "\(document.validityDays) jours"
        (validityText as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        return y + boxHeight
    }
    
    private func drawBTPItemsTable(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let tableWidth = bounds.width - margin * 2
        
        // Table header
        let headerHeight: CGFloat = 45
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: headerHeight)
        
        let gradient = NSGradient(colors: [primaryOrange, primaryOrange.blended(withFraction: 0.1, of: .black)!])
        gradient?.draw(in: headerRect, angle: 0)
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.white
        ]
        
        // BTP-specific column headers
        var xPos = margin + 10
        ("Corps d'État" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 100
        ("Description des travaux" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 180
        ("Unité" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 60
        ("Qté" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 60
        ("Prix unit." as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 80
        ("TVA" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 50
        ("Total HT" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        
        y += headerHeight
        
        // Items grouped by Corps d'État
        let groupedItems = getItemsGroupedByCorpsEtat()
        let rowHeight: CGFloat = 40
        
        for (corpsEtat, items) in groupedItems {
            // Corps d'État header
            if groupedItems.count > 1 {
                let groupHeaderRect = CGRect(x: margin, y: y, width: tableWidth, height: 25)
                lightOrange.setFill()
                ctx.fill(groupHeaderRect)
                
                let groupAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: primaryOrange
                ]
                
                let groupTitle = corpsEtat?.localized ?? "Prestations générales"
                (groupTitle as NSString).draw(at: CGPoint(x: margin + 10, y: y + 6), withAttributes: groupAttrs)
                y += 25
            }
            
            // Items in this corps d'état
            for (index, item) in items.enumerated() {
                let rowRect = CGRect(x: margin, y: y, width: tableWidth, height: rowHeight)
                
                if index % 2 == 0 {
                    lightGray.withAlphaComponent(0.3).setFill()
                    ctx.fill(rowRect)
                }
                
                let itemAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 10),
                    .foregroundColor: darkGray
                ]
                
                xPos = margin + 10
                
                // Corps d'État indicator
                if let itemCorpsEtat = item.corpsEtat {
                    let colorIndicator = "●"
                    let colorAttrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: 14),
                        .foregroundColor: corpsEtatToNSColor(itemCorpsEtat)
                    ]
                    (colorIndicator as NSString).draw(at: CGPoint(x: xPos, y: y + 12), withAttributes: colorAttrs)
                    
                    let corpsText = itemCorpsEtat.rawValue.prefix(8) + (itemCorpsEtat.rawValue.count > 8 ? "..." : "")
                    (String(corpsText) as NSString).draw(at: CGPoint(x: xPos + 15, y: y + 15), withAttributes: itemAttrs)
                } else {
                    ("Général" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
                }
                xPos += 100
                
                // Description with specifications
                if item.itemDescription != nil {
                    let fullDesc = buildItemDescription(item)
                    let truncated = fullDesc.prefix(25) + (fullDesc.count > 25 ? "..." : "")
                    (String(truncated) as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
                }
                xPos += 180
                
                // Unit (BTP units)
                let unit = item.uniteBTP?.localized ?? item.unit ?? "u"
                (unit as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
                xPos += 60
                
                // Quantity
                let qty = formatNumber(item.quantity ?? 0)
                (qty as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
                xPos += 60
                
                // Unit price
                let unitPrice = formatCurrency(item.unitPrice ?? 0, currency: document.currencyCode ?? "EUR")
                (unitPrice as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
                xPos += 80
                
                // VAT rate with smart detection
                let vatRate = getSmartVATRate(for: item)
                let vatText = String(format: "%.1f%%", vatRate)
                (vatText as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
                xPos += 50
                
                // Line total
                let lineTotal = calculateLineTotal(item)
                let total = formatCurrency(lineTotal, currency: document.currencyCode ?? "EUR")
                (total as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
                
                y += rowHeight
            }
        }
        
        // Table border
        primaryOrange.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: margin, y: startY + headerHeight, width: tableWidth, height: y - startY - headerHeight))
        
        return y
    }
    
    private func drawModernTotals(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth: CGFloat = 300
        let boxHeight: CGFloat = 180
        let x = bounds.width - margin - boxWidth
        
        let totalsRect = CGRect(x: x, y: y, width: boxWidth, height: boxHeight)
        drawModernBox(ctx: ctx, rect: totalsRect, title: "💰 RÉCAPITULATIF", color: primaryOrange)
        
        let calculations = DocumentCalculations(document: document)
        let currency = document.currencyCode ?? "EUR"
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: darkGray
        ]
        
        var totalY = y + 40
        
        // Subtotal
        ("Total HT :" as NSString).draw(at: CGPoint(x: x + 20, y: totalY), withAttributes: normalAttrs)
        (formatCurrency(calculations.subtotal, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 120, y: totalY),
            withAttributes: normalAttrs
        )
        totalY += 25
        
        // VAT breakdown
        let vatBreakdown = getVATBreakdown()
        for breakdown in vatBreakdown {
            let vatLabel = "TVA \(String(format: "%.1f", breakdown.rate))% :"
            (vatLabel as NSString).draw(at: CGPoint(x: x + 20, y: totalY), withAttributes: normalAttrs)
            (formatCurrency(breakdown.amount, currency: currency) as NSString).draw(
                at: CGPoint(x: x + boxWidth - 120, y: totalY),
                withAttributes: normalAttrs
            )
            totalY += 20
        }
        
        // Separator
        ctx.setStrokeColor(darkGray.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: x + 20, y: totalY + 5))
        ctx.addLine(to: CGPoint(x: x + boxWidth - 20, y: totalY + 5))
        ctx.strokePath()
        totalY += 15
        
        // Total TTC
        let ttcRect = CGRect(x: x + 10, y: totalY, width: boxWidth - 20, height: 35)
        successGreen.setFill()
        ctx.fill(ttcRect)
        
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        ("TOTAL TTC :" as NSString).draw(at: CGPoint(x: x + 20, y: totalY + 8), withAttributes: totalAttrs)
        (formatCurrency(calculations.totalWithVAT, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 140, y: totalY + 8),
            withAttributes: totalAttrs
        )
        totalY += 40
        
        // Advance payment if any
        if calculations.advance > 0 {
            ("Acompte demandé :" as NSString).draw(at: CGPoint(x: x + 20, y: totalY), withAttributes: normalAttrs)
            (formatCurrency(calculations.advance, currency: currency) as NSString).draw(
                at: CGPoint(x: x + boxWidth - 120, y: totalY),
                withAttributes: normalAttrs
            )
        }
        
        return y + boxHeight
    }
    
    private func drawBTPValidityAndConditions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxHeight: CGFloat = 120
        
        let conditionsRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: boxHeight)
        drawModernBox(ctx: ctx, rect: conditionsRect, title: "📋 CONDITIONS ET VALIDITÉ", color: secondaryBlue)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        var contentY = y + 40
        let leftCol = margin + 15
        let rightCol = margin + (bounds.width - margin * 2) / 2 + 15
        
        // Left column
        ("📅 Validité :" as NSString).draw(at: CGPoint(x: leftCol, y: contentY), withAttributes: contentAttrs)
        let validityText = "\(document.validityDays) jours à compter de ce jour"
        (validityText as NSString).draw(at: CGPoint(x: leftCol + 80, y: contentY), withAttributes: contentAttrs)
        contentY += 20
        
        ("💳 Acompte :" as NSString).draw(at: CGPoint(x: leftCol, y: contentY), withAttributes: contentAttrs)
        let advanceText = document.advance?.doubleValue ?? 0 > 0 ? 
            formatCurrency(document.advance!, currency: document.currencyCode ?? "EUR") : "Non demandé"
        (advanceText as NSString).draw(at: CGPoint(x: leftCol + 80, y: contentY), withAttributes: contentAttrs)
        contentY += 20
        
        ("🔧 Garanties :" as NSString).draw(at: CGPoint(x: leftCol, y: contentY), withAttributes: contentAttrs)
        ("Légales + décennale" as NSString).draw(at: CGPoint(x: leftCol + 80, y: contentY), withAttributes: contentAttrs)
        
        // Right column
        contentY = y + 40
        ("⏱️ Délai :" as NSString).draw(at: CGPoint(x: rightCol, y: contentY), withAttributes: contentAttrs)
        let delayText = calculateProjectDuration()
        (delayText as NSString).draw(at: CGPoint(x: rightCol + 80, y: contentY), withAttributes: contentAttrs)
        contentY += 20
        
        ("📍 Conditions :" as NSString).draw(at: CGPoint(x: rightCol, y: contentY), withAttributes: contentAttrs)
        ("Terrain accessible" as NSString).draw(at: CGPoint(x: rightCol + 80, y: contentY), withAttributes: contentAttrs)
        contentY += 20
        
        ("🏗️ Normes :" as NSString).draw(at: CGPoint(x: rightCol, y: contentY), withAttributes: contentAttrs)
        ("DTU en vigueur" as NSString).draw(at: CGPoint(x: rightCol + 80, y: contentY), withAttributes: contentAttrs)
        
        return y + boxHeight
    }
    
    private func drawBTPGuarantees(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxHeight: CGFloat = 100
        
        let guaranteesRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: boxHeight)
        drawModernBox(ctx: ctx, rect: guaranteesRect, title: "🛡️ GARANTIES BTP", color: successGreen)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: darkGray
        ]
        
        var contentY = y + 40
        let guarantees = [
            "🔧 Garantie de parfait achèvement : 1 an à compter de la réception",
            "🏗️ Garantie biennale : 2 ans (équipements dissociables)",
            "🏛️ Garantie décennale : 10 ans (éléments porteurs et étanchéité)",
            "📋 Assurance responsabilité civile et décennale en cours de validité"
        ]
        
        for guarantee in guarantees {
            (guarantee as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 15
        }
        
        return y + boxHeight
    }
    
    private func drawSignatureSection(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let _: CGFloat = 100
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: primaryOrange
        ]
        ("✍️ ACCEPTATION DU DEVIS" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        
        y += 25
        
        // Signature boxes
        let boxWidth = (bounds.width - margin * 2 - 30) / 2
        let boxHeight: CGFloat = 70
        
        // Company signature
        let companySignRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        lightGray.setFill()
        ctx.fill(companySignRect)
        darkGray.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(companySignRect)
        
        let signAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        ("Date et signature de l'entreprise" as NSString).draw(
            at: CGPoint(x: margin + 10, y: y + 10),
            withAttributes: signAttrs
        )
        
        // Client signature
        let clientSignRect = CGRect(x: margin + boxWidth + 30, y: y, width: boxWidth, height: boxHeight)
        lightGray.setFill()
        ctx.fill(clientSignRect)
        darkGray.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(clientSignRect)
        
        ("Date et signature du client" as NSString).draw(
            at: CGPoint(x: margin + boxWidth + 40, y: y + 10),
            withAttributes: signAttrs
        )
        ("« Bon pour accord »" as NSString).draw(
            at: CGPoint(x: margin + boxWidth + 40, y: y + 25),
            withAttributes: signAttrs
        )
        
        return y + boxHeight
    }
    
    private func drawModernFooter(ctx: CGContext) {
        let footerY = bounds.height - 50
        let footerHeight: CGFloat = 50
        
        // Footer background
        let footerRect = CGRect(x: 0, y: footerY, width: bounds.width, height: footerHeight)
        lightOrange.setFill()
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
        
        // Modern BTP quote indicator
        let btpIndicator = "🏗️ Devis BTP ModernElite • Conforme DTU et réglementation en vigueur"
        (btpIndicator as NSString).draw(
            in: CGRect(x: margin, y: footerY + 30, width: bounds.width - margin * 2, height: 15),
            withAttributes: attrs
        )
    }
    
    // MARK: - Helper Functions
    
    private func drawModernBox(ctx: CGContext, rect: CGRect, title: String, color: NSColor) {
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
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: NSColor.white
        ]
        (title as NSString).draw(at: CGPoint(x: rect.origin.x + 15, y: rect.origin.y + 8), withAttributes: titleAttrs)
        
        // Border
        color.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(rect)
    }
    
    private func getItemsGroupedByCorpsEtat() -> [(CorpsEtat?, [LineItem])] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return [] }
        
        let grouped = Dictionary(grouping: lineItems.sorted { $0.position < $1.position }) { $0.corpsEtat }
        
        return grouped.sorted { left, right in
            let leftKey = left.key?.rawValue ?? "zzz"
            let rightKey = right.key?.rawValue ?? "zzz"
            return leftKey < rightKey
        }
    }
    
    private func buildItemDescription(_ item: LineItem) -> String {
        var description = item.itemDescription ?? ""
        
        if let specifications = item.specifications, !specifications.isEmpty {
            description += " - \(specifications)"
        }
        
        if let materials = item.materials, !materials.isEmpty {
            description += " (\(materials))"
        }
        
        return description
    }
    
    private func calculateProjectDuration() -> String {
        if let startDate = document.projectStartDate,
           let endDate = document.projectEndDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day], from: startDate, to: endDate)
            if let days = components.day, days > 0 {
                return "\(days) jour(s)"
            }
        }
        
        // Estimate based on work complexity
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else {
            return "À définir"
        }
        
        let itemCount = lineItems.count
        let estimatedDays = max(1, itemCount * 2) // 2 days per line item as rough estimate
        return "≈ \(estimatedDays) jour(s)"
    }
    
    private func getSmartVATRate(for item: LineItem) -> Double {
        // Use BTP-aware VAT calculation
        if document.typeTravaux != nil {
            let suggestedRate = document.suggestedVATRate()
            return suggestedRate * 100 // Convert to percentage
        }
        
        return item.taxRate
    }
    
    private func corpsEtatToNSColor(_ corpsEtat: CorpsEtat) -> NSColor {
        switch corpsEtat.category {
        case .grosOeuvre: return NSColor.brown
        case .secondOeuvre: return NSColor.blue
        case .finitions: return NSColor.purple
        case .techniques: return NSColor.red
        case .exterieur: return NSColor.green
        case .menuiseries: return NSColor.orange
        case .specialises: return NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.8, alpha: 1.0)
        }
    }
    
    private func getVATBreakdown() -> [VATBreakdown] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return [] }
        
        let grouped = Dictionary(grouping: lineItems) { item in
            getSmartVATRate(for: item)
        }
        
        return grouped.map { rate, items in
            let base = items.reduce(0.0) { sum, item in
                let itemTotal = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
                let discount = itemTotal * (item.discount / 100.0)
                return sum + (itemTotal - discount)
            }
            let vatAmount = base * (rate / 100.0)
            
            return VATBreakdown(rate: rate, base: base, amount: vatAmount)
        }.sorted { $0.rate < $1.rate }
    }
    
    private func buildCompanyFooterInfo() -> String {
        var components: [String] = []
        
        if let name = UserDefaults.standard.string(forKey: "companyName"), !name.isEmpty {
            components.append(name)
        }
        
        if let address = UserDefaults.standard.string(forKey: "companyAddress"), !address.isEmpty {
            components.append(address)
        }
        
        if let siret = UserDefaults.standard.string(forKey: "companySIRET"), !siret.isEmpty {
            components.append("SIRET: \(siret)")
        }
        
        if let taxId = UserDefaults.standard.string(forKey: "companyTaxId"), !taxId.isEmpty {
            components.append("TVA: \(taxId)")
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

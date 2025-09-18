import Foundation
import AppKit
import PDFKit
import SwiftUI

// MARK: - Modern BTP Invoice Template (Compatible with new BTP infrastructure)
final class ModernBTPInvoiceTemplate {
    private let pageSize = CGSize(width: 595, height: 842) // A4
    private let margin: CGFloat = 40
    
    // Modern BTP color scheme
    private let primaryBlue = NSColor(calibratedRed: 0.051, green: 0.278, blue: 0.631, alpha: 1.0) // #0D47A1
    private let accentOrange = NSColor(calibratedRed: 1.0, green: 0.341, blue: 0.133, alpha: 1.0) // #FF5722
    private let lightGray = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
    private let darkGray = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    private let successGreen = NSColor(calibratedRed: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
    
    func generate(document: Document) -> Data? {
        let view = ModernBTPInvoiceView(
            frame: CGRect(origin: .zero, size: pageSize),
            document: document,
            margin: margin,
            primaryBlue: primaryBlue,
            accentOrange: accentOrange,
            lightGray: lightGray,
            darkGray: darkGray,
            successGreen: successGreen
        )
        return view.dataWithPDF(inside: view.bounds)
    }
}

private final class ModernBTPInvoiceView: NSView {
    private let document: Document
    private let margin: CGFloat
    private let primaryBlue: NSColor
    private let accentOrange: NSColor
    private let lightGray: NSColor
    private let darkGray: NSColor
    private let successGreen: NSColor
    
    init(frame: CGRect, document: Document, margin: CGFloat, primaryBlue: NSColor, accentOrange: NSColor, lightGray: NSColor, darkGray: NSColor, successGreen: NSColor) {
        self.document = document
        self.margin = margin
        self.primaryBlue = primaryBlue
        self.accentOrange = accentOrange
        self.lightGray = lightGray
        self.darkGray = darkGray
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
        currentY = drawBTPProjectInfo(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPItemsTable(ctx: ctx, startY: currentY + 20)
        currentY = drawModernTotals(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPPaymentInfo(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPLegalMentions(ctx: ctx, startY: currentY + 20)
        drawModernFooter(ctx: ctx)
    }
    
    private func drawModernHeader(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Header background with gradient
        let headerRect = CGRect(x: 0, y: y, width: bounds.width, height: 120)
        let gradient = NSGradient(colors: [primaryBlue, primaryBlue.blended(withFraction: 0.2, of: .black)!])
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
        
        // FACTURE title with modern styling
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 48),
            .foregroundColor: NSColor.white
        ]
        let title = "FACTURE" as NSString
        let titleSize = title.size(withAttributes: titleAttrs)
        title.draw(at: CGPoint(x: bounds.width - margin - titleSize.width, y: y + 30), withAttributes: titleAttrs)
        
        // Document details with modern layout
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
        
        // Company box with modern design
        let companyRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        drawModernBox(ctx: ctx, rect: companyRect, title: "ÉMETTEUR", color: primaryBlue)
        
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
        
        if let siret = UserDefaults.standard.string(forKey: "companySIRET"), !siret.isEmpty {
            ("SIRET : \(siret)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
        }
        
        // Client box
        let clientRect = CGRect(x: margin + boxWidth + 30, y: y, width: boxWidth, height: boxHeight)
        drawModernBox(ctx: ctx, rect: clientRect, title: "CLIENT", color: accentOrange)
        
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
    
    private func drawBTPProjectInfo(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxHeight: CGFloat = 120
        
        let projectRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: boxHeight)
        drawModernBox(ctx: ctx, rect: projectRect, title: "🏗️ INFORMATIONS CHANTIER BTP", color: successGreen)
        
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
        let siteAddress = document.siteAddress ?? "Non spécifiée"
        (siteAddress as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Nature des travaux :" as NSString).draw(at: CGPoint(x: leftCol, y: infoY), withAttributes: labelAttrs)
        let workType = document.typeTravaux?.localized ?? "Non spécifiée"
        (workType as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        // Right column
        infoY = y + 40
        ("Zone de travaux :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let workZone = document.zoneTravaux?.localized ?? "Non spécifiée"
        (workZone as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Pays/Réglementation :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let countryInfo = "\(document.btpCountry.flag) \(document.btpCountry.name)"
        (countryInfo as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        return y + boxHeight
    }
    
    private func drawBTPItemsTable(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let tableWidth = bounds.width - margin * 2
        
        // Table header with BTP columns
        let headerHeight: CGFloat = 45
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: headerHeight)
        
        let gradient = NSGradient(colors: [primaryBlue, primaryBlue.blended(withFraction: 0.1, of: .black)!])
        gradient?.draw(in: headerRect, angle: 0)
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.white
        ]
        
        // BTP-specific column headers
        var xPos = margin + 10
        ("Corps d'État" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 100
        ("Désignation" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 180
        ("Unité" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 60
        ("Qté" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 60
        ("P.U. HT" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 80
        ("TVA" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 50
        ("Total HT" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        
        y += headerHeight
        
        // Items with BTP data
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else {
            return y
        }
        
        let sortedItems = lineItems.sorted { $0.position < $1.position }
        let rowHeight: CGFloat = 40
        
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
                (colorIndicator as NSString).draw(at: CGPoint(x: xPos, y: y + 12), withAttributes: colorAttrs)
                
                let corpsText = corpsEtat.rawValue.prefix(8) + (corpsEtat.rawValue.count > 8 ? "..." : "")
                (String(corpsText) as NSString).draw(at: CGPoint(x: xPos + 15, y: y + 15), withAttributes: itemAttrs)
            } else {
                ("Général" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
            }
            xPos += 100
            
            // Description
            if let desc = item.itemDescription {
                let truncated = desc.prefix(25) + (desc.count > 25 ? "..." : "")
                (String(truncated) as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
            }
            xPos += 180
            
            // Unit (using BTP units)
            let unit = item.uniteBTP?.rawValue ?? item.unit ?? "u"
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
            
            // VAT rate with smart calculation
            let vatRate = String(format: "%.1f%%", item.taxRate)
            (vatRate as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
            xPos += 50
            
            // Line total
            let lineTotal = calculateLineTotal(item)
            let total = formatCurrency(lineTotal, currency: document.currencyCode ?? "EUR")
            (total as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
            
            y += rowHeight
        }
        
        // Table border
        primaryBlue.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: margin, y: startY + headerHeight, width: tableWidth, height: y - startY - headerHeight))
        
        return y
    }
    
    private func drawModernTotals(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth: CGFloat = 300
        let boxHeight: CGFloat = 160
        let x = bounds.width - margin - boxWidth
        
        let totalsRect = CGRect(x: x, y: y, width: boxWidth, height: boxHeight)
        drawModernBox(ctx: ctx, rect: totalsRect, title: "💰 TOTAUX", color: primaryBlue)
        
        // Calculate totals using BTP-aware calculations
        let calculations = DocumentCalculations(document: document)
        let currency = document.currencyCode ?? "EUR"
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: darkGray
        ]
        let _: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: darkGray
        ]
        
        var totalY = y + 40
        
        // Subtotal HT
        ("Total HT :" as NSString).draw(at: CGPoint(x: x + 20, y: totalY), withAttributes: normalAttrs)
        (formatCurrency(calculations.subtotal, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 120, y: totalY),
            withAttributes: normalAttrs
        )
        totalY += 25
        
        // VAT breakdown by rate
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
        
        // Separator line
        ctx.setStrokeColor(darkGray.cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: x + 20, y: totalY + 5))
        ctx.addLine(to: CGPoint(x: x + boxWidth - 20, y: totalY + 5))
        ctx.strokePath()
        totalY += 15
        
        // Total TTC with modern highlight
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
        
        return y + boxHeight
    }
    
    private func drawBTPPaymentInfo(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxHeight: CGFloat = 110
        
        let paymentRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: boxHeight)
        drawModernBox(ctx: ctx, rect: paymentRect, title: "💳 CONDITIONS DE RÈGLEMENT BTP", color: accentOrange)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        var contentY = y + 40
        
        // Payment terms with BTP specifics
        if let dueDate = document.dueDate {
            let df = DateFormatter()
            df.locale = Locale(identifier: document.btpLanguage.localeIdentifier)
            df.dateFormat = "d MMMM yyyy"
            ("📅 Échéance de paiement : \(df.string(from: dueDate))" as NSString).draw(
                at: CGPoint(x: margin + 15, y: contentY),
                withAttributes: contentAttrs
            )
            contentY += 20
        }
        
        // IBAN
        if let iban = UserDefaults.standard.string(forKey: "companyIBAN"), !iban.isEmpty {
            ("🏦 IBAN : \(iban)" as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
            contentY += 20
        }
        
        // BTP-specific payment terms
        let btpTerms = "⚖️ Conformément à la Loi du 2 août 2005 • Pénalités : 3 × taux légal • Indemnité : 40 €"
        (btpTerms as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
        
        return y + boxHeight
    }
    
    private func drawBTPLegalMentions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: primaryBlue
        ]
        ("⚖️ MENTIONS LÉGALES BTP" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: darkGray.withAlphaComponent(0.8)
        ]
        
        y += 25
        let btpMentions = [
            "🏗️ Travaux réalisés conformément aux DTU en vigueur et règles de l'art",
            "🛡️ Garantie de parfait achèvement : 1 an à compter de la réception",
            "🏛️ Garantie décennale : 10 ans (éléments d'équipement indissociables)",
            "🏢 Assurance responsabilité civile et décennale : Police n° \(UserDefaults.standard.string(forKey: "insuranceNumber") ?? "À préciser")",
            "📋 Réserve de propriété : les matériaux restent notre propriété jusqu'au paiement intégral",
            "⚖️ En cas de litige : Tribunal de Commerce de \(UserDefaults.standard.string(forKey: "companyCity") ?? "Paris")",
            "🇫🇷 Conforme au Code de la Construction et de l'Habitation"
        ]
        
        for mention in btpMentions {
            (mention as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: contentAttrs)
            y += 15
        }
        
        return y
    }
    
    private func drawModernFooter(ctx: CGContext) {
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
        
        // Modern BTP indicator
        let btpIndicator = "🏗️ Template BTP ModernElite • Conforme réglementation française"
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
    
    private func getVATBreakdown() -> [ModernBTPVATBreakdown] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return [] }
        
        let grouped = Dictionary(grouping: lineItems) { $0.taxRate }
        
        return grouped.map { rate, items in
            let base = items.reduce(0.0) { sum, item in
                let itemTotal = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
                let discount = itemTotal * (item.discount / 100.0)
                return sum + (itemTotal - discount)
            }
            let vatAmount = base * (rate / 100.0)
            
            return ModernBTPVATBreakdown(rate: rate, base: base, amount: vatAmount)
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

// MARK: - Helper Models
struct ModernBTPVATBreakdown {
    let rate: Double
    let base: Double
    let amount: Double
}


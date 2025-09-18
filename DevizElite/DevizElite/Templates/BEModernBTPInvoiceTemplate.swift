import Foundation
import AppKit
import PDFKit
import SwiftUI

// MARK: - Belgian Modern BTP Invoice Template (Compatible with new BTP infrastructure)
final class BEModernBTPInvoiceTemplate {
    private let pageSize = CGSize(width: 595, height: 842) // A4
    private let margin: CGFloat = 40
    
    // Belgian BTP color scheme
    private let primaryRed = NSColor(calibratedRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0) // Belgian red
    private let accentYellow = NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Belgian yellow
    private let lightGray = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
    private let darkGray = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    private let successGreen = NSColor(calibratedRed: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
    
    func generate(document: Document) -> Data? {
        let view = BEModernBTPInvoiceView(
            frame: CGRect(origin: .zero, size: pageSize),
            document: document,
            margin: margin,
            primaryRed: primaryRed,
            accentYellow: accentYellow,
            lightGray: lightGray,
            darkGray: darkGray,
            successGreen: successGreen
        )
        return view.dataWithPDF(inside: view.bounds)
    }
}

private final class BEModernBTPInvoiceView: NSView {
    private let document: Document
    private let margin: CGFloat
    private let primaryRed: NSColor
    private let accentYellow: NSColor
    private let lightGray: NSColor
    private let darkGray: NSColor
    private let successGreen: NSColor
    
    init(frame: CGRect, document: Document, margin: CGFloat, primaryRed: NSColor, accentYellow: NSColor, lightGray: NSColor, darkGray: NSColor, successGreen: NSColor) {
        self.document = document
        self.margin = margin
        self.primaryRed = primaryRed
        self.accentYellow = accentYellow
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
        currentY = drawBelgianHeader(ctx: ctx, startY: currentY)
        currentY = drawCompanyAndClientBelgian(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPProjectInfo(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPItemsTable(ctx: ctx, startY: currentY + 20)
        currentY = drawBelgianTotals(ctx: ctx, startY: currentY + 20)
        currentY = drawBTPPaymentInfo(ctx: ctx, startY: currentY + 20)
        currentY = drawBelgianLegalMentions(ctx: ctx, startY: currentY + 20)
        drawBelgianFooter(ctx: ctx)
    }
    
    private func drawBelgianHeader(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        
        // Header background with Belgian colors gradient
        let headerRect = CGRect(x: 0, y: y, width: bounds.width, height: 120)
        let gradient = NSGradient(colors: [primaryRed, primaryRed.blended(withFraction: 0.2, of: .black)!])
        gradient?.draw(in: headerRect, angle: 45)
        
        // Company info section with accent
        let logoRect = CGRect(x: margin, y: y + 20, width: 200, height: 80)
        accentYellow.withAlphaComponent(0.2).setFill()
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
        
        // FACTUUR title (Belgian)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 48),
            .foregroundColor: accentYellow
        ]
        let title = "FACTUUR" as NSString
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
        
        // Company box with Belgian design
        let companyRect = CGRect(x: margin, y: y, width: boxWidth, height: boxHeight)
        drawBelgianBox(ctx: ctx, rect: companyRect, title: "LEVERANCIER", color: primaryRed)
        
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
        drawBelgianBox(ctx: ctx, rect: clientRect, title: "KLANT", color: accentYellow)
        
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
        drawBelgianBox(ctx: ctx, rect: projectRect, title: "🏗️ BOUWWERF INFORMATIE", color: successGreen)
        
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
        ("Adres bouwwerf :" as NSString).draw(at: CGPoint(x: leftCol, y: infoY), withAttributes: labelAttrs)
        let siteAddress = document.siteAddress ?? "Niet gespecificeerd"
        (siteAddress as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Aard van de werken :" as NSString).draw(at: CGPoint(x: leftCol, y: infoY), withAttributes: labelAttrs)
        let workType = document.typeTravaux?.localized ?? "Niet gespecificeerd"
        (workType as NSString).draw(at: CGPoint(x: leftCol, y: infoY + 15), withAttributes: valueAttrs)
        
        // Right column
        infoY = y + 40
        ("Werkzone :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let workZone = document.zoneTravaux?.localized ?? "Niet gespecificeerd"
        (workZone as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        infoY += 35
        ("Land/Regelgeving :" as NSString).draw(at: CGPoint(x: rightCol, y: infoY), withAttributes: labelAttrs)
        let countryInfo = "\(document.btpCountry.flag) \(document.btpCountry.name)"
        (countryInfo as NSString).draw(at: CGPoint(x: rightCol, y: infoY + 15), withAttributes: valueAttrs)
        
        return y + boxHeight
    }
    
    private func drawBTPItemsTable(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        let tableWidth = bounds.width - margin * 2
        
        // Table header with Belgian BTP columns
        let headerHeight: CGFloat = 45
        let headerRect = CGRect(x: margin, y: y, width: tableWidth, height: headerHeight)
        
        let gradient = NSGradient(colors: [primaryRed, primaryRed.blended(withFraction: 0.1, of: .black)!])
        gradient?.draw(in: headerRect, angle: 0)
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.white
        ]
        
        // Belgian BTP-specific column headers
        var xPos = margin + 10
        ("Corps d'État" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 100
        ("Omschrijving" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 180
        ("Eenheid" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 60
        ("Aantal" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 60
        ("E.P. excl." as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 80
        ("BTW" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        xPos += 50
        ("Totaal excl." as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: headerAttrs)
        
        y += headerHeight
        
        // Items with Belgian BTP data
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
                ("Algemeen" as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
            }
            xPos += 100
            
            // Description
            if let desc = item.itemDescription {
                let truncated = desc.prefix(25) + (desc.count > 25 ? "..." : "")
                (String(truncated) as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
            }
            xPos += 180
            
            // Unit (using BTP units)
            let unit = item.uniteBTP?.rawValue ?? item.unit ?? "st"
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
            
            // VAT rate with Belgian rates (6%/21%)
            let vatRate = String(format: "%.0f%%", item.taxRate)
            (vatRate as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
            xPos += 50
            
            // Line total
            let lineTotal = calculateLineTotal(item)
            let total = formatCurrency(lineTotal, currency: document.currencyCode ?? "EUR")
            (total as NSString).draw(at: CGPoint(x: xPos, y: y + 15), withAttributes: itemAttrs)
            
            y += rowHeight
        }
        
        // Table border
        primaryRed.setStroke()
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: margin, y: startY + headerHeight, width: tableWidth, height: y - startY - headerHeight))
        
        return y
    }
    
    private func drawBelgianTotals(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxWidth: CGFloat = 300
        let boxHeight: CGFloat = 160
        let x = bounds.width - margin - boxWidth
        
        let totalsRect = CGRect(x: x, y: y, width: boxWidth, height: boxHeight)
        drawBelgianBox(ctx: ctx, rect: totalsRect, title: "💰 TOTALEN", color: primaryRed)
        
        // Calculate totals using Belgian VAT rates
        let calculations = DocumentCalculations(document: document)
        let currency = document.currencyCode ?? "EUR"
        
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: darkGray
        ]
        
        var totalY = y + 40
        
        // Subtotal excl. BTW
        ("Totaal excl. BTW :" as NSString).draw(at: CGPoint(x: x + 20, y: totalY), withAttributes: normalAttrs)
        (formatCurrency(calculations.subtotal, currency: currency) as NSString).draw(
            at: CGPoint(x: x + boxWidth - 120, y: totalY),
            withAttributes: normalAttrs
        )
        totalY += 25
        
        // Belgian VAT breakdown (6%/21%)
        let vatBreakdown = getVATBreakdown()
        for breakdown in vatBreakdown {
            let vatLabel = "BTW \(String(format: "%.0f", breakdown.rate))% :"
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
        
        // Total incl. BTW with Belgian highlight
        let ttcRect = CGRect(x: x + 10, y: totalY, width: boxWidth - 20, height: 35)
        successGreen.setFill()
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
    
    private func drawBTPPaymentInfo(ctx: CGContext, startY: CGFloat) -> CGFloat {
        let y = startY
        let boxHeight: CGFloat = 110
        
        let paymentRect = CGRect(x: margin, y: y, width: bounds.width - margin * 2, height: boxHeight)
        drawBelgianBox(ctx: ctx, rect: paymentRect, title: "💳 BETALINGSVOORWAARDEN", color: accentYellow)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: darkGray
        ]
        
        var contentY = y + 40
        
        // Belgian payment terms
        if let dueDate = document.dueDate {
            let df = DateFormatter()
            df.locale = Locale(identifier: document.btpLanguage.localeIdentifier)
            df.dateFormat = "d MMMM yyyy"
            ("📅 Vervaldatum : \(df.string(from: dueDate))" as NSString).draw(
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
        
        // Belgian-specific payment terms
        let belgianTerms = "⚖️ Belgische wetgeving • Intrest: 3× wettelijk tarief • Schadevergoeding: 40 €"
        (belgianTerms as NSString).draw(at: CGPoint(x: margin + 15, y: contentY), withAttributes: contentAttrs)
        
        return y + boxHeight
    }
    
    private func drawBelgianLegalMentions(ctx: CGContext, startY: CGFloat) -> CGFloat {
        var y = startY
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: primaryRed
        ]
        ("⚖️ WETTELIJKE VERMELDINGEN" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: darkGray.withAlphaComponent(0.8)
        ]
        
        y += 25
        let belgianMentions = [
            "🏗️ Werken uitgevoerd conform geldende normen en regels van goed vakmanschap",
            "🛡️ Garantie van voltooiing: 1 jaar vanaf oplevering",
            "🏛️ Tienjarige garantie: 10 jaar (onroerend door bestemming)",
            "🏢 Verzekeringsmaatschappij: Polis nr. \(UserDefaults.standard.string(forKey: "insuranceNumber") ?? "Te specificeren")",
            "📋 Eigendomsvoorbehoud: materialen blijven onze eigendom tot volledige betaling",
            "⚖️ Bij geschillen: Rechtbank van Koophandel van \(UserDefaults.standard.string(forKey: "companyCity") ?? "Brussel")",
            "🇧🇪 Conform Belgische bouwregelgeving"
        ]
        
        for mention in belgianMentions {
            (mention as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: contentAttrs)
            y += 15
        }
        
        return y
    }
    
    private func drawBelgianFooter(ctx: CGContext) {
        let footerY = bounds.height - 50
        let footerHeight: CGFloat = 50
        
        // Footer background with Belgian colors
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
        
        // Belgian BTP indicator
        let btpIndicator = "🇧🇪 Template BTP België • Conform Belgische regelgeving"
        (btpIndicator as NSString).draw(
            in: CGRect(x: margin, y: footerY + 30, width: bounds.width - margin * 2, height: 15),
            withAttributes: attrs
        )
    }
    
    // MARK: - Helper Functions
    
    private func drawBelgianBox(ctx: CGContext, rect: CGRect, title: String, color: NSColor) {
        // Box shadow
        let shadowRect = CGRect(x: rect.origin.x + 2, y: rect.origin.y + 2, width: rect.width, height: rect.height)
        NSColor.black.withAlphaComponent(0.1).setFill()
        ctx.fill(shadowRect)
        
        // Main box
        NSColor.white.setFill()
        ctx.fill(rect)
        
        // Title bar with Belgian styling
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
    
    private func getVATBreakdown() -> [BEModernVATBreakdown] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return [] }
        
        let grouped = Dictionary(grouping: lineItems) { $0.taxRate }
        
        return grouped.map { rate, items in
            let base = items.reduce(0.0) { sum, item in
                let itemTotal = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
                let discount = itemTotal * (item.discount / 100.0)
                return sum + (itemTotal - discount)
            }
            let vatAmount = base * (rate / 100.0)
            
            return BEModernVATBreakdown(rate: rate, base: base, amount: vatAmount)
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

// MARK: - Helper Models
struct BEModernVATBreakdown {
    let rate: Double
    let base: Double
    let amount: Double
}


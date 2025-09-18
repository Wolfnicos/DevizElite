import SwiftUI
import CoreGraphics
import CoreData
import Foundation

#if os(iOS)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
#else
import AppKit
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
#endif

// MARK: - Generator PDF Universal pentru macOS și iOS
class UniversalPDFGenerator {
    static let pageWidth: CGFloat = 595.0  // A4 width in points
    static let pageHeight: CGFloat = 842.0 // A4 height in points
    static let margin: CGFloat = 40.0
    
    static func generatePDF(for document: Document) -> Data? {
        // Ensure we're on the main thread and document is valid
        guard !document.isDeleted,
              document.managedObjectContext != nil else {
            print("Document is invalid or deleted")
            return nil
        }
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            print("Could not create PDF consumer")
            return nil
        }
        
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            print("Could not create PDF context")
            return nil
        }
        
        // Begin PDF document
        context.beginPDFPage(nil)
        
        // Draw content
        drawPDFContent(in: context, document: document, pageRect: pageRect)
        
        // End page and document
        context.endPDFPage()
        context.closePDF()
        
        return pdfData as Data
    }
    
    private static func drawPDFContent(in context: CGContext, document: Document, pageRect: CGRect) {
        let contentRect = CGRect(
            x: margin,
            y: margin,
            width: pageRect.width - (margin * 2),
            height: pageRect.height - (margin * 2)
        )
        
        var currentY: CGFloat = contentRect.maxY
        
        // 1. Header avec logo et type document
        currentY = drawHeader(in: context, document: document, rect: contentRect, startY: currentY)
        
        // 2. Company et Client info
        currentY = drawCompanyAndClient(in: context, document: document, rect: contentRect, startY: currentY)
        
        // 3. Document info (number, date, etc.)
        currentY = drawDocumentInfo(in: context, document: document, rect: contentRect, startY: currentY)
        
        // 4. Table des articles
        let totals = drawItemsTable(in: context, document: document, rect: contentRect, startY: currentY)
        
        // 5. Totals
        drawTotals(in: context, totals: totals, rect: contentRect)
        
        // 6. Footer
        drawFooter(in: context, document: document, rect: contentRect)
    }
    
    // MARK: - Header
    private static func drawHeader(in context: CGContext, document: Document, rect: CGRect, startY: CGFloat) -> CGFloat {
        let headerHeight: CGFloat = 80
        let headerRect = CGRect(x: rect.minX, y: startY - headerHeight, width: rect.width, height: headerHeight)
        
        // Background gradient
        let colors = [
            CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
            CGColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0)
        ]
        
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
            context.saveGState()
            context.addRect(headerRect)
            context.clip()
            context.drawLinearGradient(gradient, start: headerRect.origin, end: CGPoint(x: headerRect.maxX, y: headerRect.minY), options: [])
            context.restoreGState()
        }
        
        // Company name with safety check
        let companyName = document.safeOwnerField("companyName")
        let displayName = companyName.isEmpty ? "DevizElite BTP" : companyName
        
        #if os(iOS)
        let whiteColor = UIColor.white
        #else
        let whiteColor = NSColor.white
        #endif
        
        drawText(
            displayName,
            at: CGPoint(x: headerRect.minX + 20, y: headerRect.midY + 10),
            fontSize: 24,
            weight: .bold,
            color: whiteColor,
            in: context
        )
        
        // Document type
        let docType = document.type?.lowercased() == "invoice" ? "FACTURE" : "DEVIS"
        #if os(iOS)
        let orangeColor = UIColor.orange
        let whiteTypeColor = UIColor.white
        #else
        let orangeColor = NSColor.orange
        let whiteTypeColor = NSColor.white
        #endif
        let typeColor = document.type?.lowercased() == "invoice" ? whiteTypeColor : orangeColor
        
        drawText(
            docType,
            at: CGPoint(x: headerRect.maxX - 150, y: headerRect.midY + 5),
            fontSize: 32,
            weight: .heavy,
            color: typeColor,
            in: context
        )
        
        // Document number and date
        let docNumber = "N° \(document.number ?? "2024-001")"
        drawText(
            docNumber,
            at: CGPoint(x: headerRect.maxX - 150, y: headerRect.midY - 15),
            fontSize: 12,
            color: whiteColor,
            in: context
        )
        
        return startY - headerHeight - 20
    }
    
    // MARK: - Company and Client
    private static func drawCompanyAndClient(in context: CGContext, document: Document, rect: CGRect, startY: CGFloat) -> CGFloat {
        let sectionHeight: CGFloat = 120
        let columnWidth = (rect.width - 40) / 2
        
        // Company section (left)
        let companyRect = CGRect(x: rect.minX, y: startY - sectionHeight, width: columnWidth, height: sectionHeight)
        drawSection(title: "ÉMETTEUR", rect: companyRect, in: context)
        
        var textY = companyRect.maxY - 30
        let companyName = document.safeOwnerField("companyName")
        let companyAddress = document.safeOwnerField("companyAddress")
        let companyCity = document.safeOwnerField("companyCity")
        let companyEmail = document.safeOwnerField("companyEmail")
        let companyTaxId = document.safeOwnerField("companyTaxId")
        
        if !companyName.isEmpty {
            drawText(companyName, at: CGPoint(x: companyRect.minX + 10, y: textY), fontSize: 11, weight: .medium, in: context)
            textY -= 16
        }
        
        if !companyAddress.isEmpty {
            drawText(companyAddress, at: CGPoint(x: companyRect.minX + 10, y: textY), fontSize: 10, in: context)
            textY -= 14
        }
        
        if !companyCity.isEmpty {
            drawText(companyCity, at: CGPoint(x: companyRect.minX + 10, y: textY), fontSize: 10, in: context)
            textY -= 14
        }
        
        if !companyEmail.isEmpty {
            drawText(companyEmail, at: CGPoint(x: companyRect.minX + 10, y: textY), fontSize: 10, in: context)
            textY -= 14
        }
        
        if !companyTaxId.isEmpty {
            drawText("TVA: \(companyTaxId)", at: CGPoint(x: companyRect.minX + 10, y: textY), fontSize: 10, in: context)
        }
        
        // Client section (right)
        let clientRect = CGRect(x: rect.minX + columnWidth + 40, y: startY - sectionHeight, width: columnWidth, height: sectionHeight)
        drawSection(title: "CLIENT", rect: clientRect, in: context)
        
        if let client = document.safeClient, !client.isDeleted {
            textY = clientRect.maxY - 30
            
            if let name = client.name, !name.isEmpty {
                drawText(name, at: CGPoint(x: clientRect.minX + 10, y: textY), fontSize: 11, weight: .medium, in: context)
                textY -= 16
            }
            
            if let address = client.address, !address.isEmpty {
                drawText(address, at: CGPoint(x: clientRect.minX + 10, y: textY), fontSize: 10, in: context)
                textY -= 14
            }
            
            let postalCode = client.postalCode ?? ""
            let city = client.city ?? ""
            if !postalCode.isEmpty || !city.isEmpty {
                let fullCity = "\(postalCode) \(city)".trimmingCharacters(in: .whitespaces)
                drawText(fullCity, at: CGPoint(x: clientRect.minX + 10, y: textY), fontSize: 10, in: context)
                textY -= 14
            }
            
            if let email = client.contactEmail, !email.isEmpty {
                drawText(email, at: CGPoint(x: clientRect.minX + 10, y: textY), fontSize: 10, in: context)
            }
        }
        
        return startY - sectionHeight - 20
    }
    
    // MARK: - Document Info
    private static func drawDocumentInfo(in context: CGContext, document: Document, rect: CGRect, startY: CGFloat) -> CGFloat {
        let infoHeight: CGFloat = 40
        
        // Site address if available
        if let siteAddress = document.siteAddress, !siteAddress.isEmpty {
            let siteRect = CGRect(x: rect.minX, y: startY - infoHeight, width: rect.width, height: infoHeight)
            #if os(iOS)
            context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.1).cgColor)
            context.fill(siteRect)
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            #else
            context.setFillColor(NSColor.systemBlue.withAlphaComponent(0.1).cgColor)
            context.fill(siteRect)
            context.setStrokeColor(NSColor.systemBlue.cgColor)
            #endif
            context.setLineWidth(1)
            context.stroke(siteRect)
            
            #if os(iOS)
            let blueColor = UIColor.systemBlue
            #else
            let blueColor = NSColor.systemBlue
            #endif
            
            drawText("CHANTIER", at: CGPoint(x: siteRect.minX + 10, y: siteRect.maxY - 12), fontSize: 10, weight: .semibold, color: blueColor, in: context)
            drawText("Adresse: \(siteAddress)", at: CGPoint(x: siteRect.minX + 10, y: siteRect.maxY - 28), fontSize: 10, in: context)
            
            return startY - infoHeight - 10
        }
        
        return startY
    }
    
    // MARK: - Items Table
    private static func drawItemsTable(in context: CGContext, document: Document, rect: CGRect, startY: CGFloat) -> DocumentTotals {
        let tableStartY = startY - 30
        let rowHeight: CGFloat = 25
        let headerHeight: CGFloat = 30
        
        // Table columns
        let columns = [
            (title: "Désignation", width: rect.width * 0.4),
            (title: "Qté", width: rect.width * 0.1),
            (title: "Unité", width: rect.width * 0.1),
            (title: "P.U. HT", width: rect.width * 0.15),
            (title: "TVA", width: rect.width * 0.1),
            (title: "Total HT", width: rect.width * 0.15)
        ]
        
        // Draw header
        let headerRect = CGRect(x: rect.minX, y: tableStartY - headerHeight, width: rect.width, height: headerHeight)
        #if os(iOS)
        context.setFillColor(UIColor.systemBlue.cgColor)
        let tableWhiteColor = UIColor.white
        #else
        context.setFillColor(NSColor.systemBlue.cgColor)
        let tableWhiteColor = NSColor.white
        #endif
        context.fill(headerRect)
        
        var xPos = rect.minX
        for column in columns {
            drawText(
                column.title,
                at: CGPoint(x: xPos + 8, y: tableStartY - headerHeight + 8),
                fontSize: 11,
                weight: .semibold,
                color: tableWhiteColor,
                in: context
            )
            xPos += column.width
        }
        
        // Draw items with safety checks
        guard let lineItemsSet = document.lineItems else {
            let totalVAT: Double = 0
            return DocumentTotals(subtotal: 0, vatByRate: [:], totalVAT: totalVAT, total: 0)
        }
        
        let lineItems = lineItemsSet.allObjects as? [LineItem] ?? []
        var currentY = tableStartY - headerHeight
        var subtotal: Double = 0
        var vatByRate: [Double: Double] = [:]
        
        for (index, item) in lineItems.enumerated() {
            // Safety check for Core Data object
            guard !item.isDeleted else { continue }
            currentY -= rowHeight
            
            // Alternate row colors
            if index % 2 == 1 {
                let rowRect = CGRect(x: rect.minX, y: currentY, width: rect.width, height: rowHeight)
                #if os(iOS)
                context.setFillColor(UIColor.systemGray6.cgColor)
                #else
                context.setFillColor(NSColor.controlBackgroundColor.cgColor)
                #endif
                context.fill(rowRect)
            }
            
            let quantity = item.quantity?.doubleValue ?? 0
            let unitPrice = item.unitPrice?.doubleValue ?? 0
            let vatRate = (item.taxRate / 100.0)
            let itemTotal = quantity * unitPrice
            let itemVAT = itemTotal * vatRate
            
            subtotal += itemTotal
            vatByRate[vatRate, default: 0] += itemVAT
            
            // Draw row data
            xPos = rect.minX
            let rowData = [
                item.itemDescription ?? "Article",
                String(format: "%.2f", quantity),
                item.unit ?? "unité",
                String(format: "%.2f €", unitPrice),
                String(format: "%.0f%%", vatRate * 100),
                String(format: "%.2f €", itemTotal)
            ]
            
            for (i, data) in rowData.enumerated() {
                let alignment: NSTextAlignment = (i == 0) ? .left : (i >= 3) ? .right : .center
                drawTextInRect(
                    data,
                    in: CGRect(x: xPos + 4, y: currentY + 4, width: columns[i].width - 8, height: rowHeight - 8),
                    fontSize: 10,
                    alignment: alignment,
                    in: context
                )
                xPos += columns[i].width
            }
        }
        
        let totalVAT = vatByRate.values.reduce(0, +)
        return DocumentTotals(subtotal: subtotal, vatByRate: vatByRate, totalVAT: totalVAT, total: subtotal + totalVAT)
    }
    
    // MARK: - Totals
    private static func drawTotals(in context: CGContext, totals: DocumentTotals, rect: CGRect) {
        let totalsWidth: CGFloat = 200
        let totalsX = rect.maxX - totalsWidth
        let totalsStartY = rect.minY + 200
        
        var currentY = totalsStartY
        
        // Background
        let totalsRect = CGRect(x: totalsX - 10, y: totalsStartY - 80, width: totalsWidth + 20, height: 80)
        #if os(iOS)
        context.setFillColor(UIColor.systemGray6.cgColor)
        #else
        context.setFillColor(NSColor.controlBackgroundColor.cgColor)
        #endif
        context.fill(totalsRect)
        #if os(iOS)
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        #else
        context.setStrokeColor(NSColor.systemGray.cgColor)
        #endif
        context.setLineWidth(1)
        context.stroke(totalsRect)
        
        // Subtotal
        drawText("Sous-total HT:", at: CGPoint(x: totalsX, y: currentY), fontSize: 11, in: context)
        drawText(String(format: "%.2f €", totals.subtotal), at: CGPoint(x: totalsX + 120, y: currentY), fontSize: 11, weight: .medium, in: context)
        currentY -= 18
        
        // VAT by rate
        for (rate, amount) in totals.vatByRate.sorted(by: { $0.key < $1.key }) {
            let ratePercent = Int(rate * 100)
            drawText("TVA \(ratePercent)%:", at: CGPoint(x: totalsX, y: currentY), fontSize: 11, color: getSystemGray(), in: context)
            drawText(String(format: "%.2f €", amount), at: CGPoint(x: totalsX + 120, y: currentY), fontSize: 11, in: context)
            currentY -= 18
        }
        
        // Total
        currentY -= 5
        let totalRect = CGRect(x: totalsX - 5, y: currentY - 5, width: totalsWidth + 10, height: 25)
        #if os(iOS)
        context.setFillColor(UIColor.systemBlue.cgColor)
        #else
        context.setFillColor(NSColor.systemBlue.cgColor)
        #endif
        context.fill(totalRect)
        
        #if os(iOS)
        let totalWhiteColor = UIColor.white
        #else
        let totalWhiteColor = NSColor.white
        #endif
        
        drawText("TOTAL TTC:", at: CGPoint(x: totalsX, y: currentY + 3), fontSize: 14, weight: .bold, color: totalWhiteColor, in: context)
        drawText(String(format: "%.2f €", totals.total), at: CGPoint(x: totalsX + 100, y: currentY + 3), fontSize: 14, weight: .bold, color: totalWhiteColor, in: context)
    }
    
    // MARK: - Footer
    private static func drawFooter(in context: CGContext, document: Document, rect: CGRect) {
        let footerY = rect.minY + 60
        
        // Separator line
        #if os(iOS)
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        #else
        context.setStrokeColor(NSColor.systemGray.cgColor)
        #endif
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: rect.minX, y: footerY))
        context.addLine(to: CGPoint(x: rect.maxX, y: footerY))
        context.strokePath()
        
        // Footer text
        let footerText: String
        if document.type?.lowercased() == "invoice" {
            footerText = "Facture payable à réception. En cas de retard de paiement, pénalité de 3 fois le taux d'intérêt légal."
        } else {
            footerText = "Devis valable 30 jours. Prix fermes et non révisables. Acompte de 30% à la commande."
        }
        
        drawTextInRect(
            footerText,
            in: CGRect(x: rect.minX, y: footerY - 40, width: rect.width, height: 30),
            fontSize: 8,
            color: getSystemGray(),
            alignment: .center,
            in: context
        )
    }
    
    // MARK: - Helper Functions
    
    private static func drawSection(title: String, rect: CGRect, in context: CGContext) {
        // Border
        #if os(iOS)
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        #else
        context.setStrokeColor(NSColor.systemBlue.cgColor)
        #endif
        context.setLineWidth(1.5)
        context.stroke(rect)
        
        // Title background
        let titleRect = CGRect(x: rect.minX, y: rect.maxY - 20, width: 80, height: 20)
        #if os(iOS)
        context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.1).cgColor)
        #else
        context.setFillColor(NSColor.systemBlue.withAlphaComponent(0.1).cgColor)
        #endif
        context.fill(titleRect)
        
        #if os(iOS)
        let sectionBlueColor = UIColor.systemBlue
        #else
        let sectionBlueColor = NSColor.systemBlue
        #endif
        
        drawText(title, at: CGPoint(x: rect.minX + 8, y: rect.maxY - 12), fontSize: 10, weight: .semibold, color: sectionBlueColor, in: context)
    }
    
    private static func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, weight: FontWeight = .regular, color: PlatformColor? = nil, in context: CGContext) {
        let font = systemFont(ofSize: fontSize, weight: weight)
        
        #if os(iOS)
        let finalColor = color ?? UIColor.black
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: finalColor
        ]
        text.draw(at: point, withAttributes: attributes)
        #else
        let finalColor = color ?? NSColor.black
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: finalColor
        ]
        text.draw(at: point, withAttributes: attributes)
        #endif
    }
    
    private static func drawTextInRect(_ text: String, in rect: CGRect, fontSize: CGFloat, weight: FontWeight = .regular, color: PlatformColor? = nil, alignment: NSTextAlignment = .left, in context: CGContext) {
        let font = systemFont(ofSize: fontSize, weight: weight)
        let finalColor = color ?? getBlackColor()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        #if os(iOS)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: finalColor,
            .paragraphStyle: paragraphStyle
        ]
        text.draw(in: rect, withAttributes: attributes)
        #else
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: finalColor,
            .paragraphStyle: paragraphStyle
        ]
        text.draw(in: rect, withAttributes: attributes)
        #endif
    }
    
    // Cross-platform font helper
    private static func systemFont(ofSize size: CGFloat, weight: FontWeight) -> PlatformFont {
        #if os(iOS)
        let uiWeight: UIFont.Weight
        switch weight {
        case .light: uiWeight = .light
        case .regular: uiWeight = .regular
        case .medium: uiWeight = .medium
        case .semibold: uiWeight = .semibold
        case .bold: uiWeight = .bold
        case .heavy: uiWeight = .heavy
        }
        return UIFont.systemFont(ofSize: size, weight: uiWeight)
        #else
        let nsWeight: NSFont.Weight
        switch weight {
        case .light: nsWeight = .light
        case .regular: nsWeight = .regular
        case .medium: nsWeight = .medium
        case .semibold: nsWeight = .semibold
        case .bold: nsWeight = .bold
        case .heavy: nsWeight = .heavy
        }
        return NSFont.systemFont(ofSize: size, weight: nsWeight)
        #endif
    }
    
    // Cross-platform color helpers
    private static func getBlackColor() -> PlatformColor {
        #if os(iOS)
        return UIColor.black
        #else
        return NSColor.black
        #endif
    }
    
    private static func getSystemGray() -> PlatformColor {
        #if os(iOS)
        return UIColor.systemGray
        #else
        return NSColor.systemGray
        #endif
    }
}

// MARK: - Supporting Types

enum FontWeight {
    case light, regular, medium, semibold, bold, heavy
}

struct DocumentTotals {
    let subtotal: Double
    let vatByRate: [Double: Double]
    let totalVAT: Double
    let total: Double
}
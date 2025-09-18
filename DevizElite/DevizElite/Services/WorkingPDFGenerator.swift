import Foundation
import CoreGraphics
import AppKit

// MARK: - PDF Generator that ACTUALLY draws text
class WorkingPDFGenerator {
    
    static func generatePDF(for document: Document) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData) else {
            return Data()
        }
        
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }
        
        context.beginPDFPage(nil)
        
        // Draw the actual content with WORKING text
        drawRealContent(in: context, document: document, pageRect: pageRect)
        
        context.endPDFPage()
        context.closePDF()
        
        return pdfData as Data
    }
    
    private static func drawRealContent(in context: CGContext, document: Document, pageRect: CGRect) {
        let margin: CGFloat = 40
        
        // 1. HEADER avec fond bleu et TEXT BLANC VISIBLE
        let headerRect = CGRect(x: 0, y: pageRect.height - 80, width: pageRect.width, height: 80)
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        context.fill(headerRect)
        
        // Company name - TEXT BLANC SUR BLEU
        let companyName = document.safeOwnerField("companyName").isEmpty ? "Metta Concept" : document.safeOwnerField("companyName")
        drawWorkingText(
            text: companyName,
            at: CGPoint(x: margin, y: pageRect.height - 45),
            fontSize: 24,
            color: NSColor.white,
            bold: true,
            in: context
        )
        
        // Document type - TEXT BLANC
        let docType = document.type?.lowercased() == "invoice" ? "FACTURE" : "DEVIS"
        drawWorkingText(
            text: docType,
            at: CGPoint(x: pageRect.width - 150, y: pageRect.height - 45),
            fontSize: 24,
            color: NSColor.white,
            bold: true,
            in: context
        )
        
        // 2. DOCUMENT INFO - TEXT NEGRU PE ALB
        var yPos: CGFloat = pageRect.height - 120
        
        let docNumber = "N° \(document.number ?? "2024-001")"
        drawWorkingText(
            text: docNumber,
            at: CGPoint(x: margin, y: yPos),
            fontSize: 14,
            color: NSColor.black,
            bold: true,
            in: context
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "fr_FR")
        let dateText = "Date: \(dateFormatter.string(from: document.issueDate ?? Date()))"
        drawWorkingText(
            text: dateText,
            at: CGPoint(x: pageRect.width - 200, y: yPos),
            fontSize: 12,
            color: NSColor.black,
            bold: false,
            in: context
        )
        
        yPos -= 40
        
        // 3. COMPANY INFO - TEXT NEGRU
        drawWorkingText(
            text: "ÉMETTEUR:",
            at: CGPoint(x: margin, y: yPos),
            fontSize: 12,
            color: NSColor.black,
            bold: true,
            in: context
        )
        
        yPos -= 20
        
        if !companyName.isEmpty {
            drawWorkingText(
                text: companyName,
                at: CGPoint(x: margin, y: yPos),
                fontSize: 11,
                color: NSColor.black,
                bold: false,
                in: context
            )
            yPos -= 18
        }
        
        let companyAddress = document.safeOwnerField("companyAddress")
        if !companyAddress.isEmpty {
            drawWorkingText(
                text: companyAddress,
                at: CGPoint(x: margin, y: yPos),
                fontSize: 10,
                color: NSColor.black,
                bold: false,
                in: context
            )
            yPos -= 18
        }
        
        let companyCity = document.safeOwnerField("companyCity")
        if !companyCity.isEmpty {
            drawWorkingText(
                text: companyCity,
                at: CGPoint(x: margin, y: yPos),
                fontSize: 10,
                color: NSColor.black,
                bold: false,
                in: context
            )
        }
        
        // 4. CLIENT INFO - TEXT NEGRU
        var clientY: CGFloat = pageRect.height - 160
        
        drawWorkingText(
            text: "CLIENT:",
            at: CGPoint(x: margin + 300, y: clientY),
            fontSize: 12,
            color: NSColor.black,
            bold: true,
            in: context
        )
        
        clientY -= 20
        
        if let client = document.safeClient {
            if let clientName = client.name, !clientName.isEmpty {
                drawWorkingText(
                    text: clientName,
                    at: CGPoint(x: margin + 300, y: clientY),
                    fontSize: 11,
                    color: NSColor.black,
                    bold: false,
                    in: context
                )
                clientY -= 18
            }
            
            if let clientAddress = client.address, !clientAddress.isEmpty {
                drawWorkingText(
                    text: clientAddress,
                    at: CGPoint(x: margin + 300, y: clientY),
                    fontSize: 10,
                    color: NSColor.black,
                    bold: false,
                    in: context
                )
                clientY -= 18
            }
            
            let postalCode = client.postalCode ?? ""
            let city = client.city ?? ""
            if !postalCode.isEmpty || !city.isEmpty {
                let fullCity = "\(postalCode) \(city)".trimmingCharacters(in: .whitespaces)
                if !fullCity.isEmpty {
                    drawWorkingText(
                        text: fullCity,
                        at: CGPoint(x: margin + 300, y: clientY),
                        fontSize: 10,
                        color: NSColor.black,
                        bold: false,
                        in: context
                    )
                }
            }
        }
        
        // 5. TABLE HEADER - FOND BLEU AVEC TEXT BLANC
        let tableStartY: CGFloat = 450
        let headerHeight: CGFloat = 25
        
        let tableHeaderRect = CGRect(x: margin, y: tableStartY, width: pageRect.width - 2*margin, height: headerHeight)
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        context.fill(tableHeaderRect)
        
        // Column headers - TEXT BLANC
        drawWorkingText(text: "Description", at: CGPoint(x: margin + 5, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        drawWorkingText(text: "Qté", at: CGPoint(x: margin + 250, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        drawWorkingText(text: "P.U. HT", at: CGPoint(x: margin + 300, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        drawWorkingText(text: "TVA", at: CGPoint(x: margin + 370, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        drawWorkingText(text: "Total HT", at: CGPoint(x: margin + 420, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        
        // 6. TABLE ITEMS - TEXT NEGRU AVEC CALCULS RÉELS
        guard let lineItemsSet = document.lineItems,
              let lineItems = lineItemsSet.allObjects as? [LineItem] else {
            return
        }
        
        var itemY = tableStartY - 20
        var totalHT: Double = 0
        var vatByRate: [Double: Double] = [:]
        
        for (index, item) in lineItems.enumerated() {
            guard !item.isDeleted else { continue }
            
            // Alternate row background
            if index % 2 == 1 {
                let rowRect = CGRect(x: margin, y: itemY - 5, width: pageRect.width - 2*margin, height: 20)
                context.setFillColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
                context.fill(rowRect)
            }
            
            let quantity = item.quantity?.doubleValue ?? 0
            let unitPrice = item.unitPrice?.doubleValue ?? 0
            let vatRate = item.taxRate / 100.0
            let lineTotal = quantity * unitPrice
            
            totalHT += lineTotal
            vatByRate[vatRate, default: 0] += lineTotal * vatRate
            
            // Draw item data - TEXT NOIR VISIBLE
            let description = item.itemDescription ?? "Article"
            drawWorkingText(text: description, at: CGPoint(x: margin + 5, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            drawWorkingText(text: String(format: "%.1f", quantity), at: CGPoint(x: margin + 250, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            drawWorkingText(text: String(format: "%.2f €", unitPrice), at: CGPoint(x: margin + 300, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            drawWorkingText(text: String(format: "%.0f%%", item.taxRate), at: CGPoint(x: margin + 370, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            drawWorkingText(text: String(format: "%.2f €", lineTotal), at: CGPoint(x: margin + 420, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            
            itemY -= 22
        }
        
        // 7. TOTALS - TEXT NOIR AVEC CALCULS CORRECTS
        let totalsX = pageRect.width - 200
        var totalsY: CGFloat = 250
        
        // Total HT
        drawWorkingText(
            text: "Total HT:",
            at: CGPoint(x: totalsX, y: totalsY),
            fontSize: 12,
            color: NSColor.black,
            bold: true,
            in: context
        )
        drawWorkingText(
            text: String(format: "%.2f €", totalHT),
            at: CGPoint(x: totalsX + 80, y: totalsY),
            fontSize: 12,
            color: NSColor.black,
            bold: false,
            in: context
        )
        
        totalsY -= 20
        
        // VAT by rate - CALCULS CORRECTS
        for (rate, amount) in vatByRate.sorted(by: { $0.key < $1.key }) {
            let ratePercent = Int(rate * 100)
            drawWorkingText(
                text: "TVA \(ratePercent)%:",
                at: CGPoint(x: totalsX, y: totalsY),
                fontSize: 11,
                color: NSColor.black,
                bold: false,
                in: context
            )
            drawWorkingText(
                text: String(format: "%.2f €", amount),
                at: CGPoint(x: totalsX + 80, y: totalsY),
                fontSize: 11,
                color: NSColor.black,
                bold: false,
                in: context
            )
            totalsY -= 18
        }
        
        // Total TTC - FOND BLEU AVEC TEXT BLANC
        let totalVAT = vatByRate.values.reduce(0, +)
        let totalTTC = totalHT + totalVAT
        
        totalsY -= 10
        let totalRect = CGRect(x: totalsX - 10, y: totalsY - 5, width: 180, height: 20)
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        context.fill(totalRect)
        
        drawWorkingText(
            text: "TOTAL TTC:",
            at: CGPoint(x: totalsX, y: totalsY),
            fontSize: 14,
            color: NSColor.white,
            bold: true,
            in: context
        )
        drawWorkingText(
            text: String(format: "%.2f €", totalTTC),
            at: CGPoint(x: totalsX + 80, y: totalsY),
            fontSize: 14,
            color: NSColor.white,
            bold: true,
            in: context
        )
    }
    
    // FONCTION QUI DESSINE VRAIMENT LE TEXTE
    private static func drawWorkingText(
        text: String,
        at point: CGPoint,
        fontSize: CGFloat,
        color: NSColor,
        bold: Bool,
        in context: CGContext
    ) {
        let font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        // Use Core Text for reliable text rendering
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        
        context.saveGState()
        
        // Set text position
        context.textPosition = point
        
        // Draw the text
        CTLineDraw(line, context)
        
        context.restoreGState()
    }
}
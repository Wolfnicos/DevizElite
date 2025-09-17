import Foundation
import CoreGraphics
import AppKit

// MARK: - Final PDF Generator with correct DEVIS/FACTURE differentiation
class FinalPDFGenerator {
    
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
        
        // Determine document type - DEVIS vs FACTURE
        let isDevis = document.type?.lowercased() == "estimate"
        
        // Draw content with proper DEVIS/FACTURE differentiation
        drawCompleteDocument(in: context, document: document, pageRect: pageRect, isDevis: isDevis)
        
        context.endPDFPage()
        context.closePDF()
        
        return pdfData as Data
    }
    
    private static func drawCompleteDocument(in context: CGContext, document: Document, pageRect: CGRect, isDevis: Bool) {
        let margin: CGFloat = 40
        
        // 1. HEADER with correct type differentiation
        drawHeader(in: context, document: document, pageRect: pageRect, isDevis: isDevis)
        
        // 2. Document info
        var yPos = drawDocumentInfo(in: context, document: document, pageRect: pageRect, startY: pageRect.height - 120)
        
        // 3. Company and Client
        yPos = drawCompanyAndClient(in: context, document: document, pageRect: pageRect, startY: yPos - 60)
        
        // 4. Items table with CORRECT calculations
        let calculations = drawItemsTable(in: context, document: document, pageRect: pageRect, startY: yPos - 40)
        
        // 5. Totals with CORRECT VAT calculations
        yPos = drawTotals(in: context, calculations: calculations, pageRect: pageRect, startY: 300)
        
        // 6. DEVIS vs FACTURE specific elements
        if isDevis {
            drawDevisSpecificElements(in: context, pageRect: pageRect, startY: yPos - 40)
        } else {
            drawFactureSpecificElements(in: context, pageRect: pageRect, startY: yPos - 40)
        }
    }
    
    private static func drawHeader(in context: CGContext, document: Document, pageRect: CGRect, isDevis: Bool) {
        let headerRect = CGRect(x: 0, y: pageRect.height - 80, width: pageRect.width, height: 80)
        
        // Different colors for DEVIS vs FACTURE
        if isDevis {
            context.setFillColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // Orange for DEVIS
        } else {
            context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0) // Blue for FACTURE
        }
        context.fill(headerRect)
        
        // Company name
        let companyName = document.safeOwnerField("companyName").isEmpty ? "Metta Concept" : document.safeOwnerField("companyName")
        drawText(
            text: companyName,
            at: CGPoint(x: 40, y: pageRect.height - 45),
            fontSize: 24,
            color: NSColor.white,
            bold: true,
            in: context
        )
        
        // Document type with correct differentiation
        let docType = isDevis ? "DEVIS" : "FACTURE"
        let typeColor = isDevis ? NSColor.white : NSColor.white
        
        drawText(
            text: docType,
            at: CGPoint(x: pageRect.width - 150, y: pageRect.height - 45),
            fontSize: 28,
            color: typeColor,
            bold: true,
            in: context
        )
    }
    
    private static func drawDocumentInfo(in context: CGContext, document: Document, pageRect: CGRect, startY: CGFloat) -> CGFloat {
        var yPos = startY
        
        let docNumber = "N° \(document.number ?? "2024-001")"
        drawText(
            text: docNumber,
            at: CGPoint(x: 40, y: yPos),
            fontSize: 14,
            color: NSColor.black,
            bold: true,
            in: context
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = Locale(identifier: "fr_FR")
        let dateText = "Date: \(dateFormatter.string(from: document.issueDate ?? Date()))"
        drawText(
            text: dateText,
            at: CGPoint(x: pageRect.width - 250, y: yPos),
            fontSize: 12,
            color: NSColor.black,
            bold: false,
            in: context
        )
        
        return yPos
    }
    
    private static func drawCompanyAndClient(in context: CGContext, document: Document, pageRect: CGRect, startY: CGFloat) -> CGFloat {
        var yPos = startY
        
        // Company info
        drawText(text: "ÉMETTEUR:", at: CGPoint(x: 40, y: yPos), fontSize: 12, color: NSColor.black, bold: true, in: context)
        yPos -= 20
        
        let companyName = document.safeOwnerField("companyName").isEmpty ? "Metta Concept" : document.safeOwnerField("companyName")
        if !companyName.isEmpty {
            drawText(text: companyName, at: CGPoint(x: 40, y: yPos), fontSize: 11, color: NSColor.black, bold: false, in: context)
            yPos -= 18
        }
        
        let companyAddress = document.safeOwnerField("companyAddress")
        if !companyAddress.isEmpty {
            drawText(text: companyAddress, at: CGPoint(x: 40, y: yPos), fontSize: 10, color: NSColor.black, bold: false, in: context)
            yPos -= 18
        }
        
        // Client info
        var clientY = startY
        drawText(text: "CLIENT:", at: CGPoint(x: 320, y: clientY), fontSize: 12, color: NSColor.black, bold: true, in: context)
        clientY -= 20
        
        if let client = document.safeClient {
            if let clientName = client.name, !clientName.isEmpty {
                drawText(text: clientName, at: CGPoint(x: 320, y: clientY), fontSize: 11, color: NSColor.black, bold: false, in: context)
                clientY -= 18
            }
            
            if let clientAddress = client.address, !clientAddress.isEmpty {
                drawText(text: clientAddress, at: CGPoint(x: 320, y: clientY), fontSize: 10, color: NSColor.black, bold: false, in: context)
                clientY -= 18
            }
            
            let postalCode = client.postalCode ?? ""
            let city = client.city ?? ""
            if !postalCode.isEmpty || !city.isEmpty {
                let fullCity = "\(postalCode) \(city)".trimmingCharacters(in: .whitespaces)
                if !fullCity.isEmpty {
                    drawText(text: fullCity, at: CGPoint(x: 320, y: clientY), fontSize: 10, color: NSColor.black, bold: false, in: context)
                }
            }
        }
        
        return min(yPos, clientY) - 20
    }
    
    private static func drawItemsTable(in context: CGContext, document: Document, pageRect: CGRect, startY: CGFloat) -> VATCalculations {
        let tableStartY = startY
        let headerHeight: CGFloat = 25
        
        // Table header
        let tableHeaderRect = CGRect(x: 40, y: tableStartY, width: pageRect.width - 80, height: headerHeight)
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        context.fill(tableHeaderRect)
        
        // Column headers
        drawText(text: "Description", at: CGPoint(x: 45, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        drawText(text: "Qté", at: CGPoint(x: 250, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        drawText(text: "P.U. HT", at: CGPoint(x: 300, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        drawText(text: "TVA", at: CGPoint(x: 370, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        drawText(text: "Total HT", at: CGPoint(x: 420, y: tableStartY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
        
        // Items
        guard let lineItemsSet = document.lineItems,
              let lineItems = lineItemsSet.allObjects as? [LineItem] else {
            return VATCalculations(totalHT: 0, vatByRate: [:], totalTTC: 0)
        }
        
        var itemY = tableStartY - 20
        var totalHT: Double = 0
        var vatByRate: [Double: Double] = [:]
        
        let validItems = lineItems.filter { !$0.isDeleted }.sorted { $0.position < $1.position }
        
        for (index, item) in validItems.enumerated() {
            // Alternate row background
            if index % 2 == 1 {
                let rowRect = CGRect(x: 40, y: itemY - 5, width: pageRect.width - 80, height: 20)
                context.setFillColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
                context.fill(rowRect)
            }
            
            let quantity = item.quantity?.doubleValue ?? 0
            let unitPrice = item.unitPrice?.doubleValue ?? 0
            let vatRatePercent = item.taxRate // This is stored as percentage (e.g., 20.0 for 20%)
            let vatRate = vatRatePercent / 100.0 // Convert to decimal (e.g., 0.20 for 20%)
            let lineTotal = quantity * unitPrice
            
            totalHT += lineTotal
            
            // CORRECT VAT calculation: base amount × VAT rate
            let lineVAT = lineTotal * vatRate
            vatByRate[vatRatePercent, default: 0] += lineVAT
            
            // Draw item data
            let description = item.itemDescription ?? "Article"
            drawText(text: description, at: CGPoint(x: 45, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            drawText(text: String(format: "%.1f", quantity), at: CGPoint(x: 250, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            drawText(text: String(format: "%.2f €", unitPrice), at: CGPoint(x: 300, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            drawText(text: String(format: "%.1f%%", vatRatePercent), at: CGPoint(x: 370, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            drawText(text: String(format: "%.2f €", lineTotal), at: CGPoint(x: 420, y: itemY), fontSize: 9, color: NSColor.black, bold: false, in: context)
            
            itemY -= 22
        }
        
        let totalVAT = vatByRate.values.reduce(0, +)
        return VATCalculations(totalHT: totalHT, vatByRate: vatByRate, totalTTC: totalHT + totalVAT)
    }
    
    private static func drawTotals(in context: CGContext, calculations: VATCalculations, pageRect: CGRect, startY: CGFloat) -> CGFloat {
        let totalsX = pageRect.width - 200
        var yPos = startY
        
        // Total HT
        drawText(text: "Total HT:", at: CGPoint(x: totalsX, y: yPos), fontSize: 12, color: NSColor.black, bold: true, in: context)
        drawText(text: formatEuro(calculations.totalHT), at: CGPoint(x: totalsX + 80, y: yPos), fontSize: 12, color: NSColor.black, bold: false, in: context)
        yPos -= 20
        
        // VAT by rate - CORRECT calculations
        for (ratePercent, amount) in calculations.vatByRate.sorted(by: { $0.key < $1.key }) {
            let vatText = String(format: "TVA %.1f%%:", ratePercent)
            drawText(text: vatText, at: CGPoint(x: totalsX, y: yPos), fontSize: 11, color: NSColor.black, bold: false, in: context)
            drawText(text: formatEuro(amount), at: CGPoint(x: totalsX + 80, y: yPos), fontSize: 11, color: NSColor.black, bold: false, in: context)
            yPos -= 18
        }
        
        // Total TTC
        yPos -= 10
        let totalRect = CGRect(x: totalsX - 10, y: yPos - 5, width: 180, height: 20)
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        context.fill(totalRect)
        
        drawText(text: "TOTAL TTC:", at: CGPoint(x: totalsX, y: yPos), fontSize: 14, color: NSColor.white, bold: true, in: context)
        drawText(text: formatEuro(calculations.totalTTC), at: CGPoint(x: totalsX + 80, y: yPos), fontSize: 14, color: NSColor.white, bold: true, in: context)
        
        return yPos - 30
    }
    
    // DEVIS specific elements
    private static func drawDevisSpecificElements(in context: CGContext, pageRect: CGRect, startY: CGFloat) {
        var yPos = startY
        
        // Validity
        drawText(
            text: "✓ Validité du devis : 30 jours",
            at: CGPoint(x: 40, y: yPos),
            fontSize: 11,
            color: NSColor.systemOrange,
            bold: true,
            in: context
        )
        
        yPos -= 30
        
        // Payment conditions
        drawText(text: "CONDITIONS DE PAIEMENT", at: CGPoint(x: 40, y: yPos), fontSize: 11, color: NSColor.black, bold: true, in: context)
        yPos -= 20
        
        let conditions = [
            "• Acompte à la signature : 30%",
            "• Début des travaux : 40%",
            "• Fin des travaux : 30%"
        ]
        
        for condition in conditions {
            drawText(text: condition, at: CGPoint(x: 50, y: yPos), fontSize: 10, color: NSColor.black, bold: false, in: context)
            yPos -= 18
        }
        
        // Signature boxes
        yPos -= 20
        drawSignatureBoxes(in: context, pageRect: pageRect, startY: yPos)
    }
    
    // FACTURE specific elements
    private static func drawFactureSpecificElements(in context: CGContext, pageRect: CGRect, startY: CGFloat) {
        var yPos = startY
        
        // Due date
        let dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = Locale(identifier: "fr_FR")
        
        drawText(
            text: "Date d'échéance : \(dateFormatter.string(from: dueDate))",
            at: CGPoint(x: 40, y: yPos),
            fontSize: 11,
            color: NSColor.systemRed,
            bold: true,
            in: context
        )
        
        yPos -= 30
        
        // Payment conditions
        drawText(text: "CONDITIONS DE RÈGLEMENT", at: CGPoint(x: 40, y: yPos), fontSize: 11, color: NSColor.black, bold: true, in: context)
        yPos -= 20
        
        let mentions = [
            "• Paiement à 30 jours date de facture",
            "• Pénalités de retard : 3 × taux d'intérêt légal",
            "• Indemnité forfaitaire pour frais de recouvrement : 40 €"
        ]
        
        for mention in mentions {
            drawText(text: mention, at: CGPoint(x: 50, y: yPos), fontSize: 9, color: NSColor.black, bold: false, in: context)
            yPos -= 15
        }
    }
    
    private static func drawSignatureBoxes(in context: CGContext, pageRect: CGRect, startY: CGFloat) {
        var yPos = startY
        
        // Title
        drawText(
            text: "ACCORD ET SIGNATURES",
            at: CGPoint(x: 200, y: yPos),
            fontSize: 12,
            color: NSColor.black,
            bold: true,
            in: context
        )
        
        yPos -= 40
        let boxHeight: CGFloat = 80
        let boxWidth: CGFloat = 220
        
        // Client signature box
        context.setStrokeColor(NSColor.darkGray.cgColor)
        context.setLineWidth(1)
        context.stroke(CGRect(x: 40, y: yPos - boxHeight, width: boxWidth, height: boxHeight))
        
        drawText(text: "LE CLIENT", at: CGPoint(x: 50, y: yPos - 15), fontSize: 11, color: NSColor.black, bold: true, in: context)
        drawText(text: "Lu et approuvé - Bon pour accord", at: CGPoint(x: 50, y: yPos - 35), fontSize: 9, color: NSColor.black, bold: false, in: context)
        drawText(text: "Date : .......................", at: CGPoint(x: 50, y: yPos - 55), fontSize: 10, color: NSColor.black, bold: false, in: context)
        drawText(text: "Signature :", at: CGPoint(x: 50, y: yPos - 70), fontSize: 10, color: NSColor.black, bold: false, in: context)
        
        // Company signature box
        context.stroke(CGRect(x: 320, y: yPos - boxHeight, width: boxWidth, height: boxHeight))
        
        drawText(text: "L'ENTREPRISE", at: CGPoint(x: 330, y: yPos - 15), fontSize: 11, color: NSColor.black, bold: true, in: context)
        drawText(text: "Metta Concept", at: CGPoint(x: 330, y: yPos - 35), fontSize: 10, color: NSColor.black, bold: false, in: context)
        drawText(text: "Date : .......................", at: CGPoint(x: 330, y: yPos - 55), fontSize: 10, color: NSColor.black, bold: false, in: context)
        drawText(text: "Signature et cachet :", at: CGPoint(x: 330, y: yPos - 70), fontSize: 10, color: NSColor.black, bold: false, in: context)
    }
    
    private static func drawText(text: String, at point: CGPoint, fontSize: CGFloat, color: NSColor, bold: Bool, in context: CGContext) {
        let font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        
        context.saveGState()
        context.textPosition = point
        CTLineDraw(line, context)
        context.restoreGState()
    }
    
    private static func formatEuro(_ amount: Double) -> String {
        String(format: "%.2f €", amount)
    }
}

// MARK: - Supporting structures
struct VATCalculations {
    let totalHT: Double
    let vatByRate: [Double: Double] // [vatRatePercent: vatAmount]
    let totalTTC: Double
}
import Foundation
import CoreGraphics
import AppKit

// MARK: - Final PDF Generator with correct DEVIS/FACTURE differentiation and pagination
class FinalPDFGenerator {
    
    // Constants for layout calculation
    private static let pageHeight: CGFloat = 842  // A4
    private static let pageWidth: CGFloat = 595   // A4
    private static let marginBottom: CGFloat = 50
    private static let signatureBoxHeight: CGFloat = 150  // Height needed for signatures
    private static let totalsHeight: CGFloat = 120       // Height needed for totals section
    
    static func generatePDF(for document: Document) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData) else {
            return Data()
        }
        
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }
        
        // Determine document type - DEVIS vs FACTURE
        let isDevis = document.type?.lowercased() == "estimate"
        
        // Generate PDF with pagination support
        generateMultiPagePDF(in: context, document: document, pageRect: pageRect, isDevis: isDevis)
        
        context.closePDF()
        
        return pdfData as Data
    }
    
    private static func generateMultiPagePDF(in context: CGContext, document: Document, pageRect: CGRect, isDevis: Bool) {
        var currentPage = 1
        var currentY: CGFloat = 0
        
        // Start first page
        context.beginPDFPage(nil)
        
        // 1. HEADER
        drawHeader(in: context, document: document, pageRect: pageRect, isDevis: isDevis)
        
        // 2. Document info
        currentY = drawDocumentInfo(in: context, document: document, pageRect: pageRect, startY: pageRect.height - 120)
        
        // 3. Company and Client
        currentY = drawCompanyAndClient(in: context, document: document, pageRect: pageRect, startY: currentY - 60)
        
        // 4. Items table with space checking
        let (calculations, finalY) = drawItemsTableWithPagination(
            in: context, 
            document: document, 
            pageRect: pageRect, 
            startY: currentY - 40,
            isDevis: isDevis,
            currentPage: &currentPage
        )
        currentY = finalY
        
        // 5. Check space for totals and signatures (DEVIS only)
        let spaceNeeded = totalsHeight + (isDevis ? signatureBoxHeight : 60)
        let spaceAvailable = currentY - marginBottom
        
        if spaceAvailable < spaceNeeded {
            // NOT enough space - start new page
            context.endPDFPage()
            context.beginPDFPage(nil)
            currentPage += 1
            
            // Draw simplified header on new page
            drawSimpleHeader(in: context, document: document, pageRect: pageRect, isDevis: isDevis, page: currentPage)
            currentY = pageRect.height - 80
        }
        
        // 6. Draw totals
        currentY = drawTotals(in: context, calculations: calculations, pageRect: pageRect, startY: currentY)
        
        // 7. Draw DEVIS vs FACTURE specific elements
        if isDevis {
            drawDevisSpecificElements(in: context, pageRect: pageRect, startY: currentY - 40)
        } else {
            drawFactureSpecificElements(in: context, pageRect: pageRect, startY: currentY - 40)
        }
        
        context.endPDFPage()
    }
    
    private static func drawCompleteDocument(in context: CGContext, document: Document, pageRect: CGRect, isDevis: Bool) {
        let _: CGFloat = 40
        
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
        let yPos = startY
        
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
        
        // Client info avec vérification améliorée
        var clientY = startY
        drawText(text: "CLIENT:", at: CGPoint(x: 320, y: clientY), fontSize: 12, color: NSColor.black, bold: true, in: context)
        clientY -= 20
        
        if let client = document.safeClient {
            let clientName = client.name ?? ""
            if !clientName.isEmpty {
                drawText(text: clientName, at: CGPoint(x: 320, y: clientY), fontSize: 11, color: NSColor.black, bold: false, in: context)
                clientY -= 18
            } else {
                // Pas de nom de client
                drawText(text: "Non spécifié", at: CGPoint(x: 320, y: clientY), fontSize: 11, color: NSColor.gray, bold: false, in: context)
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
                    clientY -= 18
                }
            }
            
            // Informations supplémentaires si disponibles
            if let phone = client.phone, !phone.isEmpty {
                drawText(text: "Tél: \(phone)", at: CGPoint(x: 320, y: clientY), fontSize: 9, color: NSColor.gray, bold: false, in: context)
                clientY -= 15
            }
            
            if let email = client.contactEmail, !email.isEmpty {
                drawText(text: "Email: \(email)", at: CGPoint(x: 320, y: clientY), fontSize: 9, color: NSColor.gray, bold: false, in: context)
                clientY -= 15
            }
        } else {
            // Aucun client associé
            drawText(text: "Aucun client spécifié", at: CGPoint(x: 320, y: clientY), fontSize: 11, color: NSColor.red, bold: false, in: context)
            clientY -= 18
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
    
    // MARK: - Pagination-aware items table
    private static func drawItemsTableWithPagination(
        in context: CGContext, 
        document: Document, 
        pageRect: CGRect, 
        startY: CGFloat,
        isDevis: Bool,
        currentPage: inout Int
    ) -> (VATCalculations, CGFloat) {
        
        guard let lineItemsSet = document.lineItems,
              let lineItems = lineItemsSet.allObjects as? [LineItem] else {
            return (VATCalculations(totalHT: 0, vatByRate: [:], totalTTC: 0), startY)
        }
        
        let validItems = lineItems.filter { !$0.isDeleted }.sorted { $0.position < $1.position }
        let headerHeight: CGFloat = 25
        let rowHeight: CGFloat = 22
        
        var totalHT: Double = 0
        var vatByRate: [Double: Double] = [:]
        var currentY = startY
        var itemIndex = 0
        
        // Calculate space needed for footer elements
        let footerSpace = totalsHeight + (isDevis ? signatureBoxHeight : 60) + marginBottom
        
        while itemIndex < validItems.count {
            // Draw table header
            let tableHeaderRect = CGRect(x: 40, y: currentY, width: pageRect.width - 80, height: headerHeight)
            context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
            context.fill(tableHeaderRect)
            
            // Column headers
            drawText(text: "Description", at: CGPoint(x: 45, y: currentY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
            drawText(text: "Qté", at: CGPoint(x: 250, y: currentY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
            drawText(text: "P.U. HT", at: CGPoint(x: 300, y: currentY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
            drawText(text: "TVA", at: CGPoint(x: 370, y: currentY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
            drawText(text: "Total HT", at: CGPoint(x: 420, y: currentY + 5), fontSize: 10, color: NSColor.white, bold: true, in: context)
            
            currentY -= 20
            
            // Draw items until page is full
            while itemIndex < validItems.count {
                let item = validItems[itemIndex]
                
                // Check if we have space for this row + footer
                if currentY - rowHeight < footerSpace {
                    // No space - start new page
                    if itemIndex < validItems.count - 1 { // Only if there are more items
                        context.endPDFPage()
                        context.beginPDFPage(nil)
                        currentPage += 1
                        
                        drawSimpleHeader(in: context, document: document, pageRect: pageRect, isDevis: isDevis, page: currentPage)
                        currentY = pageRect.height - 80
                        break // Break inner loop to redraw header
                    }
                }
                
                // Alternate row background
                if itemIndex % 2 == 1 {
                    let rowRect = CGRect(x: 40, y: currentY - 5, width: pageRect.width - 80, height: rowHeight)
                    context.setFillColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
                    context.fill(rowRect)
                }
                
                // Calculate values
                let quantity = item.quantity?.doubleValue ?? 0
                let unitPrice = item.unitPrice?.doubleValue ?? 0
                let vatRatePercent = item.taxRate
                let vatRate = vatRatePercent / 100.0
                let lineTotal = quantity * unitPrice
                
                totalHT += lineTotal
                let lineVAT = lineTotal * vatRate
                vatByRate[vatRatePercent, default: 0] += lineVAT
                
                // Draw item data with smaller font if many items
                let fontSize: CGFloat = validItems.count > 15 ? 8 : 9
                let description = item.itemDescription ?? "Article"
                
                drawText(text: description, at: CGPoint(x: 45, y: currentY), fontSize: fontSize, color: NSColor.black, bold: false, in: context)
                drawText(text: String(format: "%.1f", quantity), at: CGPoint(x: 250, y: currentY), fontSize: fontSize, color: NSColor.black, bold: false, in: context)
                drawText(text: String(format: "%.2f €", unitPrice), at: CGPoint(x: 300, y: currentY), fontSize: fontSize, color: NSColor.black, bold: false, in: context)
                drawText(text: String(format: "%.1f%%", vatRatePercent), at: CGPoint(x: 370, y: currentY), fontSize: fontSize, color: NSColor.black, bold: false, in: context)
                drawText(text: String(format: "%.2f €", lineTotal), at: CGPoint(x: 420, y: currentY), fontSize: fontSize, color: NSColor.black, bold: false, in: context)
                
                currentY -= rowHeight
                itemIndex += 1
            }
        }
        
        let totalVAT = vatByRate.values.reduce(0, +)
        return (VATCalculations(totalHT: totalHT, vatByRate: vatByRate, totalTTC: totalHT + totalVAT), currentY)
    }
    
    // MARK: - Simple header for continuation pages
    private static func drawSimpleHeader(in context: CGContext, document: Document, pageRect: CGRect, isDevis: Bool, page: Int) {
        let headerRect = CGRect(x: 0, y: pageRect.height - 60, width: pageRect.width, height: 60)
        
        // Different colors for DEVIS vs FACTURE
        if isDevis {
            context.setFillColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // Orange for DEVIS
        } else {
            context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0) // Blue for FACTURE
        }
        context.fill(headerRect)
        
        // Company name and document type
        let companyName = document.safeOwnerField("companyName").isEmpty ? "Metta Concept" : document.safeOwnerField("companyName")
        let docType = isDevis ? "DEVIS" : "FACTURE"
        let docNumber = document.number ?? ""
        
        drawText(
            text: "\(companyName) - \(docType) \(docNumber)",
            at: CGPoint(x: 40, y: pageRect.height - 35),
            fontSize: 16,
            color: NSColor.white,
            bold: true,
            in: context
        )
        
        drawText(
            text: "Page \(page)",
            at: CGPoint(x: pageRect.width - 100, y: pageRect.height - 35),
            fontSize: 12,
            color: NSColor.white,
            bold: false,
            in: context
        )
    }
    
    private static func drawTotals(in context: CGContext, calculations: VATCalculations, pageRect: CGRect, startY: CGFloat) -> CGFloat {
        let totalsX = pageRect.width - 200
        var yPos = startY
        
        // Total HT avec alignement parfait
        drawAlignedLabelValue(
            label: "Total HT :",
            value: formatEuro(calculations.totalHT),
            at: CGPoint(x: totalsX, y: yPos),
            labelFont: 12,
            valueFont: 12,
            color: NSColor.black,
            spacing: 100,
            in: context
        )
        yPos -= 20
        
        // VAT by rate - CORRECT calculations avec alignement
        for (ratePercent, amount) in calculations.vatByRate.sorted(by: { $0.key < $1.key }) {
            let vatText = String(format: "TVA %.1f%% :", ratePercent)
            drawAlignedLabelValue(
                label: vatText,
                value: formatEuro(amount),
                at: CGPoint(x: totalsX, y: yPos),
                labelFont: 11,
                valueFont: 11,
                color: NSColor.black,
                spacing: 100,
                in: context
            )
            yPos -= 18
        }
        
        // Total TTC avec espacement parfait
        yPos -= 10
        let totalRect = CGRect(x: totalsX - 10, y: yPos - 5, width: 200, height: 20)
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        context.fill(totalRect)
        
        drawAlignedLabelValue(
            label: "TOTAL TTC :",
            value: formatEuro(calculations.totalTTC),
            at: CGPoint(x: totalsX, y: yPos),
            labelFont: 14,
            valueFont: 14,
            color: NSColor.white,
            spacing: 100,
            bold: true,
            in: context
        )
        
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
    
    // MARK: - Aligned text drawing for perfect spacing
    private static func drawAlignedLabelValue(
        label: String,
        value: String,
        at point: CGPoint,
        labelFont: CGFloat,
        valueFont: CGFloat,
        color: NSColor,
        spacing: CGFloat,
        bold: Bool = false,
        in context: CGContext
    ) {
        // Draw label (left-aligned)
        drawText(
            text: label,
            at: point,
            fontSize: labelFont,
            color: color,
            bold: bold,
            in: context
        )
        
        // Draw value (right-aligned at fixed position)
        let valuePoint = CGPoint(x: point.x + spacing, y: point.y)
        drawText(
            text: value,
            at: valuePoint,
            fontSize: valueFont,
            color: color,
            bold: bold,
            in: context
        )
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

import SwiftUI
import PDFKit
import CoreGraphics

// MARK: - Simple PDF Generator that WORKS
class SimplePDFGenerator {
    
    static func generatePDF(for document: Document) -> Data? {
        // Use the direct Core Graphics approach for reliability
        return generatePDFLegacy(document: document)
    }
    
    
    // Legacy PDF generation using Core Graphics
    private static func generatePDFLegacy(document: Document) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let pdfData = NSMutableData()
        let consumer = CGDataConsumer(data: pdfData)!
        
        var mediaBox = pageRect
        let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
        
        context.beginPDFPage(nil)
        
        // Draw content directly
        drawPDFContent(in: context, document: document, pageRect: pageRect)
        
        context.endPDFPage()
        context.closePDF()
        
        return pdfData as Data
    }
    
    private static func drawPDFContent(in context: CGContext, document: Document, pageRect: CGRect) {
        let margin: CGFloat = 40
        
        // Set font
        let titleFont = NSFont.boldSystemFont(ofSize: 24)
        let headerFont = NSFont.boldSystemFont(ofSize: 14)
        let bodyFont = NSFont.systemFont(ofSize: 11)
        
        var yPosition: CGFloat = pageRect.height - margin
        
        // 1. Header with company name and document type
        yPosition -= 60
        
        // Header background
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        context.fill(CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 60))
        
        // Company name
        let companyName = document.safeOwnerField("companyName").isEmpty ? "Metta Concept" : document.safeOwnerField("companyName")
        drawText(companyName, at: CGPoint(x: margin + 20, y: yPosition + 35), font: titleFont, color: .white, in: context)
        
        // Document type
        let docType = document.type?.lowercased() == "invoice" ? "FACTURE" : "DEVIS"
        drawText(docType, at: CGPoint(x: pageRect.width - 150, y: yPosition + 35), font: titleFont, color: .white, in: context)
        
        yPosition -= 80
        
        // 2. Document info
        let docNumber = "N° \(document.number ?? "2024-001")"
        drawText(docNumber, at: CGPoint(x: margin, y: yPosition), font: headerFont, color: .black, in: context)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateText = "Date: \(dateFormatter.string(from: document.issueDate ?? Date()))"
        drawText(dateText, at: CGPoint(x: pageRect.width - 200, y: yPosition), font: bodyFont, color: .black, in: context)
        
        yPosition -= 60
        
        // 3. Company and Client info
        // Company
        drawText("ÉMETTEUR:", at: CGPoint(x: margin, y: yPosition), font: headerFont, color: .black, in: context)
        yPosition -= 20
        
        if !companyName.isEmpty {
            drawText(companyName, at: CGPoint(x: margin, y: yPosition), font: bodyFont, color: .black, in: context)
            yPosition -= 15
        }
        
        let companyAddress = document.safeOwnerField("companyAddress")
        if !companyAddress.isEmpty {
            drawText(companyAddress, at: CGPoint(x: margin, y: yPosition), font: bodyFont, color: .black, in: context)
            yPosition -= 15
        }
        
        yPosition -= 20
        
        // Client
        if let client = document.safeClient {
            drawText("CLIENT:", at: CGPoint(x: margin + 300, y: yPosition + 55), font: headerFont, color: .black, in: context)
            
            if let clientName = client.name {
                drawText(clientName, at: CGPoint(x: margin + 300, y: yPosition + 35), font: bodyFont, color: .black, in: context)
            }
            
            if let clientAddress = client.address {
                drawText(clientAddress, at: CGPoint(x: margin + 300, y: yPosition + 20), font: bodyFont, color: .black, in: context)
            }
        }
        
        yPosition -= 80
        
        // 4. Line items table
        drawItemsTable(in: context, document: document, startY: yPosition, margin: margin, pageRect: pageRect)
    }
    
    private static func drawItemsTable(in context: CGContext, document: Document, startY: CGFloat, margin: CGFloat, pageRect: CGRect) {
        let headerFont = NSFont.boldSystemFont(ofSize: 10)
        let bodyFont = NSFont.systemFont(ofSize: 9)
        
        var yPos = startY
        let tableWidth = pageRect.width - 2 * margin
        
        // Table header
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        context.fill(CGRect(x: margin, y: yPos - 25, width: tableWidth, height: 25))
        
        drawText("Description", at: CGPoint(x: margin + 5, y: yPos - 20), font: headerFont, color: .white, in: context)
        drawText("Qté", at: CGPoint(x: margin + 250, y: yPos - 20), font: headerFont, color: .white, in: context)
        drawText("P.U. HT", at: CGPoint(x: margin + 300, y: yPos - 20), font: headerFont, color: .white, in: context)
        drawText("TVA", at: CGPoint(x: margin + 370, y: yPos - 20), font: headerFont, color: .white, in: context)
        drawText("Total HT", at: CGPoint(x: margin + 420, y: yPos - 20), font: headerFont, color: .white, in: context)
        
        yPos -= 35
        
        // Items
        guard let lineItemsSet = document.lineItems,
              let lineItems = lineItemsSet.allObjects as? [LineItem] else {
            return
        }
        
        var totalHT: Double = 0
        var vatByRate: [Double: Double] = [:]
        
        for (index, item) in lineItems.enumerated() {
            guard !item.isDeleted else { continue }
            
            // Alternate row colors
            if index % 2 == 1 {
                context.setFillColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
                context.fill(CGRect(x: margin, y: yPos - 20, width: tableWidth, height: 20))
            }
            
            let quantity = item.quantity?.doubleValue ?? 0
            let unitPrice = item.unitPrice?.doubleValue ?? 0
            let vatRate = item.taxRate / 100.0 // Convert from percentage
            let lineTotal = quantity * unitPrice
            
            totalHT += lineTotal
            vatByRate[vatRate, default: 0] += lineTotal * vatRate
            
            // Draw item data
            let description = item.itemDescription ?? "Article"
            drawText(description, at: CGPoint(x: margin + 5, y: yPos - 15), font: bodyFont, color: .black, in: context)
            drawText(String(format: "%.1f", quantity), at: CGPoint(x: margin + 250, y: yPos - 15), font: bodyFont, color: .black, in: context)
            drawText(String(format: "%.2f €", unitPrice), at: CGPoint(x: margin + 300, y: yPos - 15), font: bodyFont, color: .black, in: context)
            drawText(String(format: "%.0f%%", item.taxRate), at: CGPoint(x: margin + 370, y: yPos - 15), font: bodyFont, color: .black, in: context)
            drawText(String(format: "%.2f €", lineTotal), at: CGPoint(x: margin + 420, y: yPos - 15), font: bodyFont, color: .black, in: context)
            
            yPos -= 25
        }
        
        // Totals section
        yPos -= 30
        let totalsX = pageRect.width - 250
        
        // Total HT
        drawText("Total HT:", at: CGPoint(x: totalsX, y: yPos), font: headerFont, color: .black, in: context)
        drawText(String(format: "%.2f €", totalHT), at: CGPoint(x: totalsX + 100, y: yPos), font: headerFont, color: .black, in: context)
        yPos -= 20
        
        // VAT by rate
        for (rate, amount) in vatByRate.sorted(by: { $0.key < $1.key }) {
            let ratePercent = Int(rate * 100)
            drawText("TVA \(ratePercent)%:", at: CGPoint(x: totalsX, y: yPos), font: bodyFont, color: .black, in: context)
            drawText(String(format: "%.2f €", amount), at: CGPoint(x: totalsX + 100, y: yPos), font: bodyFont, color: .black, in: context)
            yPos -= 18
        }
        
        // Total TTC
        let totalVAT = vatByRate.values.reduce(0, +)
        let totalTTC = totalHT + totalVAT
        
        yPos -= 10
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        context.fill(CGRect(x: totalsX - 10, y: yPos - 20, width: 200, height: 25))
        
        drawText("TOTAL TTC:", at: CGPoint(x: totalsX, y: yPos - 15), font: headerFont, color: .white, in: context)
        drawText(String(format: "%.2f €", totalTTC), at: CGPoint(x: totalsX + 100, y: yPos - 15), font: headerFont, color: .white, in: context)
    }
    
    private static func drawText(_ text: String, at point: CGPoint, font: NSFont, color: NSColor, in context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        // Draw text using NSString
        (text as NSString).draw(at: point, withAttributes: attributes)
    }
}

// MARK: - Simple PDF SwiftUI View
struct SimplePDFView: View {
    let document: Document
    
    private var lineItems: [LineItem] {
        guard let items = document.lineItems?.allObjects as? [LineItem] else { return [] }
        return items.filter { !$0.isDeleted }.sorted { $0.position < $1.position }
    }
    
    private var calculations: (totalHT: Double, vatByRate: [Double: Double], totalTTC: Double) {
        var totalHT: Double = 0
        var vatByRate: [Double: Double] = [:]
        
        for item in lineItems {
            let quantity = item.quantity?.doubleValue ?? 0
            let unitPrice = item.unitPrice?.doubleValue ?? 0
            let vatRate = item.taxRate / 100.0
            let lineTotal = quantity * unitPrice
            
            totalHT += lineTotal
            vatByRate[vatRate, default: 0] += lineTotal * vatRate
        }
        
        let totalVAT = vatByRate.values.reduce(0, +)
        return (totalHT, vatByRate, totalHT + totalVAT)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color.blue
                HStack {
                    Text(document.safeOwnerField("companyName").isEmpty ? "Metta Concept" : document.safeOwnerField("companyName"))
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                    
                    Spacer()
                    
                    Text(document.type?.lowercased() == "invoice" ? "FACTURE" : "DEVIS")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                }
                .padding()
            }
            .frame(height: 80)
            
            // Document info
            VStack(spacing: 10) {
                HStack {
                    Text("N° \(document.number ?? "2024-001")")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Date: \(document.issueDate ?? Date(), formatter: dateFormatter)")
                        .font(.body)
                }
                .padding(.horizontal)
                
                // Company and Client
                HStack(alignment: .top, spacing: 40) {
                    // Company
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ÉMETTEUR")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(document.safeOwnerField("companyName"))
                            .font(.body)
                        Text(document.safeOwnerField("companyAddress"))
                            .font(.body)
                        Text(document.safeOwnerField("companyCity"))
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Client
                    VStack(alignment: .leading, spacing: 5) {
                        Text("CLIENT")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        if let client = document.safeClient {
                            Text(client.name ?? "")
                                .font(.body)
                            Text(client.address ?? "")
                                .font(.body)
                            Text("\(client.postalCode ?? "") \(client.city ?? "")")
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
            
            // Items table
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Description")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Qté")
                        .frame(width: 60)
                    Text("P.U. HT")
                        .frame(width: 80)
                    Text("TVA")
                        .frame(width: 60)
                    Text("Total HT")
                        .frame(width: 80)
                }
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .font(.headline)
                
                // Items
                ForEach(Array(lineItems.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        Text(item.itemDescription ?? "Article")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(item.quantity?.doubleValue ?? 0, specifier: "%.1f")")
                            .frame(width: 60)
                        Text("\(item.unitPrice?.doubleValue ?? 0, specifier: "%.2f") €")
                            .frame(width: 80)
                        Text("\(item.taxRate, specifier: "%.0f")%")
                            .frame(width: 60)
                        Text("\((item.quantity?.doubleValue ?? 0) * (item.unitPrice?.doubleValue ?? 0), specifier: "%.2f") €")
                            .frame(width: 80)
                    }
                    .padding(.vertical, 6)
                    .background(index % 2 == 0 ? Color.clear : Color.gray.opacity(0.1))
                    .font(.body)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Totals
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text("Total HT:")
                    Text("\(calculations.totalHT, specifier: "%.2f") €")
                        .frame(width: 100, alignment: .trailing)
                }
                
                ForEach(Array(calculations.vatByRate.sorted(by: { $0.key < $1.key })), id: \.key) { rate, amount in
                    HStack {
                        Text("TVA \(Int(rate * 100))%:")
                        Text("\(amount, specifier: "%.2f") €")
                            .frame(width: 100, alignment: .trailing)
                    }
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Text("TOTAL TTC:")
                        .bold()
                    Text("\(calculations.totalTTC, specifier: "%.2f") €")
                        .bold()
                        .frame(width: 100, alignment: .trailing)
                }
                .padding(8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Spacer()
        }
        .frame(width: 595, height: 842)
        .background(Color.white)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}
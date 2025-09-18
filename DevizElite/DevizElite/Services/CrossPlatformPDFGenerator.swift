import SwiftUI
import PDFKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Cross-Platform PDF Generator pentru macOS/iOS BTP
class CrossPlatformPDFGenerator {
    // Dimensiuni A4 standard
    static let pageWidth: CGFloat = 595.0
    static let pageHeight: CGFloat = 842.0
    static let margins = EdgeInsets(top: 30, leading: 30, bottom: 30, trailing: 30)
    
    static func generatePDF(document: Document) -> Data? {
        #if os(iOS)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        return renderer.pdfData { context in
            context.beginPage()
            let ctx = context.cgContext
            drawPDFContent(in: ctx, document: document)
        }
        #else
        // macOS implementation
        let pdfData = NSMutableData()
        let consumer = CGDataConsumer(data: pdfData as CFMutableData)!
        
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
        
        context.beginPDFPage(nil)
        drawPDFContent(in: context, document: document)
        context.endPDFPage()
        context.closePDF()
        
        return pdfData as Data
        #endif
    }
    
    // MARK: - Conținut PDF (cross-platform)
    static func drawPDFContent(in ctx: CGContext, document: Document) {
        // 1. HEADER cu logo vizibil și tip document
        drawHeader(ctx: ctx, document: document)
        
        // 2. Info Émetteur și Client în 2 coloane SEPARATE
        drawCompanyAndClient(ctx: ctx, document: document)
        
        // 3. Informations Chantier editabile
        drawChantierInfo(ctx: ctx, document: document)
        
        // 4. Tabel pe TOATĂ lățimea cu calcule CORECTE
        let totals = drawItemsTable(ctx: ctx, document: document)
        
        // 5. Totale calculate CORECT
        drawTotals(ctx: ctx, totals: totals)
        
        // 6. Footer cu mentions légales
        drawFooter(ctx: ctx, document: document)
    }
    
    // MARK: - Header cu logo VIZIBIL
    static func drawHeader(ctx: CGContext, document: Document) {
        let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: 90)
        
        // Gradient pentru vizibilitate mai bună
        let colors = [
            CGColor(red: 0.11, green: 0.38, blue: 0.65, alpha: 1.0),
            CGColor(red: 0.15, green: 0.42, blue: 0.70, alpha: 1.0)
        ]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, 
                                 colors: colors as CFArray, 
                                 locations: [0, 1])!
        
        ctx.saveGState()
        ctx.addRect(headerRect)
        ctx.clip()
        ctx.drawLinearGradient(gradient, 
                              start: CGPoint(x: 0, y: 0), 
                              end: CGPoint(x: pageWidth, y: 0), 
                              options: [])
        ctx.restoreGState()
        
        // Logo cu contrast mai bun
        let companyName = document.safeOwnerField("companyName")
        let displayName = companyName.isEmpty ? "Metta Concept" : companyName
        drawText(displayName, 
                at: CGPoint(x: margins.leading, y: 25),
                fontSize: 24,
                weight: .bold,
                color: .white,
                in: ctx)
        
        // Tip document (DEVIS sau FACTURE) - mai mare și mai vizibil
        let docType = document.type == "invoice" ? "FACTURE" : "DEVIS"
        let docColor = document.type == "invoice" ? Color.white : Color.orange
        
        // Măsoară textul pentru aliniere
        let typeSize = measureText(docType, fontSize: 36, weight: .heavy)
        drawText(docType,
                at: CGPoint(x: pageWidth - margins.trailing - typeSize.width, y: 20),
                fontSize: 36,
                weight: .heavy,
                color: docColor,
                in: ctx)
        
        // Număr și dată
        let numero = "N° \(document.number ?? "2024-001")"
        drawText(numero,
                at: CGPoint(x: pageWidth - margins.trailing - 150, y: 60),
                fontSize: 11,
                color: .white,
                in: ctx)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateFormat = "d MMMM yyyy"
        let dateStr = "Date : \(dateFormatter.string(from: document.issueDate ?? Date()))"
        drawText(dateStr,
                at: CGPoint(x: pageWidth - margins.trailing - 150, y: 75),
                fontSize: 11,
                color: .white,
                in: ctx)
    }
    
    // MARK: - Info Émetteur et Client FĂRĂ suprapunere
    static func drawCompanyAndClient(ctx: CGContext, document: Document) {
        let columnWidth = (pageWidth - margins.leading - margins.trailing - 20) / 2
        let yPosition: CGFloat = 110
        
        // ÉMETTEUR - coloană stânga
        let emetteurBox = CGRect(x: margins.leading, y: yPosition, 
                                 width: columnWidth, height: 120)
        ctx.setStrokeColor(CGColor(red: 0, green: 0.48, blue: 1.0, alpha: 1.0))
        ctx.setLineWidth(1.5)
        ctx.stroke(emetteurBox)
        
        drawText("ÉMETTEUR",
                at: CGPoint(x: margins.leading + 10, y: yPosition + 5),
                fontSize: 12,
                weight: .semibold,
                color: Color(red: 0, green: 0.48, blue: 1.0),
                in: ctx)
        
        // Date companie din Settings (User/Owner)
        var lineY = yPosition + 25
        let companyName = document.safeOwnerField("companyName")
        let companyAddress = document.safeOwnerField("companyAddress")
        let companyCity = document.safeOwnerField("companyCity")
        _ = document.safeOwnerField("companyPhone")
        let companyEmail = document.safeOwnerField("companyEmail")
        let companyTaxId = document.safeOwnerField("companyTaxId")
        
        drawText(companyName.isEmpty ? "Nom Entreprise" : companyName,
                at: CGPoint(x: margins.leading + 10, y: lineY),
                fontSize: 11,
                color: .black,
                in: ctx)
        
        lineY += 18
        if !companyAddress.isEmpty {
            drawText(companyAddress,
                    at: CGPoint(x: margins.leading + 10, y: lineY),
                    fontSize: 11,
                    color: .black,
                    in: ctx)
            lineY += 18
        }
        
        if !companyCity.isEmpty {
            drawText(companyCity,
                    at: CGPoint(x: margins.leading + 10, y: lineY),
                    fontSize: 11,
                    color: .black,
                    in: ctx)
            lineY += 18
        }
        
        if !companyEmail.isEmpty {
            drawText(companyEmail,
                    at: CGPoint(x: margins.leading + 10, y: lineY),
                    fontSize: 11,
                    color: .black,
                    in: ctx)
            lineY += 18
        }
        
        if !companyTaxId.isEmpty {
            drawText("TVA Intra : \(companyTaxId)",
                    at: CGPoint(x: margins.leading + 10, y: lineY),
                    fontSize: 11,
                    color: .black,
                    in: ctx)
        }
        
        // CLIENT - coloană dreapta
        let clientBox = CGRect(x: margins.leading + columnWidth + 20, y: yPosition, 
                              width: columnWidth, height: 120)
        ctx.setStrokeColor(CGColor(red: 0, green: 0.48, blue: 1.0, alpha: 1.0))
        ctx.stroke(clientBox)
        
        drawText("CLIENT",
                at: CGPoint(x: margins.leading + columnWidth + 30, y: yPosition + 5),
                fontSize: 12,
                weight: .semibold,
                color: Color(red: 0, green: 0.48, blue: 1.0),
                in: ctx)
        
        lineY = yPosition + 25
        if let client = document.safeClient {
            drawText(client.name ?? "Nom Client",
                    at: CGPoint(x: margins.leading + columnWidth + 30, y: lineY),
                    fontSize: 11,
                    color: .black,
                    in: ctx)
            
            lineY += 18
            if let address = client.address, !address.isEmpty {
                drawText(address,
                        at: CGPoint(x: margins.leading + columnWidth + 30, y: lineY),
                        fontSize: 11,
                        color: .black,
                        in: ctx)
                lineY += 18
            }
            
            let postalCode = client.postalCode ?? ""
            let city = client.city ?? ""
            if !postalCode.isEmpty || !city.isEmpty {
                let clientCity = "\(postalCode) \(city)".trimmingCharacters(in: .whitespaces)
                drawText(clientCity,
                        at: CGPoint(x: margins.leading + columnWidth + 30, y: lineY),
                        fontSize: 11,
                        color: .black,
                        in: ctx)
                lineY += 18
            }
            
            if let email = client.contactEmail, !email.isEmpty {
                drawText(email,
                        at: CGPoint(x: margins.leading + columnWidth + 30, y: lineY),
                        fontSize: 11,
                        color: .black,
                        in: ctx)
            }
        }
    }
    
    // MARK: - Informații Chantier
    static func drawChantierInfo(ctx: CGContext, document: Document) {
        guard let siteAddress = document.siteAddress, !siteAddress.isEmpty else { return }
        
        let yPosition: CGFloat = 240
        let boxWidth = pageWidth - margins.leading - margins.trailing
        
        // Box pentru info chantier
        let chantierBox = CGRect(x: margins.leading, y: yPosition, width: boxWidth, height: 60)
        ctx.setFillColor(CGColor(red: 0, green: 0.48, blue: 1.0, alpha: 0.05))
        ctx.fill(chantierBox)
        ctx.setStrokeColor(CGColor(red: 0, green: 0.48, blue: 1.0, alpha: 1.0))
        ctx.setLineWidth(1)
        ctx.stroke(chantierBox)
        
        drawText("INFORMATIONS CHANTIER",
                at: CGPoint(x: margins.leading + 10, y: yPosition + 5),
                fontSize: 11,
                weight: .semibold,
                color: Color(red: 0, green: 0.48, blue: 1.0),
                in: ctx)
        
        var currentY = yPosition + 25
        drawText("Adresse : \(siteAddress)",
                at: CGPoint(x: margins.leading + 10, y: currentY),
                fontSize: 10,
                color: .black,
                in: ctx)
        
        currentY += 16
        if let projectName = document.projectName {
            drawText("Travaux : \(projectName)",
                    at: CGPoint(x: margins.leading + 10, y: currentY),
                    fontSize: 10,
                    color: .black,
                    in: ctx)
        }
    }
    
    // MARK: - Table des articles avec calculs CORRECTS
    static func drawItemsTable(ctx: CGContext, document: Document) -> TotalCalculation {
        let tableY: CGFloat = document.siteAddress?.isEmpty ?? true ? 250 : 310
        let tableWidth = pageWidth - margins.leading - margins.trailing
        
        // Colonnes proportionnelles
        let columns: [(title: String, width: CGFloat, align: TextAlignment)] = [
            ("Désignation", tableWidth * 0.4, .leading),
            ("Unité", tableWidth * 0.1, .center),
            ("Qté", tableWidth * 0.1, .center),
            ("P.U. HT", tableWidth * 0.15, .trailing),
            ("TVA", tableWidth * 0.1, .center),
            ("Total HT", tableWidth * 0.15, .trailing)
        ]
        
        // Header tabel
        ctx.setFillColor(CGColor(red: 0, green: 0.48, blue: 1.0, alpha: 1.0))
        ctx.fill(CGRect(x: margins.leading, y: tableY, width: tableWidth, height: 30))
        
        var xPos = margins.leading
        for column in columns {
            let rect = CGRect(x: xPos + 5, y: tableY + 8, 
                            width: column.width - 10, height: 20)
            drawTextInRect(column.title, in: rect,
                          fontSize: 11, weight: .semibold,
                          color: .white, alignment: column.align,
                          in: ctx)
            xPos += column.width
        }
        
        // Linii tabel cu calcule
        var yPos = tableY + 30
        var totalHT: Double = 0
        var totalsByVAT: [Double: Double] = [:]
        
        let lineItems = document.lineItems?.allObjects as? [LineItem] ?? []
        
        for (index, item) in lineItems.enumerated() {
            // Alternare culoare rânduri
            if index % 2 == 0 {
                ctx.setFillColor(CGColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0))
                ctx.fill(CGRect(x: margins.leading, y: yPos, width: tableWidth, height: 30))
            }
            
            xPos = margins.leading
            
            // Calculează totalul corect
            let quantity = item.quantity?.doubleValue ?? 0
            let unitPrice = item.unitPrice?.doubleValue ?? 0
            let vatRate = item.taxRate / 100.0
            let itemTotal = quantity * unitPrice
            let itemTVA = itemTotal * vatRate
            
            totalHT += itemTotal
            totalsByVAT[vatRate, default: 0] += itemTVA
            
            let values = [
                item.itemDescription ?? "",
                item.unit ?? "unité",
                String(format: "%.2f", quantity),
                String(format: "%.2f €", unitPrice),
                String(format: "%.0f%%", vatRate * 100),
                String(format: "%.2f €", itemTotal)
            ]
            
            for (i, column) in columns.enumerated() {
                let rect = CGRect(x: xPos + 5, y: yPos + 5, 
                                width: column.width - 10, height: 20)
                drawTextInRect(values[i], in: rect,
                              fontSize: 10, 
                              color: .black, 
                              alignment: column.align,
                              in: ctx)
                xPos += column.width
            }
            
            yPos += 30
        }
        
        let totalTVA = totalsByVAT.values.reduce(0, +)
        
        return TotalCalculation(
            subtotal: totalHT,
            tva: totalTVA,
            total: totalHT + totalTVA,
            vatDetails: totalsByVAT
        )
    }
    
    // MARK: - Afișare totale calculate
    static func drawTotals(ctx: CGContext, totals: TotalCalculation) {
        let totalsX = pageWidth - margins.trailing - 220
        var yPos: CGFloat = 520
        
        // Box pentru totale
        let totalsBox = CGRect(x: totalsX - 10, y: yPos - 10, width: 220, height: 120)
        ctx.setFillColor(CGColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0))
        ctx.fill(totalsBox)
        ctx.setStrokeColor(CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0))
        ctx.setLineWidth(1)
        ctx.stroke(totalsBox)
        
        // Total HT
        drawText("Total HT :",
                at: CGPoint(x: totalsX, y: yPos),
                fontSize: 11,
                color: Color.gray,
                in: ctx)
        drawText(String(format: "%.2f €", totals.subtotal),
                at: CGPoint(x: totalsX + 140, y: yPos),
                fontSize: 11,
                weight: .medium,
                color: .black,
                in: ctx)
        
        yPos += 20
        
        // TVA détaillée
        for (rate, amount) in totals.vatDetails {
            let ratePercent = Int(rate * 100)
            drawText("TVA \(ratePercent)% :",
                    at: CGPoint(x: totalsX, y: yPos),
                    fontSize: 11,
                    color: Color.gray,
                    in: ctx)
            drawText(String(format: "%.2f €", amount),
                    at: CGPoint(x: totalsX + 140, y: yPos),
                    fontSize: 11,
                    weight: .medium,
                    color: .black,
                    in: ctx)
            yPos += 20
        }
        
        yPos += 10
        
        // Total TTC - highlight
        ctx.setFillColor(CGColor(red: 0, green: 0.48, blue: 1.0, alpha: 1.0))
        ctx.fill(CGRect(x: totalsX - 10, y: yPos - 5, width: 220, height: 35))
        
        drawText("TOTAL TTC :",
                at: CGPoint(x: totalsX, y: yPos + 2),
                fontSize: 14,
                weight: .bold,
                color: .white,
                in: ctx)
        drawText(String(format: "%.2f €", totals.total),
                at: CGPoint(x: totalsX + 120, y: yPos + 2),
                fontSize: 14,
                weight: .bold,
                color: .white,
                in: ctx)
    }
    
    // MARK: - Footer avec mentions légales
    static func drawFooter(ctx: CGContext, document: Document) {
        let footerY = pageHeight - 100
        
        // Ligne de séparation
        ctx.setStrokeColor(CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margins.leading, y: footerY))
        ctx.addLine(to: CGPoint(x: pageWidth - margins.trailing, y: footerY))
        ctx.strokePath()
        
        var footerText = ""
        
        if document.type == "estimate" {
            footerText = """
            Devis valable 30 jours. Prix fermes et non révisables.
            Acompte de 30% à la commande. Le solde à la fin des travaux.
            """
        } else {
            footerText = """
            Facture payable à réception. En cas de retard de paiement, une pénalité de 3 fois le taux d'intérêt légal sera appliquée.
            Pas d'escompte pour paiement anticipé.
            """
        }
        
        let footerRect = CGRect(x: margins.leading, y: footerY + 10, 
                               width: pageWidth - margins.leading - margins.trailing, 
                               height: 80)
        drawTextInRect(footerText, in: footerRect,
                      fontSize: 8,
                      color: Color.gray,
                      alignment: .center,
                      in: ctx)
    }
    
    // MARK: - Helper Functions for Cross-Platform Text Drawing
    
    enum TextAlignment {
        case leading, center, trailing
    }
    
    static func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, 
                        weight: Font.Weight = .regular, color: Color, in context: CGContext) {
        #if os(iOS)
        let font = UIFont.systemFont(ofSize: fontSize, weight: uiFontWeight(from: weight))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(color)
        ]
        text.draw(at: point, withAttributes: attributes)
        #else
        let font = NSFont.systemFont(ofSize: fontSize, weight: nsFontWeight(from: weight))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(color)
        ]
        text.draw(at: point, withAttributes: attributes)
        #endif
    }
    
    static func drawTextInRect(_ text: String, in rect: CGRect, fontSize: CGFloat, 
                              weight: Font.Weight = .regular, color: Color, 
                              alignment: TextAlignment = .leading, in context: CGContext) {
        #if os(iOS)
        let paragraphStyle = NSMutableParagraphStyle()
        switch alignment {
        case .leading: paragraphStyle.alignment = .left
        case .center: paragraphStyle.alignment = .center
        case .trailing: paragraphStyle.alignment = .right
        }
        
        let font = UIFont.systemFont(ofSize: fontSize, weight: uiFontWeight(from: weight))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(color),
            .paragraphStyle: paragraphStyle
        ]
        text.draw(in: rect, withAttributes: attributes)
        #else
        let paragraphStyle = NSMutableParagraphStyle()
        switch alignment {
        case .leading: paragraphStyle.alignment = .left
        case .center: paragraphStyle.alignment = .center
        case .trailing: paragraphStyle.alignment = .right
        }
        
        let font = NSFont.systemFont(ofSize: fontSize, weight: nsFontWeight(from: weight))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(color),
            .paragraphStyle: paragraphStyle
        ]
        text.draw(in: rect, withAttributes: attributes)
        #endif
    }
    
    static func measureText(_ text: String, fontSize: CGFloat, weight: Font.Weight = .regular) -> CGSize {
        #if os(iOS)
        let font = UIFont.systemFont(ofSize: fontSize, weight: uiFontWeight(from: weight))
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return text.size(withAttributes: attributes)
        #else
        let font = NSFont.systemFont(ofSize: fontSize, weight: nsFontWeight(from: weight))
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return text.size(withAttributes: attributes)
        #endif
    }
    
    #if os(iOS)
    static func uiFontWeight(from weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
    #else
    static func nsFontWeight(from weight: Font.Weight) -> NSFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
    #endif
}

// Structure pentru calcule
struct TotalCalculation {
    let subtotal: Double
    let tva: Double
    let total: Double
    let vatDetails: [Double: Double] // Rate: Amount
}

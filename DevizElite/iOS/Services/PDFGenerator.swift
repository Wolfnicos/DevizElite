import UIKit
import PDFKit

// MARK: - PDF Generator pentru iOS BTP
class PDFGenerator {
    // Dimensiuni A4 standard
    static let pageWidth: CGFloat = 595.0
    static let pageHeight: CGFloat = 842.0
    static let margins = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
    
    static func generatePDF(document: Document) -> Data? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        return renderer.pdfData { context in
            context.beginPage()
            let ctx = context.cgContext
            
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
    }
    
    // MARK: - Header cu logo VIZIBIL
    static func drawHeader(ctx: CGContext, document: Document) {
        // Bandeau colorat cu gradient
        let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: 90)
        
        // Gradient pentru vizibilitate mai bună
        let colors = [
            UIColor(red: 0.11, green: 0.38, blue: 0.65, alpha: 1.0).cgColor,
            UIColor(red: 0.15, green: 0.42, blue: 0.70, alpha: 1.0).cgColor
        ]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), 
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
        let logoAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor(white: 0, alpha: 0.3),
            .strokeWidth: -1.0 // Contur pentru lizibilitate
        ]
        
        let logo = NSAttributedString(string: document.company.name, attributes: logoAttrs)
        logo.draw(at: CGPoint(x: margins.left, y: 25))
        
        // Tip document (DEVIS sau FACTURE) - mai mare și mai vizibil
        let docTypeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .heavy),
            .foregroundColor: document.type == .devis ? UIColor.orange : UIColor.white
        ]
        
        let docType = document.type.rawValue
        let typeSize = docType.size(withAttributes: docTypeAttrs)
        let docTypeText = NSAttributedString(string: docType, attributes: docTypeAttrs)
        docTypeText.draw(at: CGPoint(x: pageWidth - margins.right - typeSize.width, y: 20))
        
        // Numéro și dată sub tipul documentului
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.white
        ]
        
        let numero = "N° \(document.number)"
        numero.draw(at: CGPoint(x: pageWidth - margins.right - 150, y: 60), 
                   withAttributes: infoAttrs)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateFormat = "d MMMM yyyy"
        let dateStr = "Date : \(dateFormatter.string(from: document.date))"
        dateStr.draw(at: CGPoint(x: pageWidth - margins.right - 150, y: 75), 
                    withAttributes: infoAttrs)
    }
    
    // MARK: - Info Émetteur et Client FĂRĂ suprapunere
    static func drawCompanyAndClient(ctx: CGContext, document: Document) {
        let columnWidth = (pageWidth - margins.left - margins.right - 20) / 2
        var yPosition: CGFloat = 110
        
        // ÉMETTEUR - coloană stânga
        let emetteurBox = CGRect(x: margins.left, y: yPosition, 
                                 width: columnWidth, height: 120)
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(emetteurBox)
        
        // Titlu secțiune
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.systemBlue
        ]
        "ÉMETTEUR".draw(at: CGPoint(x: margins.left + 10, y: yPosition + 5), 
                       withAttributes: titleAttrs)
        
        // Date companie - FĂRĂ suprapunere
        let companyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        
        var lineY = yPosition + 25
        document.company.name.draw(at: CGPoint(x: margins.left + 10, y: lineY), 
                                  withAttributes: companyAttrs)
        
        lineY += 18
        document.company.address.draw(at: CGPoint(x: margins.left + 10, y: lineY), 
                                     withAttributes: companyAttrs)
        
        lineY += 18
        "\(document.company.postalCode) \(document.company.city)".draw(
            at: CGPoint(x: margins.left + 10, y: lineY), 
            withAttributes: companyAttrs)
        
        lineY += 18
        if let email = document.company.email {
            email.draw(at: CGPoint(x: margins.left + 10, y: lineY), 
                      withAttributes: companyAttrs)
        }
        
        lineY += 18
        if let tvaNumber = document.company.tvaNumber {
            "TVA Intra : \(tvaNumber)".draw(
                at: CGPoint(x: margins.left + 10, y: lineY), 
                withAttributes: companyAttrs)
        }
        
        // CLIENT - coloană dreapta
        let clientBox = CGRect(x: margins.left + columnWidth + 20, y: yPosition, 
                              width: columnWidth, height: 120)
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.stroke(clientBox)
        
        "CLIENT".draw(at: CGPoint(x: margins.left + columnWidth + 30, y: yPosition + 5), 
                     withAttributes: titleAttrs)
        
        lineY = yPosition + 25
        document.client.name.draw(at: CGPoint(x: margins.left + columnWidth + 30, y: lineY), 
                                 withAttributes: companyAttrs)
        
        lineY += 18
        if !document.client.address.isEmpty {
            document.client.address.draw(at: CGPoint(x: margins.left + columnWidth + 30, y: lineY), 
                                        withAttributes: companyAttrs)
            lineY += 18
        }
        
        "\(document.client.postalCode) \(document.client.city)".draw(
            at: CGPoint(x: margins.left + columnWidth + 30, y: lineY), 
            withAttributes: companyAttrs)
        
        lineY += 18
        if let email = document.client.email {
            email.draw(at: CGPoint(x: margins.left + columnWidth + 30, y: lineY), 
                      withAttributes: companyAttrs)
        }
    }
    
    // MARK: - Informații Chantier
    static func drawChantierInfo(ctx: CGContext, document: Document) {
        guard !document.chanterAddress.isEmpty || !document.workDescription.isEmpty else { return }
        
        let yPosition: CGFloat = 240
        let boxWidth = pageWidth - margins.left - margins.right
        
        // Box pentru info chantier
        let chantierBox = CGRect(x: margins.left, y: yPosition, width: boxWidth, height: 60)
        ctx.setFillColor(UIColor.systemBlue.withAlphaComponent(0.05).cgColor)
        ctx.fill(chantierBox)
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(chantierBox)
        
        // Titlu
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.systemBlue
        ]
        "INFORMATIONS CHANTIER".draw(at: CGPoint(x: margins.left + 10, y: yPosition + 5), 
                                     withAttributes: titleAttrs)
        
        // Info chantier
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        
        var currentY = yPosition + 25
        if !document.chanterAddress.isEmpty {
            let chantierText = "Adresse : \(document.chanterAddress), \(document.chanterPostalCode) \(document.chanterCity)"
            chantierText.draw(at: CGPoint(x: margins.left + 10, y: currentY), 
                             withAttributes: infoAttrs)
            currentY += 16
        }
        
        if !document.workDescription.isEmpty {
            "Travaux : \(document.workDescription)".draw(
                at: CGPoint(x: margins.left + 10, y: currentY), 
                withAttributes: infoAttrs)
        }
    }
    
    // MARK: - Tabel cu calcule CORECTE
    static func drawItemsTable(ctx: CGContext, document: Document) -> TotalCalculation {
        let tableY: CGFloat = document.chanterAddress.isEmpty ? 250 : 310
        let tableWidth = pageWidth - margins.left - margins.right
        
        // Coloane proporționale pentru tot conținutul
        let columns: [(title: String, width: CGFloat, align: NSTextAlignment)] = [
            ("Désignation", tableWidth * 0.4, .left),
            ("Unité", tableWidth * 0.1, .center),
            ("Qté", tableWidth * 0.1, .center),
            ("P.U. HT", tableWidth * 0.15, .right),
            ("TVA", tableWidth * 0.1, .center),
            ("Total HT", tableWidth * 0.15, .right)
        ]
        
        // Header tabel
        ctx.setFillColor(UIColor.systemBlue.cgColor)
        ctx.fill(CGRect(x: margins.left, y: tableY, width: tableWidth, height: 30))
        
        var xPos = margins.left
        for column in columns {
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            
            let rect = CGRect(x: xPos + 5, y: tableY + 8, 
                            width: column.width - 10, height: 20)
            column.title.draw(in: rect, withAttributes: headerAttrs)
            xPos += column.width
        }
        
        // Linii tabel cu calcule
        var yPos = tableY + 30
        var totalHT: Double = 0
        var totalsByVAT: [Double: Double] = [:]
        
        for (index, item) in document.items.enumerated() {
            // Alternare culoare rânduri
            if index % 2 == 0 {
                ctx.setFillColor(UIColor(white: 0.97, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: margins.left, y: yPos, width: tableWidth, height: 30))
            }
            
            xPos = margins.left
            
            // Calculează totalul corect
            let itemTotal = item.quantity * item.unitPrice
            let itemTVA = itemTotal * item.vatRate
            
            totalHT += itemTotal
            totalsByVAT[item.vatRate, default: 0] += itemTVA
            
            let values = [
                item.designation,
                item.unit,
                String(format: "%.2f", item.quantity),
                String(format: "%.2f €", item.unitPrice),
                String(format: "%.0f%%", item.vatRate * 100),
                String(format: "%.2f €", itemTotal)
            ]
            
            for (i, column) in columns.enumerated() {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
                
                let rect = CGRect(x: xPos + 5, y: yPos + 5, 
                                width: column.width - 10, height: 20)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = column.align
                
                var drawAttrs = attrs
                drawAttrs[.paragraphStyle] = paragraphStyle
                
                values[i].draw(in: rect, withAttributes: drawAttrs)
                xPos += column.width
            }
            
            // Description sur ligne suivante si existante
            if let description = item.description, !description.isEmpty {
                yPos += 25
                let descAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor.gray
                ]
                let descRect = CGRect(x: margins.left + 10, y: yPos + 3, 
                                     width: tableWidth * 0.6, height: 20)
                description.draw(in: descRect, withAttributes: descAttrs)
                yPos += 5
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
        let totalsX = pageWidth - margins.right - 220
        var yPos: CGFloat = 520
        
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]
        
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        
        // Box pentru totale
        let totalsBox = CGRect(x: totalsX - 10, y: yPos - 10, width: 220, height: 120)
        ctx.setFillColor(UIColor(white: 0.98, alpha: 1.0).cgColor)
        ctx.fill(totalsBox)
        ctx.setStrokeColor(UIColor.systemGray3.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(totalsBox)
        
        // Total HT
        "Total HT :".draw(at: CGPoint(x: totalsX, y: yPos), withAttributes: labelAttrs)
        String(format: "%.2f €", totals.subtotal).draw(
            at: CGPoint(x: totalsX + 140, y: yPos), 
            withAttributes: valueAttrs)
        
        yPos += 20
        
        // TVA détaillée
        for (rate, amount) in totals.vatDetails {
            let ratePercent = Int(rate * 100)
            "TVA \(ratePercent)% :".draw(at: CGPoint(x: totalsX, y: yPos), 
                                         withAttributes: labelAttrs)
            String(format: "%.2f €", amount).draw(
                at: CGPoint(x: totalsX + 140, y: yPos), 
                withAttributes: valueAttrs)
            yPos += 20
        }
        
        yPos += 10
        
        // Total TTC - highlight
        ctx.setFillColor(UIColor.systemBlue.cgColor)
        ctx.fill(CGRect(x: totalsX - 10, y: yPos - 5, width: 220, height: 35))
        
        let ttcAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        "TOTAL TTC :".draw(at: CGPoint(x: totalsX, y: yPos + 2), withAttributes: ttcAttrs)
        String(format: "%.2f €", totals.total).draw(
            at: CGPoint(x: totalsX + 120, y: yPos + 2), 
            withAttributes: ttcAttrs)
    }
    
    // MARK: - Footer avec mentions légales
    static func drawFooter(ctx: CGContext, document: Document) {
        let footerY = pageHeight - 100
        
        // Ligne de séparation
        ctx.setStrokeColor(UIColor.systemGray4.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margins.left, y: footerY))
        ctx.addLine(to: CGPoint(x: pageWidth - margins.right, y: footerY))
        ctx.strokePath()
        
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.gray
        ]
        
        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = .center
        
        var footerText = ""
        
        if document.type == .devis {
            footerText = """
            Devis valable \(document.validityDays) jours. Prix fermes et non révisables.
            Acompte de 30% à la commande. Le solde à la fin des travaux.
            """
        } else {
            footerText = """
            Facture payable à réception. En cas de retard de paiement, une pénalité de 3 fois le taux d'intérêt légal sera appliquée.
            Pas d'escompte pour paiement anticipé.
            """
        }
        
        if let siret = document.company.siret {
            footerText += "\nSIRET : \(siret)"
        }
        
        if let rcs = document.company.registreCommerce {
            footerText += " - \(rcs)"
        }
        
        var attrs = footerAttrs
        attrs[.paragraphStyle] = centerStyle
        
        let footerRect = CGRect(x: margins.left, y: footerY + 10, 
                               width: pageWidth - margins.left - margins.right, 
                               height: 80)
        footerText.draw(in: footerRect, withAttributes: attrs)
    }
}

// MARK: - Structure pour calculs
struct TotalCalculation {
    let subtotal: Double
    let tva: Double
    let total: Double
    let vatDetails: [Double: Double] // Rate: Amount
}
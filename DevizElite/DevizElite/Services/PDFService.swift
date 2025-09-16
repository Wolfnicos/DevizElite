import Foundation
import PDFKit
import SwiftUI

final class PDFService {
    static let shared = PDFService()

    @MainActor
    func generatePDF(for document: Document, in view: NSView? = nil) throws -> Data {
        let pdf = PDFDocument()
        let page = PDFPage(image: renderImage(for: document))
        if let page = page {
            pdf.insert(page, at: 0)
        }
        guard let data = pdf.dataRepresentation() else { throw NSError(domain: "PDF", code: -1) }
        return data
    }

    @MainActor
    private func renderImage(for document: Document) -> NSImage {
        let styleRaw = UserDefaults.standard.string(forKey: "templateStyle") ?? TemplateStyle.Classic.rawValue
        let style = TemplateStyle(rawValue: styleRaw) ?? .Classic
        let renderer = ImageRenderer(content: AnyView(templateView(for: style, document: document)).frame(width: 595, height: 842))
        let size = NSSize(width: 595, height: 842)
        let image = NSImage(size: size)
        image.lockFocus()
        renderer.nsImage?.draw(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }

    @ViewBuilder
    private func templateView(for style: TemplateStyle, document: Document) -> some View {
        if document.type == "invoice" {
            switch style {
            case .Classic: ClassicTemplate(document: document)
            case .Modern: ModernTemplate(document: document)
            case .Minimal: MinimalTemplate(document: document)
            case .FRModernInvoice: FRModernInvoiceTemplate(document: document)
            case .BEProfessionalInvoice: BEProfessionalInvoiceTemplate(document: document)
            case .FRModernQuote, .BEProfessionalQuote: ClassicTemplate(document: document)
            case .BTP2025Invoice: BTP2025InvoiceTemplate(document: document)
            case .BTP2025Quote: ClassicTemplate(document: document)
            }
        } else { // estimate
            switch style {
            case .Classic: EstimateClassicTemplate(document: document)
            case .Modern: EstimateModernTemplate(document: document)
            case .Minimal: EstimateMinimalTemplate(document: document)
            case .FRModernQuote: FRModernQuoteTemplate(document: document)
            case .BEProfessionalQuote: BEProfessionalQuoteTemplate(document: document)
            case .FRModernInvoice, .BEProfessionalInvoice: EstimateClassicTemplate(document: document)
            case .BTP2025Quote: BTP2025QuoteTemplate(document: document)
            case .BTP2025Invoice: EstimateClassicTemplate(document: document)
            }
        }
    }

    // Helper for live preview embedding
    @ViewBuilder
    func sharedView(for style: TemplateStyle, document: Document) -> some View {
        AnyView(templateView(for: style, document: document))
    }
}

private struct ClassicTemplate: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HeaderSection(document: document)
            PartySection(document: document)
            Divider()
            LineItemsTable(document: document)
            Spacer(minLength: 8)
            TotalsFooter(document: document)
            if let notes = document.notes, !notes.isEmpty { Divider(); Text(notes).font(.footnote) }
        }.padding(24)
    }
}

private struct ModernTemplate: View {
    let document: Document
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.08), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 16) {
                HeaderSection(document: document)
                PartySection(document: document)
                LineItemsTable(document: document)
                Spacer()
                TotalsFooter(document: document)
            }
            .padding(28)
        }
    }
}

private struct MinimalTemplate: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HeaderSection(document: document)
            PartySection(document: document)
            LineItemsTable(document: document)
            Spacer()
            TotalsFooter(document: document)
        }
        .padding(22)
    }
}

// MARK: - Estimate variants (can diverge in headings/colors later)
private struct EstimateClassicTemplate: View {
    let document: Document
    var body: some View {
        ClassicTemplate(document: document)
    }
}

private struct EstimateModernTemplate: View {
    let document: Document
    var body: some View { ModernTemplate(document: document) }
}

private struct EstimateMinimalTemplate: View {
    let document: Document
    var body: some View { MinimalTemplate(document: document) }
}

// MARK: - Header & Party sections shared by templates
private struct HeaderSection: View {
    let document: Document
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(document.type == "estimate" ? L10n.t("Estimate") : L10n.t("Invoice")).font(.largeTitle).bold()
                HStack { Text(L10n.t("Number") + ":").foregroundColor(.secondary); Text(document.number ?? "-") }
                HStack { Text(L10n.t("Issue Date") + ":").foregroundColor(.secondary); Text(formatDate(document.issueDate)) }
            }
            Spacer()
            if let user = document.safeOwnerObject ?? (try? document.managedObjectContext?.fetch(NSFetchRequest<User>(entityName: "User")).first) ?? nil {
                VStack(alignment: .trailing, spacing: 4) {
                    if let data = user.logoData, let img = NSImage(data: data) {
                        Image(nsImage: img).resizable().frame(width: 80, height: 80).cornerRadius(8)
                    }
                    if let name = user.companyName, !name.isEmpty { Text(name).bold() }
                    if let address = user.companyAddress, !address.isEmpty { Text(address).multilineTextAlignment(.trailing) }
                    if let tax = user.taxId, !tax.isEmpty { Text("VAT: \(tax)").foregroundColor(.secondary) }
                }
            }
        }
    }
}

private struct PartySection: View {
    let document: Document
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("Bill From")).font(.subheadline).foregroundColor(.secondary)
                if let user = try? document.managedObjectContext?.fetch(NSFetchRequest<User>(entityName: "User")).first {
                    if let name = user.companyName { Text(name) }
                    if let address = user.companyAddress, !address.isEmpty { Text(address) }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(L10n.t("Bill To")).font(.subheadline).foregroundColor(.secondary)
                Text(clientField(document, "name"))
                let addr = clientField(document, "address")
                if !addr.isEmpty { Text(addr).multilineTextAlignment(.trailing) }
                let city = clientField(document, "city")
                if !city.isEmpty { Text(city) }
                let country = clientField(document, "country")
                if !country.isEmpty { Text(country) }
            }
        }
    }
}

// Defensive accessor that works whether 'client' is to-one or to-many by mistake
private func clientField(_ document: Document, _ key: String) -> String {
    if let c = document.safeClient { return c.value(forKey: key) as? String ?? "" }
    if let set = document.value(forKey: "client") as? NSSet, let any = set.anyObject() as? Client {
        return any.value(forKey: key) as? String ?? ""
    }
    return ""
}

private struct LineItemsTable: View {
    let document: Document
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(L10n.t("Description")).bold(); Spacer();
                Text(L10n.t("Qty")).bold().frame(width: 50)
                Text(L10n.t("Unit")).bold().frame(width: 60)
                Text(L10n.t("Unit Price")).bold().frame(width: 90)
                Text(L10n.t("Discount %")).bold().frame(width: 80)
                Text(L10n.t("Tax %")).bold().frame(width: 60)
                Text(L10n.t("Total")).bold().frame(width: 100, alignment: .trailing)
            }
            Divider()
            ForEach(sortedLineItems(document), id: \.id) { li in
                HStack {
                    Text(li.itemDescription ?? ""); Spacer()
                    Text(formatQty(li.quantity)).frame(width: 50)
                    Text((li.value(forKey: "unit") as? String) ?? "").frame(width: 60)
                    Text(formatCurrency(li.unitPrice, code: document.currencyCode ?? "USD")).frame(width: 90)
                    Text(String(format: "%.1f", li.discount)).frame(width: 80)
                    Text(String(format: "%.1f", li.taxRate)).frame(width: 60)
                    Text(formatCurrency(lineTotal(li), code: document.currencyCode ?? "USD")).frame(width: 100, alignment: .trailing)
                }
            }
        }
    }

    private func sortedLineItems(_ document: Document) -> [LineItem] {
        let set = (document.lineItems as? Set<LineItem>) ?? []
        return set.sorted { $0.position < $1.position }
    }
}

private struct TotalsFooter: View {
    let document: Document
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack { Spacer(); Text(L10n.t("Subtotal") + ":"); Text(formatCurrency(document.subtotal, code: document.currencyCode ?? "USD")).frame(width: 140, alignment: .trailing) }
            HStack { Spacer(); Text(L10n.t("Tax") + ":"); Text(formatCurrency(document.taxTotal, code: document.currencyCode ?? "USD")).frame(width: 140, alignment: .trailing) }
            Divider()
            HStack { Spacer(); Text(L10n.t("Total") + ":").bold(); Text(formatCurrency(document.total, code: document.currencyCode ?? "USD")).bold().frame(width: 140, alignment: .trailing) }
        }
    }
}

private func formatCurrency(_ value: NSDecimalNumber?, code: String) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = code
    return f.string(from: value ?? 0) ?? "0"
}

private func formatQty(_ value: NSDecimalNumber?) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.maximumFractionDigits = 2
    return f.string(from: value ?? 0) ?? "0"
}

private func lineTotal(_ li: LineItem) -> NSDecimalNumber {
    let qty = (li.quantity as NSDecimalNumber?) ?? 0
    let unit = li.unitPrice ?? 0
    let line = qty.multiplying(by: unit)
    // apply discount
    let discountRate = NSDecimalNumber(value: max(0, min(100, li.discount)))
    let discounted = line.multiplying(by: NSDecimalNumber(value: 1)).subtracting(line.multiplying(by: discountRate).dividing(by: 100))
    let tax = discounted.multiplying(by: NSDecimalNumber(value: li.taxRate)).dividing(by: 100)
    return discounted.adding(tax)
}

private func formatDate(_ date: Date?) -> String {
    let f = DateFormatter()
    f.dateStyle = .medium
    return f.string(from: date ?? Date())
}

// MARK: - France / Belgium Templates
private struct FRModernInvoiceTemplate: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HeaderSection(document: document)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ÉMETTEUR").font(.caption).foregroundColor(.secondary)
                    if let user = try? document.managedObjectContext?.fetch(NSFetchRequest<User>(entityName: "User")).first {
                        if let name = user.companyName { Text(name).bold() }
                        if let address = user.companyAddress, !address.isEmpty { Text(address) }
                        if let tax = user.taxId, !tax.isEmpty { Text("TVA: \(tax)").foregroundColor(.secondary) }
                        if let iban = user.iban, !iban.isEmpty { Text("IBAN: \(iban)").foregroundColor(.secondary) }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("CLIENT").font(.caption).foregroundColor(.secondary)
                    let name = clientField(document, "name")
                    if !name.isEmpty { Text(name).bold() }
                    let addr = clientField(document, "address"); if !addr.isEmpty { Text(addr).multilineTextAlignment(.trailing) }
                    let city = clientField(document, "city"); if !city.isEmpty { Text(city) }
                    let country = clientField(document, "country"); if !country.isEmpty { Text(country) }
                }
            }
            Divider()
            LineItemsTable(document: document)
            TotalsFooter(document: document)
            LegalFooter(document: document)
            if let notes = document.notes, !notes.isEmpty { Divider(); Text("Notes").font(.subheadline); Text(notes).font(.footnote) }
        }
        .padding(24)
    }
}

private struct BEProfessionalInvoiceTemplate: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.type == "estimate" ? "DEVIS" : "FACTURE").font(.largeTitle).bold()
                    HStack { Text("N°").foregroundColor(.secondary); Text(document.number ?? "-") }
                }
                Spacer()
                if let user = try? document.managedObjectContext?.fetch(NSFetchRequest<User>(entityName: "User")).first {
                    VStack(alignment: .trailing, spacing: 2) {
                        if let name = user.companyName { Text(name).bold() }
                        if let address = user.companyAddress, !address.isEmpty { Text(address) }
                        if let iban = user.iban, !iban.isEmpty { Text("IBAN: \(iban)") }
                        if let bank = user.bankName, !bank.isEmpty { Text("Banque: \(bank)") }
                        if let tax = user.taxId, !tax.isEmpty { Text("TVA: \(tax)") }
                    }
                }
            }
            Divider()
            PartySection(document: document)
            Divider()
            LineItemsTable(document: document)
            Spacer(minLength: 8)
            TotalsFooter(document: document)
            LegalFooter(document: document)
            Text("TVA 6% applicable sous conditions pour rénovations (>10 ans).").font(.footnote).foregroundColor(.secondary)
        }
        .padding(22)
    }
}

private struct FRModernQuoteTemplate: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderSection(document: document)
            PartySection(document: document)
            Divider()
            LineItemsTable(document: document)
            Spacer(minLength: 8)
            TotalsFooter(document: document)
            LegalFooter(document: document)
        }
        .padding(22)
    }
}

private struct BEProfessionalQuoteTemplate: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderSection(document: document)
            PartySection(document: document)
            Divider()
            LineItemsTable(document: document)
            Spacer(minLength: 8)
            TotalsFooter(document: document)
            LegalFooter(document: document)
        }
        .padding(22)
    }
}

// MARK: - Construction Legal/Footer
private struct LegalFooter: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let project = document.value(forKey: "projectName") as? String, !project.isEmpty {
                Text("Projet / Chantier: \(project)").font(.footnote)
            }
            if let site = document.value(forKey: "siteAddress") as? String, !site.isEmpty {
                Text("Adresse du chantier: \(site)").font(.footnote)
            }
            HStack(spacing: 12) {
                if let terms = document.value(forKey: "paymentTerms") as? String, !terms.isEmpty {
                    Text("Conditions de paiement: \(terms)").font(.footnote)
                }
                if let validity = document.value(forKey: "validityDays") as? Int16, validity > 0, document.type == "estimate" {
                    Text("Validité de l'offre: \(validity) jours").font(.footnote)
                }
                let retention = (document.value(forKey: "retentionPercent") as? Double) ?? 0
                if retention > 0 { Text(String(format: "Retenue de garantie: %.1f%%", retention)).font(.footnote) }
            }
            if document.type == "invoice" {
                Text("Pénalités de retard et indemnité forfaitaire selon la législation en vigueur.").font(.footnote).foregroundColor(.secondary)
            } else {
                Text("Prix en EUR. TVA selon législation. Planning et conditions détaillées sur demande.").font(.footnote).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - BTP 2025 Templates (FR)
private struct Card: View { let color: Color; let text: String; var body: some View { Text(text).font(.caption).bold().padding(.horizontal, 8).padding(.vertical, 4).background(color.opacity(0.1)).foregroundColor(color).clipShape(Capsule()) } }

// Shared palette and typography so Factures matches Devis exactly
private struct BTPTheme {
    // Exact palette to match the shared mockups
    static let primary = Color(hex: "0C66CC")
    static let primaryDark = Color(hex: "0A3F91")
    static let sectionBg = Color(hex: "F1F7FF")
    static let sectionStroke = Color(hex: "B5D6FF")
    static let tableHeaderText = Color.white
}

private enum BTPFont {
    // Sizes tuned to match the reference visuals
    static let title: Font = .system(size: 30, weight: .bold)
    static let company: Font = .system(size: 24, weight: .bold)
    static let sectionTitle: Font = .system(size: 16, weight: .semibold)
    static let tableHeader: Font = .system(size: 14, weight: .semibold)
    static let rowPrimary: Font = .system(size: 12, weight: .semibold)
    static let rowSecondary: Font = .system(size: 11, weight: .regular)
}

private struct BTPHeader: View {
    let document: Document
    let isQuote: Bool
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    // Company name from Settings (UserDefaults)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [BTPTheme.primary, BTPTheme.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 82, height: 82)
                        .overlay(Text(companyName()).font(.system(size: 16, weight: .bold)).foregroundColor(.white).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.6).padding(6))
                    VStack(alignment: .leading, spacing: 4) {
                        // Remove duplicate company name; keep only details
                        VStack(alignment: .leading, spacing: 2) {
                            if let vat = companyTaxId(), !vat.isEmpty { Text("TVA Intra: \(vat)").font(.footnote).foregroundColor(.secondary) }
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(isQuote ? "DEVIS" : "FACTURE").font(BTPFont.title).foregroundColor(isQuote ? Color(red: 1.0, green: 0.42, blue: 0.21) : BTPTheme.primary)
                    Text("N° \(document.number ?? "-")").font(.body).bold()
                    Text("Date : \(formatDate(document.issueDate))").font(.footnote).foregroundColor(.secondary)
                    if isQuote {
                        if let validity = document.value(forKey: "validityDays") as? Int16 { Text("Validité : \(validity) jours").font(.footnote).foregroundColor(.secondary) }
                    } else {
                        if let due = document.dueDate { Text("Échéance : \(formatDate(due))").font(.footnote).foregroundColor(.secondary) }
                    }
                }
            }
        }
        .padding(.bottom, 12)
        .overlay(Rectangle().frame(height: 3).foregroundColor(BTPTheme.primary), alignment: .bottom)
    }

    private func companyName() -> String { UserDefaults.standard.string(forKey: "companyName") ?? "" }
    private func companyTaxId() -> String? { UserDefaults.standard.string(forKey: "companyTaxId") }
}

private struct BTPParties: View {
    let document: Document
    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Émetteur").font(.subheadline).bold()
                VStack(alignment: .leading, spacing: 2) {
                    let name = UserDefaults.standard.string(forKey: "companyName") ?? ""
                    if !name.isEmpty { Text(name).bold() }
                    let addr = UserDefaults.standard.string(forKey: "companyAddress") ?? ""
                    if !addr.isEmpty { Text(addr) }
                    let iban = UserDefaults.standard.string(forKey: "companyIBAN") ?? ""
                    if !iban.isEmpty { Text("IBAN: \(iban)").foregroundColor(.secondary) }
                }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 6) {
                Text("Client").font(.subheadline).bold()
                VStack(alignment: .leading, spacing: 2) {
                    let name = clientField(document, "name"); if !name.isEmpty { Text(name).bold() }
                    let addr = clientField(document, "address"); if !addr.isEmpty { Text(addr) }
                    let city = clientField(document, "city"); if !city.isEmpty { Text(city) }
                    let country = clientField(document, "country"); if !country.isEmpty { Text(country) }
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .overlay(Rectangle().frame(width: 4).foregroundColor(.blue), alignment: .leading)
    }
}

private struct BTPProjectInfo: View {
    let document: Document
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) { Text(title).font(BTPFont.sectionTitle).foregroundColor(BTPTheme.primary); Text("🏗️") }
            VStack(alignment: .leading, spacing: 6) {
                gridRow("Adresse chantier", document.value(forKey: "siteAddress") as? String)
                gridRow("Nature des travaux", document.value(forKey: "projectName") as? String)
                gridRow("Période d'exécution", nil)
            }
        }
        .padding(12)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // expand first so background fills
        .background(LinearGradient(colors: [BTPTheme.sectionBg, Color(NSColor.windowBackgroundColor)] , startPoint: .leading, endPoint: .trailing))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BTPTheme.sectionStroke))
    }
    private func gridRow(_ label: String, _ value: String?) -> some View { HStack { Text("\(label) :").font(.body).foregroundColor(.secondary).frame(width: 180, alignment: .leading); Text(value ?? "-").font(.body) } }
}

private struct BTPItemsHeader: View { let isQuote: Bool; var body: some View { HStack {
    Text(isQuote ? "Description des travaux" : "Désignation des travaux").frame(width: 230, alignment: .leading).font(BTPFont.tableHeader).foregroundColor(BTPTheme.tableHeaderText)
    Text("Unité").frame(width: 60).font(BTPFont.tableHeader).foregroundColor(BTPTheme.tableHeaderText)
    Text("Quantité").frame(width: 70, alignment: .trailing).font(BTPFont.tableHeader).foregroundColor(BTPTheme.tableHeaderText)
    Text("P.U. HT (€)").frame(width: 90, alignment: .trailing).font(BTPFont.tableHeader).foregroundColor(BTPTheme.tableHeaderText)
    if !isQuote { Text("TVA").frame(width: 60).font(BTPFont.tableHeader).foregroundColor(BTPTheme.tableHeaderText) }
    Text(isQuote ? "Total HT (€)" : "Montant HT (€)").frame(width: isQuote ? 110 : 110, alignment: .trailing).font(BTPFont.tableHeader).foregroundColor(BTPTheme.tableHeaderText)
    if !isQuote { Text("Montant TTC (€)").frame(width: 120, alignment: .trailing).font(BTPFont.tableHeader).foregroundColor(BTPTheme.tableHeaderText) }
} } }

private struct BTPItemsTable: View {
    let document: Document
    let isQuote: Bool
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: [BTPTheme.primary, BTPTheme.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                BTPItemsHeader(isQuote: isQuote)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 0) {
                ForEach(sortedLineItems(document), id: \.id) { li in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(refText(li)).font(.caption).foregroundColor(BTPTheme.primary)
                            if let desc = li.itemDescription { Text(desc).font(BTPFont.rowPrimary).foregroundColor(Color(red: 0.17, green: 0.24, blue: 0.31)) }
                            if let det = detailText(li), !det.isEmpty { Text(det).font(BTPFont.rowSecondary).foregroundColor(.secondary) }
                        }.frame(width: 230, alignment: .leading)
                        Text((li.value(forKey: "unit") as? String) ?? "").frame(width: 60, alignment: .center)
                        Text(formatQty(li.quantity)).frame(width: 70, alignment: .trailing)
                        Text(formatCurrency(li.unitPrice, code: document.currencyCode ?? "EUR")).frame(width: 90, alignment: .trailing)
                        if !isQuote { Text(String(format: "%.0f%%", li.taxRate)).frame(width: 60) }
                        Text(formatCurrency(lineNet(li), code: document.currencyCode ?? "EUR")).frame(width: 110, alignment: .trailing)
                        if !isQuote { Text(formatCurrency(lineTotal(li), code: document.currencyCode ?? "EUR")).frame(width: 120, alignment: .trailing) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.white)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.15)), alignment: .bottom)
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func sortedLineItems(_ document: Document) -> [LineItem] { ((document.lineItems as? Set<LineItem>) ?? []).sorted { $0.position < $1.position } }
    private func refText(_ li: LineItem) -> String { "LOT \(String(format: "%02d", Int(li.position)))" }
    private func detailText(_ li: LineItem) -> String? { nil }
    private func lineNet(_ li: LineItem) -> NSDecimalNumber {
        let qty = (li.quantity as NSDecimalNumber?) ?? 0
        let unit = li.unitPrice ?? 0
        let line = qty.multiplying(by: unit)
        let discountRate = NSDecimalNumber(value: max(0, min(100, li.discount)))
        return line.subtracting(line.multiplying(by: discountRate).dividing(by: 100))
    }
}

// MARK: - Totals & Aux Sections used by Facture
private func _netAmount(_ li: LineItem) -> NSDecimalNumber {
    let qty = (li.quantity as NSDecimalNumber?) ?? 0
    let unit = li.unitPrice ?? 0
    let line = qty.multiplying(by: unit)
    let discountRate = NSDecimalNumber(value: max(0, min(100, li.discount)))
    return line.subtracting(line.multiplying(by: discountRate).dividing(by: 100))
}

private func _totalsByRate(_ document: Document) -> [(rate: Double, ht: NSDecimalNumber, tva: NSDecimalNumber)] {
    var map: [Double: (NSDecimalNumber, NSDecimalNumber)] = [:]
    let items = (document.lineItems as? Set<LineItem>) ?? []
    for li in items {
        let net = _netAmount(li)
        let rate = Double(li.taxRate)
        let tva = net.multiplying(by: NSDecimalNumber(value: rate)).dividing(by: 100)
        let current = map[rate] ?? (0, 0)
        map[rate] = (current.0.adding(net), current.1.adding(tva))
    }
    return map.keys.sorted().map { r in let pair = map[r]!; return (rate: r, ht: pair.0, tva: pair.1) }
}

private func _totalHT(_ document: Document) -> NSDecimalNumber { _totalsByRate(document).reduce(0) { $0.adding($1.ht) } }
private func _totalTVA(_ document: Document) -> NSDecimalNumber { _totalsByRate(document).reduce(0) { $0.adding($1.tva) } }
private func _totalTTC(_ document: Document) -> NSDecimalNumber { _totalHT(document).adding(_totalTVA(document)) }

private struct BTPTotalsBoxDetailed: View {
    let document: Document
    var body: some View {
        let rows = _totalsByRate(document)
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
                row("Total HT (TVA \(Int(r.rate))%) :", formatCurrency(r.ht, code: document.currencyCode ?? "EUR"), bg: Color(NSColor.windowBackgroundColor))
            }
            row("TOTAL HT :", formatCurrency(_totalHT(document), code: document.currencyCode ?? "EUR"), bg: Color(red: 0.89, green: 0.95, blue: 0.99), bold: true)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, r in
                row("TVA \(Int(r.rate))% :", formatCurrency(r.tva, code: document.currencyCode ?? "EUR"), bg: Color(red: 1.0, green: 0.95, blue: 0.80))
            }
            ZStack {
                LinearGradient(colors: [BTPTheme.primary, BTPTheme.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                HStack { Text("TOTAL TTC :").foregroundColor(.white).bold(); Spacer(); Text(formatCurrency(_totalTTC(document), code: document.currencyCode ?? "EUR")).foregroundColor(.white).bold() }.padding(12)
            }
        }
        .frame(width: 330)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(BTPTheme.primary, lineWidth: 2))
        .cornerRadius(10)
    }
    private func row(_ l: String, _ r: String, bg: Color, bold: Bool = false) -> some View { HStack { Text(l).font(.body).fontWeight(bold ? .bold : .regular); Spacer(); Text(r).font(.body).fontWeight(bold ? .bold : .regular) }.padding(10).background(bg).overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2)), alignment: .bottom) }
}

private struct BTPObservationsBox: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Observations").font(BTPFont.sectionTitle)
            if let notes = document.notes, !notes.isEmpty {
                Text(notes).font(.footnote)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Travaux réalisés selon DTU en vigueur")
                    Text("• Garantie décennale en cours de validité")
                    Text("• Matériaux conformes aux normes CE")
                    Text("• Nettoyage de fin de chantier inclus")
                    Text("• Photos avant/après disponibles sur demande")
                }.font(.footnote).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
    }
}

private struct BTPPaymentsBox: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Modalités de règlement").font(BTPFont.sectionTitle).foregroundColor(Color(red: 0.18, green: 0.49, blue: 0.25))
            VStack(alignment: .leading, spacing: 8) {
                if let due = document.dueDate { HStack(spacing: 10) { Text("📅"); Text("Échéance : \(formatDate(due))") }.font(.footnote) }
                let iban = UserDefaults.standard.string(forKey: "companyIBAN") ?? ""
                if !iban.isEmpty { HStack(spacing: 10) { Text("🏦"); Text("IBAN : \(iban)") }.font(.footnote) }
                HStack(spacing: 10) { Text("⚠️"); Text("Pénalités de retard : 3 × taux légal • Indemnité forfaitaire : 40 €") }.font(.footnote)
            }
        }
        .padding(14)
        .background(Color(red: 0.91, green: 0.96, blue: 0.92))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.51, green: 0.78, blue: 0.52)))
        .cornerRadius(10)
    }
}

private struct BTPLegalSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mentions légales et conditions générales").font(.subheadline).bold()
            VStack(alignment: .leading, spacing: 4) {
                Text("• Travaux réalisés conformément aux règles de l'art et DTU")
                Text("• Garantie de parfait achèvement : 1 an")
                Text("• Garantie biennale : 2 ans (équipements)")
                Text("• Garantie décennale : 10 ans (gros œuvre)")
                Text("• Escompte pour paiement anticipé : néant")
                Text("• En cas de retard : application article L441-10 C.Com")
                Text("• Réserve de propriété jusqu'au paiement intégral")
                Text("• Tribunal compétent : Tribunal de Commerce")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
    }
}

private struct BTP2025InvoiceTemplate: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BTPHeader(document: document, isQuote: false)
            BTPParties(document: document)
            BTPProjectInfo(document: document, title: "Informations Chantier")
                .frame(maxWidth: .infinity)
            BTPItemsTable(document: document, isQuote: false)
                .frame(maxWidth: .infinity)
            HStack(alignment: .top, spacing: 30) {
                BTPObservationsBox(document: document)
                Spacer()
                BTPTotalsBoxDetailed(document: document)
            }
            BTPPaymentsBox(document: document)
            BTPLegalSection()
        }
        .padding(EdgeInsets(top: 36, leading: 24, bottom: 24, trailing: 24))
    }
}

private struct BTP2025QuoteTemplate: View {
    let document: Document
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BTPHeader(document: document, isQuote: true)
            BTPParties(document: document)
            BTPProjectInfo(document: document, title: "Description du projet")
            BTPItemsTable(document: document, isQuote: true)
            HStack(alignment: .top, spacing: 22) {
                Spacer()
                BTPTotalsBoxDetailed(document: document)
            }
            BTPConditionsBox()
            BTPGuaranteesBox()
            BTPSignatureSection()
            BTPFooterQuote()
        }
        .padding(24)
    }
}

// MARK: - Quote sections implementation
private struct BTPOptionsBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("+ Options supplémentaires (non incluses)").font(BTPFont.sectionTitle).foregroundColor(Color(red: 0.07, green: 0.37, blue: 0.80))
            VStack(alignment: .leading, spacing: 4) {
                Text("• Pompe à chaleur air/eau Atlantic 11kW    8 500,00 € HT")
                Text("• Portail aluminium motorisé 4m           3 200,00 € HT")
                Text("• Pergola bioclimatique 20m²              12 000,00 € HT")
            }.font(.footnote)
        }
        .padding(14)
        .background(Color(red: 0.90, green: 0.95, blue: 1.0))
        .cornerRadius(12)
    }
}

private struct BTPPlanningBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Planning prévisionnel").font(BTPFont.sectionTitle)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Semaines 1-4 : Gros œuvre")
                    Text("Semaines 5-8 : Charpente, couverture")
                    Text("Semaines 9-11 : Second œuvre")
                    Text("Semaines 12 : Finitions, réception")
                }.font(.footnote)
                VStack { Spacer(); Text("Sous réserve conditions météo et autorisations").font(.caption).foregroundColor(.secondary) }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct BTPConditionsBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Conditions de réalisation").font(BTPFont.sectionTitle).foregroundColor(Color(red: 0.10, green: 0.50, blue: 0.26))
            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1  Acompte signature : 30%")
                    Text("3  Mi-parcours : 25%")
                }.font(.footnote)
                VStack(alignment: .leading, spacing: 6) {
                    Text("2  Début travaux : 35%")
                    Text("4  Réception : 10%")
                }.font(.footnote)
            }
        }
        .padding(14)
        .background(Color(red: 0.92, green: 0.98, blue: 0.94))
        .cornerRadius(12)
    }
}

private struct BTPGuaranteesBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nos garanties et engagements").font(BTPFont.sectionTitle).foregroundColor(Color(red: 0.10, green: 0.50, blue: 0.26))
            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("✓ Garantie décennale tous corps d'état")
                    Text("✓ Respect des délais contractuels")
                    Text("✓ Conducteur de travaux dédié")
                }.font(.footnote)
                VStack(alignment: .leading, spacing: 4) {
                    Text("✓ Assurance dommages-ouvrage proposée")
                    Text("✓ Certification RGE (aides fiscales possibles)")
                    Text("✓ Nettoyage quotidien du chantier")
                }.font(.footnote)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct BTPSignatureSection: View {
    var body: some View {
        HStack(alignment: .top, spacing: 60) {
            VStack { Text("Le Client").bold(); Spacer().frame(height: 32); Rectangle().frame(height: 1); Text("Précédé de 'Bon pour accord'\nDate et signature").font(.caption).foregroundColor(.secondary) }
            VStack { Text("L'Entreprise").bold(); Spacer().frame(height: 32); Rectangle().frame(height: 1); Text("Cachet entreprise").font(.caption).foregroundColor(.secondary) }
        }
        .padding(.vertical, 10)
    }
}

private struct BTPFooterQuote: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Validité du devis : 30 jours").font(.caption)
                .padding(8)
                .background(Color(red: 1.0, green: 0.94, blue: 0.84))
                .cornerRadius(6)
            // Contact line removed per request
        }
        .padding(.top, 6)
    }
}



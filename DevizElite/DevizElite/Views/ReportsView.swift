import SwiftUI
import CoreData
import Charts
import AppKit
import PDFKit
import UniformTypeIdentifiers

struct ReportsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Document.entity(), sortDescriptors: []) private var documents: FetchedResults<Document>

    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var currencyFilter: String = "ALL"

    private var currencyOptions: [String] {
        let codes = Set(simpleDocs.map { $0.currencyCode }).sorted()
        return ["ALL"] + codes
    }

    private struct SimpleLineItem { let description: String; let qty: Double; let unit: Double; let taxRate: Double }
    private struct SimpleDoc {
        let type: String
        let status: String
        let issueDate: Date?
        let dueDate: Date?
        let currencyCode: String
        let total: Double
        let clientName: String
        let items: [SimpleLineItem]
    }

    private var simpleDocs: [SimpleDoc] {
        Array(documents).map { d in
            let set = (d.lineItems as? Set<LineItem>) ?? []
            let items = set.map { li in
                let qty = ((li.quantity as NSDecimalNumber?) ?? 0).doubleValue
                let unit = (li.unitPrice ?? 0).doubleValue
                let rate = li.taxRate
                return SimpleLineItem(description: li.itemDescription ?? "", qty: qty, unit: unit, taxRate: rate)
            }
            return SimpleDoc(
                type: d.type ?? "",
                status: d.status ?? "",
                issueDate: d.issueDate,
                dueDate: d.dueDate,
                currencyCode: d.currencyCode ?? "",
                total: (d.total ?? 0).doubleValue,
                clientName: d.safeClientName,
                items: items
            )
        }
    }

    private var revenueByMonth: [(month: Date, total: Double)] {
        let paid = simpleDocs.filter { d in
            d.type == "invoice" && d.status == "paid" && d.issueDate != nil &&
            inRange(d.issueDate!) && currencyMatches(d)
        }
        let cal = Calendar.current
        var bucket: [Date: Double] = [:]
        for d in paid {
            if let date = d.issueDate, let m = cal.date(from: cal.dateComponents([.year, .month], from: date)) {
                bucket[m, default: 0] += d.total
            }
        }
        return bucket.keys.sorted().map { (month: $0, total: bucket[$0] ?? 0) }
    }

    private var unpaidSummary: (count: Int, amount: Double) {
        let list = simpleDocs.filter { d in
            d.type == "invoice" && d.status != "paid" && d.dueDate != nil &&
            inRange(d.dueDate!) && currencyMatches(d)
        }
        let amount = list.reduce(0) { $0 + max($1.total, 0) }
        return (list.count, amount)
    }

    private var topClients: [(name: String, amount: Double)] {
        var bucket: [String: Double] = [:]
        for d in simpleDocs where d.type == "invoice" && (d.issueDate.map(inRange) ?? false) && currencyMatches(d) {
            let name = d.clientName.isEmpty ? L10n.t("Unknown Client") : d.clientName
            bucket[name, default: 0] += d.total
        }
        let arr = bucket.map { (name: $0.key, amount: $0.value) }.sorted(by: { $0.amount > $1.amount })
        return Array(arr.prefix(5))
    }

    private var topProducts: [(name: String, amount: Double)] {
        var bucket: [String: Double] = [:]
        for d in simpleDocs where (d.issueDate.map(inRange) ?? false) && currencyMatches(d) {
            for li in d.items {
                let line = li.qty * li.unit
                let tax = line * (li.taxRate / 100)
                let total = line + tax
                let name = li.description.isEmpty ? L10n.t("Unknown Item") : li.description
                bucket[name, default: 0] += total
            }
        }
        let arr = bucket.map { (name: $0.key, amount: $0.value) }.sorted(by: { $0.amount > $1.amount })
        return Array(arr.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.t("Reports")).font(.largeTitle.bold())

                // Filters
                HStack(spacing: 12) {
                    DatePicker(L10n.t("From"), selection: $startDate, displayedComponents: .date)
                    DatePicker(L10n.t("To"), selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                    Picker(L10n.t("Currency Filter"), selection: $currencyFilter) {
                        Text(L10n.t("All Currencies")).tag("ALL")
                        ForEach(currencyOptions.filter { $0 != "ALL" }, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .frame(maxWidth: 220)
                    Spacer()
                }
                .themedCard()

                HStack(spacing: 12) {
                    Button(L10n.t("Export CSV")) { exportCSV() }
                    Button(L10n.t("Export PDF")) { exportPDF() }
                    Spacer()
                }
                .themedCard()

                // Revenue by Month
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Revenue by Month")).font(.headline)
                    if revenueByMonth.count > 0 {
                        Chart {
                            ForEach(revenueByMonth, id: \.month) { p in
                                BarMark(x: .value("Month", p.month), y: .value("Total", p.total))
                                    .foregroundStyle(UITheme.accentGreen)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month))
                        }
                        .frame(height: 200)
                    } else {
                        Text(L10n.t("No Data")).foregroundColor(.secondary)
                    }
                }
                .themedCard()

                // Unpaid Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Unpaid Summary")).font(.headline)
                    HStack {
                        Image(systemName: "dollarsign.circle").foregroundColor(UITheme.warningYellow)
                        Text("\(unpaidSummary.count) " + L10n.t("documents"))
                        Spacer()
                        Text(formatCurrency(NSDecimalNumber(value: unpaidSummary.amount), code: currentCurrencyCode)).font(.title3.bold())
                    }
                }
                .themedCard()

                // Top Clients
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Top Clients")).font(.headline)
                    if topClients.count > 0 {
                        Chart {
                            ForEach(topClients, id: \.name) { row in
                                BarMark(x: .value("Amount", row.amount), y: .value("Client", row.name))
                                    .foregroundStyle(UITheme.primaryBlue)
                            }
                        }
                        .frame(height: CGFloat(40 * max(3, topClients.count)))
                    } else {
                        Text(L10n.t("No Data")).foregroundColor(.secondary)
                    }
                }
                .themedCard()

                // Top Products
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("Top Products")).font(.headline)
                    if topProducts.count > 0 {
                        Chart {
                            ForEach(topProducts, id: \.name) { row in
                                BarMark(x: .value("Amount", row.amount), y: .value("Item", row.name))
                                    .foregroundStyle(UITheme.accentPurple)
                            }
                        }
                        .frame(height: CGFloat(40 * max(3, topProducts.count)))
                    } else {
                        Text(L10n.t("No Data")).foregroundColor(.secondary)
                    }
                }
                .themedCard()

            }
            .padding(20)
        }
    }

    private var currentCurrencyCode: String {
        currencyFilter == "ALL" ? (simpleDocs.first?.currencyCode ?? "USD") : currencyFilter
    }

    private func inRange(_ date: Date) -> Bool { date >= startDate && date <= endDate }
    private func currencyMatches(_ d: SimpleDoc) -> Bool { currencyFilter == "ALL" || d.currencyCode == currencyFilter }

    private func formatCurrency(_ value: NSDecimalNumber, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        return f.string(from: value) ?? "0"
    }

    // MARK: - Exports
    private func exportCSV() {
        var rows: [String] = []
        let df = DateFormatter(); df.dateFormat = "yyyy-MM"
        let nf = NumberFormatter(); nf.locale = Locale(identifier: "en_US_POSIX"); nf.numberStyle = .decimal; nf.maximumFractionDigits = 2

        rows.append("Report,\(df.string(from: startDate)) to \(df.string(from: endDate)),Currency,\(currencyFilter == "ALL" ? "ALL" : currencyFilter)")
        rows.append("")
        rows.append("Revenue by Month")
        rows.append("Month,Total")
        for p in revenueByMonth {
            let m = df.string(from: p.month)
            let t = nf.string(from: NSNumber(value: p.total)) ?? "0"
            rows.append("\(m),\(t)")
        }
        rows.append("")
        rows.append("Unpaid Summary")
        rows.append("Count,Amount (\(currentCurrencyCode))")
        rows.append("\(unpaidSummary.count),\(nf.string(from: NSNumber(value: unpaidSummary.amount)) ?? "0")")

        let csv = rows.joined(separator: "\n")
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.nameFieldStringValue = "report-\(df.string(from: Date())).csv"
        if panel.runModal() == .OK, let url = panel.url {
            do { try csv.data(using: .utf8)?.write(to: url) } catch { NSLog("CSV export error: \(error.localizedDescription)") }
        }
    }

    private func exportPDF() {
        let df = DateFormatter(); df.dateFormat = "yyyyMMdd-HHmm"
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.pdf]
        panel.nameFieldStringValue = "report-\(df.string(from: Date())).pdf"
        if panel.runModal() == .OK, let url = panel.url {
            let view = ReportExportView(
                startDate: startDate,
                endDate: endDate,
                currency: currentCurrencyCode,
                revenueByMonth: revenueByMonth,
                unpaidCount: unpaidSummary.count,
                unpaidAmount: unpaidSummary.amount
            )
            let renderer = ImageRenderer(content: view.frame(width: 800, height: 1100))
            let size = NSSize(width: 800, height: 1100)
            let image = NSImage(size: size)
            image.lockFocus()
            renderer.nsImage?.draw(in: NSRect(origin: .zero, size: size))
            image.unlockFocus()
            let pdf = PDFDocument()
            if let page = PDFPage(image: image) { pdf.insert(page, at: 0) }
            do { try pdf.dataRepresentation()?.write(to: url) } catch { NSLog("PDF export error: \(error.localizedDescription)") }
        }
    }
}

private struct ReportExportView: View {
    let startDate: Date
    let endDate: Date
    let currency: String
    let revenueByMonth: [(month: Date, total: Double)]
    let unpaidCount: Int
    let unpaidAmount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t("Reports")).font(.largeTitle.bold())
            HStack {
                Text("\(L10n.t("From")): \(formatDate(startDate))  •  \(L10n.t("To")): \(formatDate(endDate))  •  \(L10n.t("Currency")): \(currency)")
                Spacer()
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("Revenue by Month")).font(.headline)
                if revenueByMonth.count > 0 {
                    Chart {
                        ForEach(revenueByMonth, id: \.month) { p in
                            BarMark(x: .value("Month", p.month), y: .value("Total", p.total))
                                .foregroundStyle(UITheme.accentGreen)
                        }
                    }
                    .chartXAxis { AxisMarks(values: .stride(by: .month)) }
                    .frame(height: 220)
                } else {
                    Text(L10n.t("No Data")).foregroundColor(.secondary)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("Unpaid Summary")).font(.headline)
                HStack {
                    Text("\(unpaidCount) " + L10n.t("documents"))
                    Spacer()
                    Text(formatCurrency(unpaidAmount, code: currency)).bold()
                }
            }
            Spacer()
        }
        .padding(24)
    }

    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
    private func formatCurrency(_ value: Double, code: String) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = code
        return f.string(from: NSNumber(value: value)) ?? "0"
    }
}

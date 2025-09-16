import SwiftUI
import CoreData
import Charts

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(entity: Client.entity(), sortDescriptors: []) private var clients: FetchedResults<Client>
    @FetchRequest(entity: Document.entity(), sortDescriptors: []) private var documents: FetchedResults<Document>
    @FetchRequest(entity: InventoryItem.entity(), sortDescriptors: []) private var items: FetchedResults<InventoryItem>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.t("Dashboard")).font(.largeTitle.bold())

                HStack(spacing: 16) {
                    StatCard(title: L10n.t("Clients"), value: "\(clients.count)")
                    RevenueCard(documents: Array(documents))
                    StatCard(title: L10n.t("Invoices"), value: "\(documents.filter{ $0.type == "invoice" }.count)")
                    StatCard(title: L10n.t("Estimates"), value: "\(documents.filter{ $0.type == "estimate" }.count)")
                }

                HStack(spacing: 16) {
                    KpiCard(title: L10n.t("Unpaid"), value: "\(unpaidCount())", accent: UITheme.accentOrange)
                    KpiCard(title: L10n.t("Overdue"), value: "\(overdueCount())", accent: UITheme.errorRed)
                    CashFlowCard(documents: Array(documents))
                }

                ChartsRow(documents: Array(documents))

                RecentDocumentsSection(documents: documents)
            }
            .padding(20)
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(title).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .themedCard()
    }
}

private struct RecentDocumentsSection: View {
    let documents: FetchedResults<Document>
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("Recent Documents")).font(.headline)
            ForEach(documents.prefix(5)) { doc in
                HStack {
                    Text(doc.number ?? "-").font(.headline)
                    Text(formatDate(doc.issueDate)).foregroundColor(.secondary)
                    Spacer()
                    Text(doc.type == "invoice" ? L10n.t("Invoices") : L10n.t("Estimates")).foregroundColor(.secondary)
                }
                .themedCard()
            }
        }
    }
    private func formatDate(_ date: Date?) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date ?? Date())
    }
}

private struct RevenuePoint: Identifiable { let id = UUID(); let month: String; let total: Double }

private struct RevenueCard: View {
    let documents: [Document]
    private var monthly: [RevenuePoint] {
        let cal = Calendar.current
        var bucket: [String: Double] = [:]
        for d in documents where d.type == "invoice" {
            let date = d.issueDate ?? Date()
            let comps = cal.dateComponents([.year, .month], from: date)
            let label = String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
            bucket[label, default: 0] += (d.total?.doubleValue ?? 0)
        }
        return bucket.keys.sorted().map { RevenuePoint(month: $0, total: bucket[$0] ?? 0) }
    }
    private var total: String {
        let sum = documents.filter{ $0.type == "invoice" }.reduce(0.0) { $0 + ($1.total?.doubleValue ?? 0) }
        let nf = NumberFormatter(); nf.numberStyle = .currency; nf.currencyCode = documents.first?.currencyCode ?? "USD"
        return nf.string(from: NSNumber(value: sum)) ?? "0"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(total).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(L10n.t("Revenue")).foregroundColor(.secondary)
            Chart(monthly) { p in
                LineMark(x: .value("m", p.month), y: .value("t", p.total))
                    .foregroundStyle(UITheme.accent)
                AreaMark(x: .value("m", p.month), y: .value("t", p.total))
                    .foregroundStyle(UITheme.accent.opacity(0.2))
            }
            .frame(height: 80)
        }
        .frame(maxWidth: .infinity)
        .themedCard()
    }
}

private struct KpiCard: View {
    let title: String
    let value: String
    let accent: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(title).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(UITheme.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.3)))
        .shadow(color: UITheme.subtleShadow, radius: 6, x: 0, y: 2)
    }
}

private struct CashPoint: Identifiable { let id = UUID(); let day: String; let amount: Double }

private struct CashFlowCard: View {
    let documents: [Document]
    private var upcoming: [CashPoint] {
        let cal = Calendar.current
        let now = Date()
        let range = (0..<14).compactMap { cal.date(byAdding: .day, value: $0, to: now) }
        var bucket: [String: Double] = [:]
        for date in range { bucket[key(date)] = 0 }
        for d in documents where d.type == "invoice" && (d.status ?? "") != "paid" {
            if let due = d.dueDate, due >= now, let days = cal.dateComponents([.day], from: now, to: due).day, days < 14 {
                bucket[key(due), default: 0] += d.total?.doubleValue ?? 0
            }
        }
        return range.map { CashPoint(day: short($0), amount: bucket[key($0)] ?? 0) }
    }
    private var subtitle: String {
        let sum = upcoming.reduce(0.0) { $0 + $1.amount }
        let nf = NumberFormatter(); nf.numberStyle = .currency; nf.currencyCode = documents.first?.currencyCode ?? "USD"
        return nf.string(from: NSNumber(value: sum)) ?? "0"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(subtitle).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(L10n.t("Cash Flow")).foregroundColor(.secondary)
            Chart(upcoming) { p in
                BarMark(x: .value("d", p.day), y: .value("a", p.amount))
                    .foregroundStyle(UITheme.accentGreen)
            }.frame(height: 80)
        }
        .frame(maxWidth: .infinity)
        .themedCard()
    }
    private func key(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date) }
    private func short(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "dd/MM"; return f.string(from: date) }
}

private struct ChartsRow: View {
    let documents: [Document]
    private var revenueMonthly: [RevenuePoint] {
        let cal = Calendar.current
        var bucket: [String: Double] = [:]
        for d in documents where d.type == "invoice" {
            let date = d.issueDate ?? Date()
            let comps = cal.dateComponents([.year, .month], from: date)
            let label = String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
            bucket[label, default: 0] += (d.total?.doubleValue ?? 0)
        }
        return bucket.keys.sorted().map { RevenuePoint(month: $0, total: bucket[$0] ?? 0) }
    }
    private struct ProductSlice: Identifiable { let id = UUID(); let name: String; let total: Double }
    private var topProducts: [ProductSlice] {
        var bucket: [String: Double] = [:]
        for d in documents {
            let set = (d.lineItems as? Set<LineItem>) ?? []
            for li in set {
                let name = li.itemDescription ?? ""
                bucket[name, default: 0] += lineTotalForChart(li)
            }
        }
        let slices = bucket.map { ProductSlice(name: $0.key, total: $0.value) }
        return slices.sorted { $0.total > $1.total }.prefix(6).map { $0 }
    }
    private func lineTotalForChart(_ li: LineItem) -> Double {
        let qty = (li.quantity as NSDecimalNumber?) ?? 0
        let unit = li.unitPrice ?? 0
        let line = qty.multiplying(by: unit)
        let tax = line.multiplying(by: NSDecimalNumber(value: li.taxRate)).dividing(by: 100)
        return line.adding(tax).doubleValue
    }
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text(L10n.t("Revenue")).font(.headline)
                Chart(revenueMonthly) { p in
                    LineMark(x: .value("m", p.month), y: .value("t", p.total))
                        .foregroundStyle(UITheme.accent)
                    AreaMark(x: .value("m", p.month), y: .value("t", p.total))
                        .foregroundStyle(UITheme.accent.opacity(0.2))
                }
                .frame(height: 180)
            }
            .frame(maxWidth: .infinity)
            .themedCard()

            VStack(alignment: .leading) {
                Text(L10n.t("Top Products")).font(.headline)
                Chart(topProducts) { s in
                    SectorMark(angle: .value("Total", s.total))
                        .foregroundStyle(by: .value("Name", s.name))
                }
                .chartLegend(.visible)
                .frame(height: 180)
            }
            .frame(maxWidth: .infinity)
            .themedCard()
        }
    }
}

private extension DashboardView {
    func unpaidCount() -> Int {
        documents.filter { $0.type == "invoice" && ($0.status ?? "draft") != "paid" }.count
    }
    func overdueCount() -> Int {
        let now = Date()
        return documents.filter { $0.type == "invoice" && ($0.status ?? "draft") != "paid" && (($0.dueDate ?? now) < now) }.count
    }
}



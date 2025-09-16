import SwiftUI
import CoreData

struct GlobalSearchOverlay: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @State private var query: String = ""

    @FetchRequest(entity: Client.entity(), sortDescriptors: []) private var clients: FetchedResults<Client>
    @FetchRequest(entity: Document.entity(), sortDescriptors: []) private var documents: FetchedResults<Document>
    @FetchRequest(entity: InventoryItem.entity(), sortDescriptors: []) private var items: FetchedResults<InventoryItem>

    private var filteredClients: [Client] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return clients.filter { ($0.name ?? "").lowercased().contains(q) || ($0.contactEmail ?? "").lowercased().contains(q) }
    }
    private var filteredInvoices: [Document] { documents.filter { ($0.type == "invoice") && matchDocument($0) } }
    private var filteredEstimates: [Document] { documents.filter { ($0.type == "estimate") && matchDocument($0) } }
    private var filteredItems: [InventoryItem] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return items.filter { ($0.name ?? "").lowercased().contains(q) || ($0.sku ?? "").lowercased().contains(q) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(UITheme.gray100))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !filteredClients.isEmpty { SectionList(title: L10n.t("Clients")) { ForEach(filteredClients) { c in ResultRow(title: c.name ?? "-", subtitle: c.contactEmail ?? "") } } }
                    if !filteredInvoices.isEmpty { SectionList(title: L10n.t("Invoices")) { ForEach(filteredInvoices) { d in ResultRow(title: d.number ?? "-", subtitle: formatDate(d.issueDate)) } } }
                    if !filteredEstimates.isEmpty { SectionList(title: L10n.t("Estimates")) { ForEach(filteredEstimates) { d in ResultRow(title: d.number ?? "-", subtitle: formatDate(d.issueDate)) } } }
                    if !filteredItems.isEmpty { SectionList(title: L10n.t("Items")) { ForEach(filteredItems) { i in ResultRow(title: i.name ?? "-", subtitle: i.sku ?? "") } } }
                    if query.isEmpty { Text(L10n.t("Type to search across clients, invoices, estimates and items.")).foregroundColor(.secondary) }
                }
            }

            HStack { Spacer(); Button(L10n.t("Close")) { appState.showGlobalSearch = false } }
        }
        .padding(20)
        .frame(minWidth: 720, minHeight: 520)
    }

    private func matchDocument(_ d: Document) -> Bool {
        guard !query.isEmpty else { return false }
        let q = query.lowercased()
        let num = (d.number ?? "").lowercased()
        let cname = (d.safeClientName).lowercased()
        return num.contains(q) || cname.contains(q)
    }
}

private struct SectionList<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content
        }
    }
}

private struct ResultRow: View {
    let title: String
    let subtitle: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) { Text(title); if !subtitle.isEmpty { Text(subtitle).foregroundColor(.secondary) } }
            Spacer()
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(UITheme.gray100))
    }
}

private func formatDate(_ date: Date?) -> String {
    let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date ?? Date())
}



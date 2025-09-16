import SwiftUI
import CoreData

struct ItemsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: InventoryItem.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)])
    private var items: FetchedResults<InventoryItem>

    @State private var showingEditor: Bool = false
    @State private var selectedItem: InventoryItem?

    var body: some View {
        VStack {
            HStack {
                Text(L10n.t("Items")).font(.title)
                Spacer()
                Button { addItem() } label: { Label(L10n.t("New Item"), systemImage: "plus") }.primaryButton()
            }.padding([.horizontal, .top])
            List(selection: $selectedItem) {
                ForEach(items) { item in
                    Button(action: { selectedItem = item; showingEditor = true }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "").font(.headline)
                                if let sku = item.sku, !sku.isEmpty { Text(sku).foregroundColor(.secondary) }
                            }
                            Spacer()
                            Text(formatCurrency(item.unitPrice, code: "USD"))
                        }
                    }
                    .contextMenu { Button(role: .destructive) { delete(item) } label: { Label(L10n.t("Delete"), systemImage: "trash") } }
                }
                .onDelete(perform: delete)
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let item = selectedItem { ItemEditorView(item: item).environment(\.managedObjectContext, viewContext) }
        }
    }

    private func addItem() {
        let item = InventoryItem(context: viewContext)
        item.id = UUID()
        item.name = "New Item"
        item.unitPrice = 0
        selectedItem = item
        showingEditor = true
        try? viewContext.save()
    }

    private func delete(_ offsets: IndexSet) { offsets.map { items[$0] }.forEach(viewContext.delete); try? viewContext.save() }
    private func delete(_ item: InventoryItem) { viewContext.delete(item); try? viewContext.save() }

    private func formatCurrency(_ value: NSDecimalNumber?, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: value ?? 0) ?? "0"
    }
}

private struct ItemEditorView: View {
    @ObservedObject var item: InventoryItem
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            TextField(L10n.t("Name"), text: Binding(get: { item.name ?? "" }, set: { item.name = $0 }))
            TextField("SKU", text: Binding(get: { item.sku ?? "" }, set: { item.sku = $0 }))
            TextField(L10n.t("Unit"), text: Binding(get: { item.unit ?? "" }, set: { item.unit = $0 }))
            TextField(L10n.t("Unit Price"), value: Binding<Double>(
                get: { item.unitPrice?.doubleValue ?? 0 },
                set: { item.unitPrice = NSDecimalNumber(value: $0) }
            ), formatter: NumberFormatter())
            TextField(
                L10n.t("Tax Rate %"),
                value: Binding<Double>(
                    get: { item.taxRate },
                    set: { item.taxRate = $0 }
                ),
                formatter: {
                    let f = NumberFormatter()
                    f.numberStyle = .decimal
                    f.maximumFractionDigits = 2
                    return f
                }()
            )
            TextField(L10n.t("Notes"), text: Binding(get: { item.notes ?? "" }, set: { item.notes = $0 }))
            HStack {
                Spacer()
                Button(L10n.t("Save")) { UIUtilities.endEditing(); viewContext.perform { try? viewContext.save(); DispatchQueue.main.async { dismiss() } } }.primaryButton()
                Button(role: .destructive) {
                    UIUtilities.endEditing()
                    let alert = NSAlert()
                    alert.messageText = L10n.t("Delete this item?")
                    alert.informativeText = L10n.t("This will not delete line items already using it.")
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: L10n.t("Delete"))
                    alert.addButton(withTitle: L10n.t("Cancel"))
                    if alert.runModal() == .alertFirstButtonReturn {
                        viewContext.perform {
                            viewContext.delete(item)
                            try? viewContext.save()
                            DispatchQueue.main.async { dismiss() }
                        }
                    }
                } label: { Text(L10n.t("Delete")) }
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 360)
        .themedCard()
    }
}



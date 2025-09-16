import SwiftUI
import CoreData

struct ItemsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: InventoryItem.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)])
    private var items: FetchedResults<InventoryItem>

    @State private var showingEditor: Bool = false
    @State private var selectedItem: InventoryItem?
    // Nouveau: filtre catalogue
    @ObservedObject private var constructionDB = ConstructionDatabase.shared
    @State private var searchText: String = ""
    @State private var selectedCategoryName: String = L10n.t("All")

    private var shownCategories: [ConstructionCategory] {
        let all = constructionDB.categories
        let name = selectedCategoryName
        if name == L10n.t("All") { return all }
        return all.filter { $0.nameFR == name }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(L10n.t("Products")).font(.title)
                Spacer()
            }.padding([.horizontal, .top])

            // Barre de recherche + filtres FR/BE & catégorie
            HStack(spacing: 12) {
                TextField(L10n.t("Search product"), text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 260)
                Picker(L10n.t("Country"), selection: $constructionDB.selectedCountry) {
                    Text("FR").tag(ConstructionDatabase.Country.france)
                    Text("BE").tag(ConstructionDatabase.Country.belgium)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                Picker(L10n.t("Category"), selection: $selectedCategoryName) {
                    Text(L10n.t("All")).tag(L10n.t("All"))
                    ForEach(constructionDB.categories.map { $0.nameFR }, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .frame(width: 260)
                Spacer()
            }
            .padding(.horizontal)

            // Liste de produits (base construction completă)
            List {
                if shownCategories.isEmpty {
                    Text(L10n.t("No products found"))
                        .foregroundColor(.secondary)
                }
                ForEach(shownCategories) { category in
                    Section(header: HStack { Text(category.icon); Text(category.nameFR).font(.headline) }) {
                        let products = category.products.filter { prod in
                            searchText.isEmpty || prod.nameFR.localizedCaseInsensitiveContains(searchText) || prod.code.localizedCaseInsensitiveContains(searchText)
                        }
                        if products.isEmpty {
                            Text(L10n.t("No products in this category"))
                                .foregroundColor(.secondary)
                        }
                        ForEach(products) { p in
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack { Text(p.code).font(.caption).foregroundColor(.blue); Text(p.nameFR).font(.headline) }
                                    Text(p.description).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(String(format: "%.2f €/%@", constructionDB.getPrice(for: p), p.unit))
                                Button(L10n.t("Add")) { addToCurrentDocument(p) }
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            }

            // (Opțional) vechile items locale rămân ascunse în acest ecran
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

    private func addToCurrentDocument(_ p: ConstructionProduct) {
        NotificationCenter.default.post(name: Notification.Name("AddProductToCurrentDocument"), object: nil, userInfo: [
            "description": p.nameFR,
            "unit": p.unit,
            "price": constructionDB.getPrice(for: p)
        ])
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



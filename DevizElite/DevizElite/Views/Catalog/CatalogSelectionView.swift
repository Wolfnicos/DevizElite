import SwiftUI
import CoreData

// MARK: - View pentru selecția produselor din catalog BTP
struct CatalogSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var catalog = CatalogBTP()
    
    @ObservedObject var document: Document
    
    @State private var searchText = ""
    @State private var selectedCategory: CatalogBTP.Category?
    @State private var selectedItems: [CatalogBTP.CatalogItem] = []
    @State private var showPriceFilter = false
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 10000
    
    var filteredItems: [CatalogBTP.CatalogItem] {
        var items = catalog.searchItems(query: searchText.isEmpty ? nil : searchText, 
                                       category: selectedCategory)
        
        if showPriceFilter {
            items = catalog.filterByPriceRange(items: items, min: minPrice, max: maxPrice)
        }
        
        return items
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header avec recherche et filtres
            headerSection
            
            // Filtres par catégorie
            categoryFilterSection
            
            // Liste des produits
            productListSection
            
            // Footer avec sélection
            if !selectedItems.isEmpty {
                selectionFooter
            }
        }
        .navigationTitle("Catalogue BTP")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showPriceFilter.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showPriceFilter) {
            PriceFilterView(minPrice: $minPrice, maxPrice: $maxPrice)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Barre de recherche
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Rechercher un produit...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Stats rapides
            HStack {
                Label("\(filteredItems.count) produits", systemImage: "cube.box")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !selectedItems.isEmpty {
                    Label("\(selectedItems.count) sélectionnés", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - Category Filter Section
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                BTPCategoryChip(
                    title: "Tous",
                    icon: "square.grid.2x2",
                    color: .blue,
                    isSelected: selectedCategory == nil,
                    count: catalog.catalogItems.count
                ) {
                    selectedCategory = nil
                }
                
                ForEach(CatalogBTP.Category.allCases) { category in
                    let items = catalog.searchItems(category: category)
                    
                    BTPCategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category,
                        count: items.count
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - Product List Section
    private var productListSection: some View {
        List {
            ForEach(filteredItems) { item in
                CatalogItemRow(
                    item: item,
                    isSelected: selectedItems.contains { $0.id == item.id }
                ) { selectedItem in
                    toggleItemSelection(selectedItem)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Selection Footer
    private var selectionFooter: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedItems.count) article(s) sélectionné(s)")
                        .font(.headline)
                    
                    let totalHT = selectedItems.reduce(0) { $0 + $1.priceHT }
                    Text("Total estimé: \(formatCurrency(totalHT))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Tout désélectionner") {
                    selectedItems.removeAll()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            Button(action: addSelectedItemsToDocument) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Ajouter au document")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
    
    // MARK: - Actions
    private func toggleItemSelection(_ item: CatalogBTP.CatalogItem) {
        if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(item)
        }
    }
    
    private func addSelectedItemsToDocument() {
        let currentPosition = (document.lineItems?.count ?? 0)
        
        for (index, catalogItem) in selectedItems.enumerated() {
            let lineItem = catalogItem.toLineItem(context: viewContext)
            lineItem.position = Int16(currentPosition + index + 1)
            lineItem.document = document
            
            document.addToLineItems(lineItem)
        }
        
        // Sauvegarde
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Erreur lors de l'ajout des articles: \(error)")
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

// MARK: - BTP Category Chip Component  
struct BTPCategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("\(count)")
                        .font(.caption2)
                        .opacity(0.7)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? color : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Catalog Item Row Component
struct CatalogItemRow: View {
    let item: CatalogBTP.CatalogItem
    let isSelected: Bool
    let onSelect: (CatalogBTP.CatalogItem) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: categoryIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(categoryColor)
                .frame(width: 24, height: 24)
                .background(categoryColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Product info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.designation)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.gray)
                    }
                }
                
                if let description = item.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    // Code produit
                    Label(item.code, systemImage: "barcode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Unité
                    Text(item.unit)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            // Price info
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(item.priceHT))
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("HT")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("TVA \(item.vatPercentage)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(formatCurrency(item.priceTTC))
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(item)
        }
        .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
    }
    
    private var categoryIcon: String {
        if let category = CatalogBTP.Category(rawValue: item.category) {
            return category.icon
        }
        return "cube.box"
    }
    
    private var categoryColor: Color {
        if let category = CatalogBTP.Category(rawValue: item.category) {
            return category.color
        }
        return .gray
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

// MARK: - Price Filter View
struct PriceFilterView: View {
    @Binding var minPrice: Double
    @Binding var maxPrice: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Filtrer par prix")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Prix minimum (HT)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Slider(value: $minPrice, in: 0...1000, step: 10)
                        Text(formatCurrency(minPrice))
                            .font(.caption)
                            .frame(width: 80)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Prix maximum (HT)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Slider(value: $maxPrice, in: 100...20000, step: 50)
                        Text(formatCurrency(maxPrice))
                            .font(.caption)
                            .frame(width: 80)
                    }
                }
                
                Spacer()
                
                Button("Réinitialiser") {
                    minPrice = 0
                    maxPrice = 10000
                }
                .foregroundColor(.red)
                
                Button("Appliquer") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Filtres")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    document.number = "TEST-001"
    
    return CatalogSelectionView(document: document)
        .environment(\.managedObjectContext, context)
}
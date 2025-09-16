import SwiftUI

struct ConstructionCatalogSheet: View {
    let onSelect: (SimpleCatalogItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var i18n: LocalizationService
    @ObservedObject private var database = ConstructionDatabase.shared
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    var categories: [String] {
        var result = [L10n.t("All")]
        result.append(contentsOf: database.categories.map { $0.nameFR })
        return result
    }
    
    var catalogItems: [SimpleCatalogItem] {
        database.categories.flatMap { category in
            category.products.map { p in
                SimpleCatalogItem(
                    code: p.code,
                    name: p.nameFR,
                    category: category.nameFR,
                    unit: p.unit,
                    price: database.getPrice(for: p),
                    description: p.description
                )
            }
        }
    }
    
    var filteredItems: [SimpleCatalogItem] {
        catalogItems.filter { item in
            let matchesSearch = searchText.isEmpty || 
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.code.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == L10n.t("All") || 
                item.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.t("Construction Catalog"))
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Spacer()
                Picker(L10n.t("Country"), selection: $database.selectedCountry) {
                    Text("FR").tag(ConstructionDatabase.Country.france)
                    Text("BE").tag(ConstructionDatabase.Country.belgium)
                }
                .pickerStyle(.segmented)
                
                Button(L10n.t("Close")) {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            
            // Search and Filter
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    TextField(L10n.t("Search items..."), text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.surfaceSecondary)
                .cornerRadius(DesignSystem.CornerRadius.small)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Items Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DesignSystem.Spacing.md) {
                    ForEach(filteredItems) { item in
                        CatalogItemCard(item: item) {
                            onSelect(item)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            
            // Footer
            HStack {
                Text("\(filteredItems.count) \(L10n.t("items"))")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            .padding()
            .background(DesignSystem.Colors.surface)
        }
        .frame(width: 900, height: 600)
        .background(DesignSystem.Colors.background)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.callout)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceSecondary)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .cornerRadius(DesignSystem.CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

struct CatalogItemCard: View {
    let item: SimpleCatalogItem
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(item.code)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(categoryColor(item.category))
                    .cornerRadius(4)
                
                Spacer()
                
                Button(action: onSelect) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            
            Text(item.name)
                .font(DesignSystem.Typography.bodyBold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
            
            if let description = item.description {
                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            HStack {
                Text(item.price, format: .currency(code: "EUR"))
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Spacer()
                
                Text("/ \(item.unit)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(height: 150)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(radius: isHovered ? 4 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case L10n.t("Materials"):
            return DesignSystem.Colors.info
        case L10n.t("Labor"):
            return DesignSystem.Colors.warning
        case L10n.t("Equipment"):
            return DesignSystem.Colors.accent
        default:
            return DesignSystem.Colors.textTertiary
        }
    }
}

struct SimpleCatalogItem: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let category: String
    let unit: String
    let price: Double
    let description: String?
}
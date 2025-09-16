import SwiftUI

struct ConstructionCatalogSheet: View {
    let onSelect: (SimpleCatalogItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var i18n: LocalizationService
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    var categories: [String] {
        [
            L10n.t("All"),
            L10n.t("Materials"),
            L10n.t("Labor"),
            L10n.t("Equipment")
        ]
    }
    
    var catalogItems: [SimpleCatalogItem] {
        [
            // Materials
            SimpleCatalogItem(
                code: "MAT001",
                name: L10n.t("Porotherm Brick 25"),
                category: L10n.t("Materials"),
                unit: L10n.t("pcs"),
                price: 2.5,
                description: L10n.t("Ceramic brick for masonry")
            ),
            SimpleCatalogItem(
                code: "MAT002",
                name: L10n.t("Cement CEM II 42.5R"),
                category: L10n.t("Materials"),
                unit: L10n.t("bag"),
                price: 25,
                description: L10n.t("40kg Portland cement bag")
            ),
            SimpleCatalogItem(
                code: "MAT003",
                name: L10n.t("Rebar OB37 Ø12"),
                category: L10n.t("Materials"),
                unit: "kg",
                price: 4.5,
                description: L10n.t("Steel rebar for reinforcement")
            ),
            SimpleCatalogItem(
                code: "MAT004",
                name: L10n.t("AAC Block Ytong"),
                category: L10n.t("Materials"),
                unit: L10n.t("pcs"),
                price: 8.5,
                description: L10n.t("Autoclaved aerated concrete block")
            ),
            SimpleCatalogItem(
                code: "MAT005",
                name: L10n.t("Polystyrene EPS100"),
                category: L10n.t("Materials"),
                unit: "m²",
                price: 35,
                description: L10n.t("Expanded polystyrene insulation")
            ),
            
            // Labor
            SimpleCatalogItem(
                code: "MAN001",
                name: L10n.t("Masonry work"),
                category: L10n.t("Labor"),
                unit: "m²",
                price: 45,
                description: L10n.t("Brick masonry execution")
            ),
            SimpleCatalogItem(
                code: "MAN002",
                name: L10n.t("Plastering work"),
                category: L10n.t("Labor"),
                unit: "m²",
                price: 25,
                description: L10n.t("Traditional plaster application")
            ),
            SimpleCatalogItem(
                code: "MAN003",
                name: L10n.t("Painting work"),
                category: L10n.t("Labor"),
                unit: "m²",
                price: 18,
                description: L10n.t("Surface preparation and painting")
            ),
            SimpleCatalogItem(
                code: "MAN004",
                name: L10n.t("Tile installation"),
                category: L10n.t("Labor"),
                unit: "m²",
                price: 35,
                description: L10n.t("Ceramic tile installation")
            ),
            
            // Equipment
            SimpleCatalogItem(
                code: "EQ001",
                name: L10n.t("Concrete mixer rental"),
                category: L10n.t("Equipment"),
                unit: L10n.t("day"),
                price: 50,
                description: L10n.t("Daily equipment rental")
            ),
            SimpleCatalogItem(
                code: "EQ002",
                name: L10n.t("Scaffolding rental"),
                category: L10n.t("Equipment"),
                unit: "m²",
                price: 5,
                description: L10n.t("Scaffolding system rental")
            ),
            SimpleCatalogItem(
                code: "EQ003",
                name: L10n.t("Crane service"),
                category: L10n.t("Equipment"),
                unit: L10n.t("hour"),
                price: 150,
                description: L10n.t("Mobile crane with operator")
            )
        ]
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
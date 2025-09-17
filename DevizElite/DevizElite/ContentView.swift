import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var i18n: LocalizationService
    
    @State private var selectedView: NavigationItem = .dashboard
    @State private var showSettings = false
    
    enum NavigationItem: String, CaseIterable {
        case dashboard = "Dashboard"
        case invoices = "Invoices"
        case estimates = "Estimates"
        case clients = "Clients"
        case products = "Products"
        case templates = "Templates"
        case reports = "Reports"
        
        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .invoices: return "doc.richtext"
            case .estimates: return "doc.text"
            case .clients: return "person.2"
            case .products: return "cube.box"
            case .templates: return "doc.badge.gearshape"
            case .reports: return "chart.bar"
            }
        }
        
        func displayName(_ i18n: LocalizationService) -> String {
            return L10n.t(self.rawValue)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            sidebarContent
        } detail: {
            // Main Content
            mainContent
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showSettings) {
            ModernSettingsView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(i18n)
        }
        .id(i18n.reloadToken) // Force UI refresh when language changes
        .onReceive(NotificationCenter.default.publisher(for: .actionDashboard)) { _ in
            selectedView = .dashboard
        }
        .onReceive(NotificationCenter.default.publisher(for: .actionInvoices)) { _ in
            selectedView = .invoices
        }
        .onReceive(NotificationCenter.default.publisher(for: .actionEstimates)) { _ in
            selectedView = .estimates
        }
        .onReceive(NotificationCenter.default.publisher(for: .actionClients)) { _ in
            selectedView = .clients
        }
    }
    
    // MARK: - Sidebar
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // App Header
            HStack {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("DevizElite")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            
            Divider()
            
            // Navigation Items
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(NavigationItem.allCases, id: \.self) { item in
                        NavigationButton(
                            item: item,
                            isSelected: selectedView == item
                        ) {
                            withAnimation(DesignSystem.Animation.fast) {
                                selectedView = item
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.sm)
            }
            
            Spacer()
            
            Divider()
            
            // Settings Button
            Button(action: { showSettings = true }) {
                HStack {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                    Text(L10n.t("Settings"))
                        .font(DesignSystem.Typography.body)
                    Spacer()
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(DesignSystem.Spacing.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(minWidth: 240)
        .background(DesignSystem.Colors.surface)
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        switch selectedView {
        case .dashboard:
            ModernDashboardView()
                .environment(\.managedObjectContext, viewContext)
        case .invoices:
            InvoicesListView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(i18n)
        case .estimates:
            EstimatesListView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(i18n)
        case .clients:
            ClientsListView()
                .environment(\.managedObjectContext, viewContext)
        case .products:
            ItemsListView()
                .environment(\.managedObjectContext, viewContext)
        case .templates:
            TemplatesView()
                .environment(\.managedObjectContext, viewContext)
        case .reports:
            ReportsView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

// MARK: - Navigation Button
struct NavigationButton: View {
    @EnvironmentObject private var i18n: LocalizationService
    let item: ContentView.NavigationItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .frame(width: 24)
                
                Text(item.displayName(i18n))
                    .font(isSelected ? DesignSystem.Typography.bodyBold : DesignSystem.Typography.body)
                
                Spacer()
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views
// EstimatesListView is now in its own file: Views/Estimates/EstimatesListView.swift

struct ClientsPlaceholderView: View {
    var body: some View {
        VStack {
            Text("Clienți")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

struct ProductsListView: View {
    var body: some View {
        VStack {
            Text("Produse")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

struct ReportsPlaceholderView: View {
    var body: some View {
        VStack {
            Text("Rapoarte")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

struct SimpleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager()
    @State private var selectedLanguage = "ro"
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header
            HStack {
                Text("Setări")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Theme Selection
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Temă")
                    .font(DesignSystem.Typography.headline)
                
                Picker("", selection: $themeManager.selectedTheme) {
                    Text("Sistem").tag("system")
                    Text("Luminos").tag("light")
                    Text("Întunecat").tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Language Selection
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Limbă")
                    .font(DesignSystem.Typography.headline)
                
                Picker("", selection: $selectedLanguage) {
                    HStack {
                        Text("🇷🇴")
                        Text("Română")
                    }
                    .tag("ro")
                    
                    HStack {
                        Text("🇬🇧")
                        Text("English")
                    }
                    .tag("en")
                    
                    HStack {
                        Text("🇫🇷")
                        Text("Français")
                    }
                    .tag("fr")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(width: 500, height: 400)
    }
}

// MARK: - Document Card
struct DocumentCard: View {
    let number: String
    let clientName: String
    let date: Date
    let amount: Double
    let status: InvoiceStatus
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(number)
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(clientName)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                Text(formatCurrency(amount))
                    .font(DesignSystem.Typography.numberMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            
            StatusBadge(status: status)
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle(isHovered: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Removed old placeholder views - using new modern editors
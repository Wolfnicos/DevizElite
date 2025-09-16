import SwiftUI
import Charts
import CoreData

struct ModernDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedPeriod: Period = .month
    @State private var showNewInvoice = false
    @State private var showNewEstimate = false
    
    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                headerSection
                
                // Quick Actions
                quickActionsSection
                
                // KPI Cards
                kpiCardsSection
                
                // Charts Section
                chartsSection
                
                // Recent Documents
                recentDocumentsSection
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showNewInvoice) {
            Text("New Invoice Editor")
                .frame(width: 800, height: 600)
        }
        .sheet(isPresented: $showNewEstimate) {
            Text("New Estimate Editor")
                .frame(width: 800, height: 600)
        }
        .onAppear {
            viewModel.setContext(viewContext)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(L10n.t("Welcome back"))
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            // Period Selector
            Picker("Perioadă", selection: $selectedPeriod) {
                ForEach(Period.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 300)
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            QuickActionCard(
                icon: "doc.badge.plus",
                title: L10n.t("New Invoice"),
                subtitle: L10n.t("Create an invoice"),
                color: DesignSystem.Colors.primary
            ) {
                showNewInvoice = true
            }
            
            QuickActionCard(
                icon: "doc.text.badge.plus",
                title: L10n.t("New Estimate"),
                subtitle: L10n.t("Create an estimate"),
                color: DesignSystem.Colors.info
            ) {
                showNewEstimate = true
            }
            
            QuickActionCard(
                icon: "person.badge.plus",
                title: L10n.t("New Client"),
                subtitle: L10n.t("Add a client"),
                color: DesignSystem.Colors.accent
            ) {
                // Add client action
            }
            
            QuickActionCard(
                icon: "chart.bar.doc.horizontal",
                title: L10n.t("Reports"),
                subtitle: L10n.t("View detailed reports"),
                color: DesignSystem.Colors.warning
            ) {
                // Reports action
            }
        }
    }
    
    // MARK: - KPI Cards
    private var kpiCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: DesignSystem.Spacing.md) {
            KPICard(
                title: L10n.t("Total Revenue"),
                value: viewModel.formatCurrency(viewModel.totalRevenue),
                change: "+12.5%",
                isPositive: true,
                icon: "chart.line.uptrend.xyaxis",
                color: DesignSystem.Colors.accent
            )
            
            KPICard(
                title: L10n.t("Outstanding Invoices"),
                value: "\(viewModel.pendingInvoices)",
                subtitle: viewModel.formatCurrency(viewModel.pendingAmount),
                icon: "clock.badge.exclamationmark",
                color: DesignSystem.Colors.warning
            )
            
            KPICard(
                title: L10n.t("Paid"),
                value: "\(viewModel.paidInvoices)",
                subtitle: L10n.t("This Month"),
                icon: "checkmark.seal.fill",
                color: DesignSystem.Colors.accent
            )
            
            KPICard(
                title: L10n.t("Active Clients"),
                value: "\(viewModel.activeClients)",
                change: "+3",
                isPositive: true,
                icon: "person.2.fill",
                color: DesignSystem.Colors.info
            )
        }
    }
    
    // MARK: - Charts Section
    private var chartsSection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Revenue Chart
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text(L10n.t("Revenue Evolution"))
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Chart(viewModel.revenueData) { item in
                    LineMark(
                        x: .value("Luna", item.month),
                        y: .value("Venit", item.amount)
                    )
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Luna", item.month),
                        y: .value("Venit", item.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.primary.opacity(0.3),
                                DesignSystem.Colors.primary.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
            }
            .padding()
            .cardStyle()
            
            // Status Distribution
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text(L10n.t("Status Distribution"))
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Chart(viewModel.statusDistribution) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                
                // Legend
                HStack(spacing: DesignSystem.Spacing.lg) {
                    ForEach(viewModel.statusDistribution, id: \.status) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text(item.status)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
            .padding()
            .cardStyle()
        }
    }
    
    // MARK: - Recent Documents
    private var recentDocumentsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Documente Recente")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("Vezi toate") {
                    // Navigate to documents
                }
                .ghostButton()
            }
            
            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("DOCUMENT")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("CLIENT")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .frame(width: 200, alignment: .leading)
                    
                    Text("DATA")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .frame(width: 100, alignment: .leading)
                    
                    Text("VALOARE")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .frame(width: 120, alignment: .trailing)
                    
                    Text("STATUS")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .frame(width: 100, alignment: .center)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                
                Divider()
                
                // Table Rows
                ForEach(viewModel.recentDocuments) { document in
                    DocumentRow(document: document)
                    if document.id != viewModel.recentDocuments.last?.id {
                        Divider()
                    }
                }
            }
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(color)
                    )
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyBold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .cardStyle(isHovered: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - KPI Card
struct KPICard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var change: String? = nil
    var isPositive: Bool = true
    let icon: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                if let change = change {
                    HStack(spacing: 2) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(change)
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundColor(isPositive ? DesignSystem.Colors.accent : DesignSystem.Colors.danger)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(DesignSystem.Typography.numberLarge)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Text(title)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(isHovered: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Document Row
struct DocumentRow: View {
    let document: RecentDocument
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: document.type == .invoice ? "doc.richtext" : "doc.text")
                    .foregroundColor(DesignSystem.Colors.primary)
                Text(document.number)
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(document.clientName)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 200, alignment: .leading)
            
            Text(document.date.formatted(date: .abbreviated, time: .omitted))
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            Text(document.formattedAmount)
                .font(DesignSystem.Typography.numberSmall)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(width: 120, alignment: .trailing)
            
            StatusBadge(status: document.status)
                .frame(width: 100, alignment: .center)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(isHovered ? DesignSystem.Colors.surfaceSecondary : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - View Models
class DashboardViewModel: ObservableObject {
    @Published var totalRevenue: Double = 0
    @Published var pendingInvoices: Int = 0
    @Published var pendingAmount: Double = 0
    @Published var paidInvoices: Int = 0
    @Published var activeClients: Int = 0
    
    @Published var revenueData: [RevenueDataPoint] = []
    @Published var statusDistribution: [StatusDataPoint] = []
    @Published var recentDocuments: [RecentDocument] = []
    
    private var viewContext: NSManagedObjectContext?
    
    init() {
        loadDashboardData()
    }
    
    func setContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
        loadDashboardData()
    }
    
    func loadDashboardData() {
        guard let context = viewContext else {
            // Use sample data if no context
            loadSampleData()
            return
        }
        
        // Fetch real data from Core Data
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", "invoice")
        
        do {
            let invoices = try context.fetch(request)
            
            // Calculate totals
            totalRevenue = invoices.compactMap { $0.total }
                .reduce(0) { $0 + $1.doubleValue }
            
            pendingInvoices = invoices.filter { $0.status == "pending" }.count
            pendingAmount = invoices.filter { $0.status == "pending" }
                .compactMap { $0.total }
                .reduce(0) { $0 + $1.doubleValue }
            
            paidInvoices = invoices.filter { $0.status == "paid" }.count
            
            // Get unique clients
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            activeClients = (try? context.count(for: clientRequest)) ?? 0
            
            // Get recent documents
            let recentRequest: NSFetchRequest<Document> = Document.fetchRequest()
            recentRequest.sortDescriptors = [NSSortDescriptor(key: "issueDate", ascending: false)]
            recentRequest.fetchLimit = 5
            
            if let recentDocs = try? context.fetch(recentRequest) {
                recentDocuments = recentDocs.map { doc in
                    RecentDocument(
                        id: doc.id ?? UUID(),
                        number: doc.number ?? "N/A",
                        clientName: getClientName(doc),
                        date: doc.issueDate ?? Date(),
                        amount: doc.total?.doubleValue ?? 0,
                        status: mapStatus(doc.status ?? "draft"),
                        type: doc.type == "invoice" ? .invoice : .estimate
                    )
                }
            }
            
            // Status distribution
            let statusCounts = Dictionary(grouping: invoices, by: { $0.status ?? "draft" })
            statusDistribution = statusCounts.map { key, value in
                StatusDataPoint(
                    status: mapStatus(key).rawValue,
                    count: value.count,
                    color: colorForStatus(mapStatus(key))
                )
            }
            
        } catch {
            print("Error loading dashboard data: \(error)")
            loadSampleData()
        }
    }
    
    private func getClientName(_ document: Document) -> String {
        if let client = document.safeClient { return client.name ?? "N/A" }
        return "N/A"
    }
    
    private func mapStatus(_ status: String) -> InvoiceStatus {
        switch status.lowercased() {
        case "paid": return .paid
        case "pending": return .pending
        case "overdue": return .overdue
        case "cancelled": return .cancelled
        default: return .draft
        }
    }
    
    private func colorForStatus(_ status: InvoiceStatus) -> Color {
        switch status {
        case .paid: return DesignSystem.Colors.accent
        case .pending: return DesignSystem.Colors.warning
        case .overdue: return DesignSystem.Colors.danger
        case .cancelled: return DesignSystem.Colors.textTertiary
        case .draft: return DesignSystem.Colors.info
        case .all: return DesignSystem.Colors.textPrimary
        }
    }
    
    private func loadSampleData() {
        // Sample data for when no real data exists
        revenueData = [
            RevenueDataPoint(month: "Jan", amount: 15000),
            RevenueDataPoint(month: "Feb", amount: 18000),
            RevenueDataPoint(month: "Mar", amount: 22000),
            RevenueDataPoint(month: "Apr", amount: 19000),
            RevenueDataPoint(month: "Mai", amount: 25000),
            RevenueDataPoint(month: "Iun", amount: 28000)
        ]
        
        statusDistribution = [
            StatusDataPoint(status: "Plătit", count: 24, color: DesignSystem.Colors.statusPaid),
            StatusDataPoint(status: "În așteptare", count: 8, color: DesignSystem.Colors.statusPending),
            StatusDataPoint(status: "Întârziat", count: 3, color: DesignSystem.Colors.statusOverdue),
            StatusDataPoint(status: "Ciornă", count: 5, color: DesignSystem.Colors.statusDraft)
        ]
        
        recentDocuments = [
            RecentDocument(
                id: UUID(),
                number: "INV-2024-001",
                clientName: "Construct SRL",
                date: Date(),
                amount: 5430.50,
                status: .paid,
                type: .invoice
            ),
            RecentDocument(
                id: UUID(),
                number: "EST-2024-015",
                clientName: "Build Pro SA",
                date: Date().addingTimeInterval(-86400),
                amount: 12300.00,
                status: .pending,
                type: .estimate
            ),
            RecentDocument(
                id: UUID(),
                number: "INV-2024-002",
                clientName: "Mega Construct",
                date: Date().addingTimeInterval(-172800),
                amount: 8750.00,
                status: .overdue,
                type: .invoice
            )
        ]
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "0 EUR"
    }
}

// MARK: - Data Models
struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct StatusDataPoint: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
    let color: Color
}

struct RecentDocument: Identifiable {
    let id: UUID
    let number: String
    let clientName: String
    let date: Date
    let amount: Double
    let status: InvoiceStatus
    let type: DocumentType
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 EUR"
    }
}

enum DocumentType: String, Codable {
    case invoice = "invoice"
    case estimate = "estimate"
}

//
//  EstimatesListView.swift
//  DevizElite
//
//  Created by Claude Code on 17/09/2025.
//

import SwiftUI
import CoreData

struct EstimatesListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var i18n: LocalizationService
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.issueDate, ascending: false)],
        predicate: NSPredicate(format: "type == %@", "estimate"),
        animation: .default)
    private var estimates: FetchedResults<Document>

    @State private var searchTerm: String = ""
    @State private var selectedStatus: EstimateStatus = .all
    
    // State for opening editor
    @State private var selectedEstimate: Document?
    @State private var showNewEstimate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EstimateHeaderView(
                searchTerm: $searchTerm,
                onSearchChanged: { _ in },
                onNewEstimate: {
                    showNewEstimate = true
                },
                onNewEstimateWithTemplate: { style in
                    openEstimateEditor(for: nil, withTemplate: style)
                }
            )
            
            EstimateStatusFilterView(selectedStatus: $selectedStatus)
            
            EstimateStatsView(estimates: Array(estimates))
            
            List {
                ForEach(filteredEstimates, id: \.id) { estimate in
                    SwipeableEstimateRow(
                        estimate: estimate,
                        onEdit: { selectedEstimate = $0 },
                        onDelete: { 
                            print("🗑️ DELETE ESTIMATE: \(estimate.number ?? "N/A")")
                            deleteEstimate($0) 
                        },
                        onConvertToInvoice: { convertToInvoice($0) }
                    )
                }
                .onDelete { indexSet in
                    print("🔄 SWIPE DELETE triggered for indices: \(indexSet)")
                    deleteEstimates(at: indexSet)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background)
        }
        .background(DesignSystem.Colors.background)
        .frame(minWidth: 600, idealWidth: 800, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .onChange(of: showNewEstimate) { _, newValue in
            if newValue {
                openEstimateEditor(for: nil) // Open new
                showNewEstimate = false // Reset trigger
            }
        }
        .onChange(of: selectedEstimate) { _, estimate in
            if let estimateToEdit = estimate {
                openEstimateEditor(for: estimateToEdit)
                selectedEstimate = nil // Reset trigger
            }
        }
    }
    
    private var filteredEstimates: [Document] {
        estimates.filter { estimate in
            let statusMatch = (selectedStatus == .all) || (estimate.status?.caseInsensitiveCompare(selectedStatus.rawValue) == .orderedSame)
            let searchMatch = searchTerm.isEmpty ||
                (estimate.number?.localizedCaseInsensitiveContains(searchTerm) ?? false) ||
                (estimate.safeClient?.name?.localizedCaseInsensitiveContains(searchTerm) ?? false)
            return statusMatch && searchMatch
        }
    }

    private func deleteEstimate(_ estimate: Document) {
        viewContext.perform {
            viewContext.delete(estimate)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting estimate: \(error)")
            }
        }
    }
    
    // MARK: - Swipe to delete functionality
    private func deleteEstimates(at offsets: IndexSet) {
        print("🔄 deleteEstimates called with offsets: \(offsets)")
        
        guard !offsets.isEmpty else {
            print("⚠️ No offsets provided")
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in offsets {
                guard index < filteredEstimates.count else {
                    print("⚠️ Index \(index) out of bounds")
                    continue
                }
                let estimate = filteredEstimates[index]
                print("🗑️ Suppression du devis: \(estimate.number ?? "N/A")")
                viewContext.delete(estimate)
            }
            
            do {
                try viewContext.save()
                print("✅ \(offsets.count) devis supprimé(s) avec succès")
            } catch {
                print("❌ Erreur lors de la suppression: \(error)")
                viewContext.rollback()
            }
        }
    }
    
    private func convertToInvoice(_ estimate: Document) {
        // Create new invoice from estimate
        let invoice = Document(context: viewContext)
        
        // Copy all data from estimate
        invoice.id = UUID()
        invoice.type = "invoice"
        invoice.number = generateInvoiceNumber()
        invoice.issueDate = Date()
        invoice.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        invoice.status = "draft"
        invoice.client = estimate.client
        invoice.currencyCode = estimate.currencyCode
        invoice.subtotal = estimate.subtotal
        // Don't copy taxAmount as it's calculated automatically
        invoice.total = estimate.total
        invoice.notes = estimate.notes
        
        // Copy BTP metadata
        invoice.projectName = estimate.projectName
        invoice.permitNumber = estimate.permitNumber
        invoice.btpCountry = estimate.btpCountry
        invoice.zoneTravaux = estimate.zoneTravaux
        invoice.typeTravaux = estimate.typeTravaux
        invoice.siteAddress = estimate.siteAddress
        
        // Copy line items
        if let estimateLineItems = estimate.lineItems?.allObjects as? [LineItem] {
            for oldItem in estimateLineItems {
                let newItem = LineItem(context: viewContext)
                newItem.id = UUID()
                newItem.itemDescription = oldItem.itemDescription
                newItem.quantity = oldItem.quantity
                newItem.unitPrice = oldItem.unitPrice
                newItem.taxRate = oldItem.taxRate
                newItem.position = oldItem.position
                newItem.uniteBTP = oldItem.uniteBTP
                newItem.corpsEtat = oldItem.corpsEtat
                newItem.document = invoice
            }
        }
        
        do {
            try viewContext.save()
            print("✅ Devis converti en facture: \(invoice.number ?? "N/A")")
            
            // Open the new invoice
            openInvoiceEditor(for: invoice)
        } catch {
            print("❌ Erreur lors de la conversion: \(error)")
        }
    }
    
    private func generateInvoiceNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: Date())
        
        // Count existing invoices for this year
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@ AND number BEGINSWITH %@", "invoice", "FA-\(year)")
        
        let count = (try? viewContext.count(for: request)) ?? 0
        return "FA-\(year)-\(String(format: "%03d", count + 1))"
    }

    private func openEstimateEditor(for document: Document?, withTemplate style: TemplateStyle? = nil) {
        // Set template if provided, otherwise use current selection
        if let style = style {
            UserDefaults.standard.set(style.rawValue, forKey: "templateStyle")
        }
        
        let windowController = EstimateWindowController(
            document: document,
            context: viewContext,
            i18n: i18n
        )
        windowController.showWindow(nil)
    }
    
    private func openInvoiceEditor(for invoice: Document) {
        let windowController = InvoiceWindowController(
            document: invoice,
            context: viewContext,
            i18n: i18n
        )
        windowController.showWindow(nil)
    }
}

// MARK: - Estimate Status Enum
enum EstimateStatus: String, CaseIterable {
    case all = "all"
    case draft = "draft"
    case sent = "sent"
    case accepted = "accepted"
    case rejected = "rejected"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .all: return L10n.t("All")
        case .draft: return L10n.t("Brouillon")
        case .sent: return L10n.t("Envoyé")
        case .accepted: return L10n.t("Accepté")
        case .rejected: return L10n.t("Refusé")
        case .expired: return L10n.t("Expiré")
        }
    }
}

// MARK: - Subviews
private struct EstimateHeaderView: View {
    @Binding var searchTerm: String
    var onSearchChanged: (String) -> Void
    var onNewEstimate: () -> Void
    var onNewEstimateWithTemplate: (TemplateStyle) -> Void
    
    @State private var showTemplateSelector = false
    
    var body: some View {
        HStack {
            TextField(L10n.t("Rechercher devis..."), text: $searchTerm)
                .textFieldStyle(ModernTextFieldStyle())
                .frame(maxWidth: 300)
            
            Spacer()
            
            // Template Selector Button
            Button {
                showTemplateSelector = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 14, weight: .medium))
                    Text("Nouveau Devis BTP")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange) // Orange pour les devis
            .controlSize(.large)
            .sheet(isPresented: $showTemplateSelector) {
                TemplateSelector(
                    isPresented: $showTemplateSelector,
                    documentType: .estimate,
                    onTemplateSelected: onNewEstimateWithTemplate
                )
            }
            
            // Classic New Estimate Button
            Button(action: onNewEstimate) {
                Label(L10n.t("Nouveau Devis"), systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(DesignSystem.Colors.background)
    }
}

private struct EstimateStatusFilterView: View {
    @Binding var selectedStatus: EstimateStatus
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(EstimateStatus.allCases, id: \.self) { status in
                    Button(action: { selectedStatus = status }) {
                        Text(status.displayName)
                            .font(DesignSystem.Typography.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selectedStatus == status ? Color.orange.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedStatus == status ? .orange : DesignSystem.Colors.textPrimary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(DesignSystem.Colors.background)
    }
}

private struct EstimateStatsView: View {
    let estimates: [Document]
    
    var totalAmount: Double {
        estimates.reduce(0) { $0 + ($1.total?.doubleValue ?? 0) }
    }
    
    var acceptedAmount: Double {
        estimates.filter { $0.status == "accepted" }.reduce(0) { $0 + ($1.total?.doubleValue ?? 0) }
    }
    
    var pendingAmount: Double {
        estimates.filter { $0.status == "sent" }.reduce(0) { $0 + ($1.total?.doubleValue ?? 0) }
    }

    var body: some View {
        HStack {
            EstimateStatCard(title: L10n.t("Total"), amount: totalAmount, color: .orange)
            EstimateStatCard(title: L10n.t("Acceptés"), amount: acceptedAmount, color: .green)
            EstimateStatCard(title: L10n.t("En attente"), amount: pendingAmount, color: .blue)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

private struct EstimateStatCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text(formatCurrency(amount))
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.large)
    }
}

private struct EstimateRow: View {
    @EnvironmentObject private var i18n: LocalizationService
    let estimate: Document
    let onEdit: (Document) -> Void
    let onDelete: (Document) -> Void
    let onConvertToInvoice: (Document) -> Void
    
    @State private var showDeleteConfirm = false
    @State private var showConvertConfirm = false

    var body: some View {
        HStack {
            // Icône DEVIS
            Image(systemName: "doc.text")
                .foregroundColor(.orange)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(estimate.number ?? "N/A")
                        .font(DesignSystem.Typography.headline)
                    
                    // Badge DEVIS
                    Text("DEVIS")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Text(getClientName(estimate))
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // Validité du devis
                if let issueDate = estimate.issueDate {
                    let validUntil = Calendar.current.date(byAdding: .day, value: 30, to: issueDate) ?? issueDate
                    Text("Valide jusqu'au \(validUntil, style: .date)")
                        .font(.caption)
                        .foregroundColor(isExpired(validUntil) ? .red : .orange)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formatCurrency(estimate.total?.doubleValue ?? 0))
                    .font(DesignSystem.Typography.headline)
                Text(estimate.issueDate ?? Date(), style: .date)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            statusBadge
                .padding(.leading)
        }
        .contentShape(Rectangle())
        .gesture(
            TapGesture()
                .onEnded { onEdit(estimate) }
        )
        .contextMenu {
            Button { onEdit(estimate) } label: { 
                Label(L10n.t("Modifier"), systemImage: "pencil") 
            }
            
            if estimate.status != "accepted" {
                Button { showConvertConfirm = true } label: { 
                    Label(L10n.t("Convertir en facture"), systemImage: "arrow.right.doc.on.clipboard") 
                }
            }
            
            Button(role: .destructive) { showDeleteConfirm = true } label: { 
                Label(L10n.t("Supprimer"), systemImage: "trash") 
            }
        }
        .alert(L10n.t("Supprimer le devis?"), isPresented: $showDeleteConfirm) {
            Button(L10n.t("Annuler"), role: .cancel) {}
            Button(L10n.t("Supprimer"), role: .destructive) { onDelete(estimate) }
        } message: {
            Text(L10n.t("Êtes-vous sûr de vouloir supprimer le devis \(estimate.number ?? "")? Cette action ne peut pas être annulée."))
        }
        .alert(L10n.t("Convertir en facture?"), isPresented: $showConvertConfirm) {
            Button(L10n.t("Annuler"), role: .cancel) {}
            Button(L10n.t("Convertir")) { onConvertToInvoice(estimate) }
        } message: {
            Text(L10n.t("Cela créera une nouvelle facture basée sur ce devis."))
        }
    }
    
    private var statusBadge: some View {
        Text(statusDisplayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(10)
    }
    
    private var statusDisplayName: String {
        switch estimate.status?.lowercased() {
        case "draft": return "Brouillon"
        case "sent": return "Envoyé"
        case "accepted": return "Accepté"
        case "rejected": return "Refusé"
        case "expired": return "Expiré"
        default: return estimate.status?.capitalized ?? "N/A"
        }
    }
    
    private var statusColor: Color {
        switch estimate.status?.lowercased() {
        case "accepted": return .green
        case "sent": return .blue
        case "rejected": return .red
        case "expired": return .red
        case "draft": return .gray
        default: return .orange
        }
    }
    
    private func isExpired(_ date: Date) -> Bool {
        date < Date()
    }
    
    private func getClientName(_ estimate: Document) -> String {
        if let client = estimate.safeClient {
            return client.name ?? L10n.t("Pas de client")
        }
        return L10n.t("Pas de client")
    }
}

// MARK: - Swipeable Estimate Row with Manual Swipe Detection
struct SwipeableEstimateRow: View {
    @EnvironmentObject private var i18n: LocalizationService
    let estimate: Document
    let onEdit: (Document) -> Void
    let onDelete: (Document) -> Void
    let onConvertToInvoice: (Document) -> Void
    
    @State private var showDeleteConfirm = false
    @State private var showConvertConfirm = false
    @State private var dragOffset: CGFloat = 0
    @State private var showingActions = false
    
    var body: some View {
        ZStack {
            // Background Delete Action
            HStack {
                Spacer()
                Button(action: { 
                    print("🔥 MANUAL DELETE BUTTON PRESSED")
                    showDeleteConfirm = true 
                }) {
                    VStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Supprimer")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
                .frame(width: 80)
                .frame(maxHeight: .infinity)
                .background(Color.red)
                .opacity(showingActions ? 1.0 : 0.0)
            }
            
            // Main Content
            HStack {
                // Icône DEVIS
                Image(systemName: "doc.text")
                    .foregroundColor(.orange)
                    .font(.title2)
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(estimate.number ?? "N/A")
                            .font(DesignSystem.Typography.headline)
                        
                        // Badge DEVIS
                        Text("DEVIS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text(getClientName(estimate))
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    // Validité du devis
                    if let issueDate = estimate.issueDate {
                        let validUntil = Calendar.current.date(byAdding: .day, value: 30, to: issueDate) ?? issueDate
                        Text("Valide jusqu'au \(validUntil, style: .date)")
                            .font(.caption)
                            .foregroundColor(isExpired(validUntil) ? .red : .orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(formatCurrency(estimate.total?.doubleValue ?? 0))
                        .font(DesignSystem.Typography.headline)
                    Text(estimate.issueDate ?? Date(), style: .date)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                statusBadge(estimate: estimate)
                    .padding(.leading)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        print("📱 DRAG DETECTED: \(value.translation.width)")
                        if value.translation.width < 0 { // Swipe left
                            dragOffset = max(value.translation.width, -100)
                            showingActions = dragOffset < -30
                        }
                    }
                    .onEnded { value in
                        print("📱 DRAG ENDED: \(value.translation.width)")
                        withAnimation(.spring()) {
                            if value.translation.width < -50 {
                                dragOffset = -80
                                showingActions = true
                            } else {
                                dragOffset = 0
                                showingActions = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if showingActions {
                    withAnimation(.spring()) {
                        dragOffset = 0
                        showingActions = false
                    }
                } else {
                    onEdit(estimate)
                }
            }
        }
        .clipped()
        .contextMenu {
            Button { onEdit(estimate) } label: { 
                Label(L10n.t("Modifier"), systemImage: "pencil") 
            }
            
            if estimate.status != "accepted" {
                Button { showConvertConfirm = true } label: { 
                    Label(L10n.t("Convertir en facture"), systemImage: "arrow.right.doc.on.clipboard") 
                }
            }
            
            Button(role: .destructive) { showDeleteConfirm = true } label: { 
                Label(L10n.t("Supprimer"), systemImage: "trash") 
            }
        }
        .alert(L10n.t("Supprimer le devis?"), isPresented: $showDeleteConfirm) {
            Button(L10n.t("Annuler"), role: .cancel) {}
            Button(L10n.t("Supprimer"), role: .destructive) { 
                print("✅ CONFIRMED DELETE")
                onDelete(estimate) 
            }
        } message: {
            Text(L10n.t("Êtes-vous sûr de vouloir supprimer le devis \(estimate.number ?? "")?"))
        }
        .alert(L10n.t("Convertir en facture?"), isPresented: $showConvertConfirm) {
            Button(L10n.t("Annuler"), role: .cancel) {}
            Button(L10n.t("Convertir")) { onConvertToInvoice(estimate) }
        } message: {
            Text(L10n.t("Cela créera une nouvelle facture basée sur ce devis."))
        }
    }
    
    private func statusBadge(estimate: Document) -> some View {
        Text(statusDisplayName(estimate: estimate))
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor(estimate: estimate).opacity(0.2))
            .foregroundColor(statusColor(estimate: estimate))
            .cornerRadius(10)
    }
    
    private func statusDisplayName(estimate: Document) -> String {
        switch estimate.status?.lowercased() {
        case "draft": return "Brouillon"
        case "sent": return "Envoyé"
        case "accepted": return "Accepté"
        case "rejected": return "Refusé"
        case "expired": return "Expiré"
        default: return estimate.status?.capitalized ?? "N/A"
        }
    }
    
    private func statusColor(estimate: Document) -> Color {
        switch estimate.status?.lowercased() {
        case "accepted": return .green
        case "sent": return .blue
        case "rejected": return .red
        case "expired": return .red
        case "draft": return .gray
        default: return .orange
        }
    }
    
    private func isExpired(_ date: Date) -> Bool {
        date < Date()
    }
    
    private func getClientName(_ estimate: Document) -> String {
        if let client = estimate.safeClient {
            return client.name ?? L10n.t("Pas de client")
        }
        return L10n.t("Pas de client")
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}
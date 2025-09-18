//
//  InvoicesListView.swift
//  DevizElite
//
//  Created by App Gemini on 15/09/2025.
//

import SwiftUI
import CoreData

struct InvoicesListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var i18n: LocalizationService
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.issueDate, ascending: false)],
        predicate: NSPredicate(format: "type == %@", "invoice"),
        animation: .default)
    private var invoices: FetchedResults<Document>

    @State private var searchTerm: String = ""
    @State private var selectedStatus: InvoiceStatus = .all
    
    // State for opening editor
    @State private var selectedInvoice: Document?
    @State private var showNewInvoice = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderView(
                searchTerm: $searchTerm,
                onSearchChanged: { _ in },
                onNewInvoice: {
                    showNewInvoice = true
                },
                onNewInvoiceWithTemplate: { style in
                    openInvoiceEditor(for: nil, withTemplate: style)
                }
            )
            
            StatusFilterView(selectedStatus: $selectedStatus)
            
            InvoiceStatsView(invoices: Array(invoices))
            
            List {
                ForEach(filteredInvoices, id: \.id) { invoice in
                    SwipeableInvoiceRow(
                        invoice: invoice,
                        onEdit: { selectedInvoice = $0 },
                        onDelete: { 
                            print("🗑️ DELETE INVOICE: \(invoice.number ?? "N/A")")
                            deleteInvoice($0) 
                        }
                    )
                }
                .onDelete { indexSet in
                    print("🔄 SWIPE DELETE triggered for indices: \(indexSet)")
                    deleteInvoices(at: indexSet)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background)
        }
        .background(DesignSystem.Colors.background)
        .frame(minWidth: 600, idealWidth: 800, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .onChange(of: showNewInvoice) { _, newValue in
            if newValue {
                openInvoiceEditor(for: nil) // Open new
                showNewInvoice = false // Reset trigger
            }
        }
        .onChange(of: selectedInvoice) { _, invoice in
            if let invoiceToEdit = invoice {
                openInvoiceEditor(for: invoiceToEdit)
                selectedInvoice = nil // Reset trigger
            }
        }
    }
    
    private var filteredInvoices: [Document] {
        invoices.filter { invoice in
            let statusMatch = (selectedStatus == .all) || (invoice.status?.caseInsensitiveCompare(selectedStatus.rawValue) == .orderedSame)
            let searchMatch = searchTerm.isEmpty ||
                (invoice.number?.localizedCaseInsensitiveContains(searchTerm) ?? false) ||
                (invoice.safeClient?.name?.localizedCaseInsensitiveContains(searchTerm) ?? false)
            return statusMatch && searchMatch
        }
    }

    private func deleteInvoice(_ invoice: Document) {
        viewContext.perform {
            viewContext.delete(invoice)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting invoice: \(error)")
            }
        }
    }
    
    // MARK: - Swipe to delete functionality
    private func deleteInvoices(at offsets: IndexSet) {
        print("🔄 deleteInvoices called with offsets: \(offsets)")
        
        guard !offsets.isEmpty else {
            print("⚠️ No offsets provided")
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in offsets {
                guard index < filteredInvoices.count else {
                    print("⚠️ Index \(index) out of bounds")
                    continue
                }
                let invoice = filteredInvoices[index]
                print("🗑️ Suppression de la facture: \(invoice.number ?? "N/A")")
                viewContext.delete(invoice)
            }
            
            do {
                try viewContext.save()
                print("✅ \(offsets.count) facture(s) supprimée(s) avec succès")
            } catch {
                print("❌ Erreur lors de la suppression: \(error)")
                viewContext.rollback()
            }
        }
    }

    private func openInvoiceEditor(for document: Document?, withTemplate style: TemplateStyle? = nil) {
        // Set template if provided, otherwise use current selection
        if let style = style {
            UserDefaults.standard.set(style.rawValue, forKey: "templateStyle")
        }
        
        let windowController = InvoiceWindowController(
            document: document,
            context: viewContext,
            i18n: i18n
        )
        windowController.showWindow(nil)
    }
}


// MARK: - Subviews
private struct HeaderView: View {
    @Binding var searchTerm: String
    var onSearchChanged: (String) -> Void
    var onNewInvoice: () -> Void
    var onNewInvoiceWithTemplate: (TemplateStyle) -> Void
    
    @State private var showTemplateSelector = false
    
    var body: some View {
        HStack {
            TextField(L10n.t("Search invoices..."), text: $searchTerm)
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
                    Text("Nouvelle Facture BTP")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue) // Blue pour les factures
            .controlSize(.large)
            .sheet(isPresented: $showTemplateSelector) {
                TemplateSelector(
                    isPresented: $showTemplateSelector,
                    documentType: .invoice,
                    onTemplateSelected: onNewInvoiceWithTemplate
                )
            }
            
            // Classic New Invoice Button
            Button(action: onNewInvoice) {
                Label(L10n.t("New Invoice"), systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(DesignSystem.Colors.background)
    }
}

private struct StatusFilterView: View {
    @Binding var selectedStatus: InvoiceStatus
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(InvoiceStatus.allCases, id: \.self) { status in
                    Button(action: { selectedStatus = status }) {
                        Text(status.displayName)
                            .font(DesignSystem.Typography.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selectedStatus == status ? DesignSystem.Colors.accent.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedStatus == status ? DesignSystem.Colors.accent : DesignSystem.Colors.textPrimary)
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

private struct InvoiceStatsView: View {
    let invoices: [Document]
    
    var totalAmount: Double {
        invoices.reduce(0) { $0 + ($1.total?.doubleValue ?? 0) }
    }
    
    var paidAmount: Double {
        invoices.filter { $0.status == "paid" }.reduce(0) { $0 + ($1.total?.doubleValue ?? 0) }
    }
    
    var pendingAmount: Double {
        invoices.filter { $0.status == "pending" }.reduce(0) { $0 + ($1.total?.doubleValue ?? 0) }
    }

    var body: some View {
        HStack {
            StatCard(title: L10n.t("Total"), amount: totalAmount, color: .blue)
            StatCard(title: L10n.t("Paid"), amount: paidAmount, color: .green)
            StatCard(title: L10n.t("Pending"), amount: pendingAmount, color: .orange)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

private struct StatCard: View {
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

private struct InvoiceRow: View {
    @EnvironmentObject private var i18n: LocalizationService
    let invoice: Document
    let onEdit: (Document) -> Void
    let onDelete: (Document) -> Void
    
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(invoice.number ?? "N/A")
                    .font(DesignSystem.Typography.headline)
                Text(getClientName(invoice))
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formatCurrency(invoice.total?.doubleValue ?? 0))
                    .font(DesignSystem.Typography.headline)
                Text(invoice.issueDate ?? Date(), style: .date)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            statusBadge
                .padding(.leading)
        }
        .contentShape(Rectangle())
        .gesture(
            TapGesture()
                .onEnded { onEdit(invoice) }
        )
        .contextMenu {
            Button { onEdit(invoice) } label: { Label(L10n.t("Edit"), systemImage: "pencil") }
            Button(role: .destructive) { showDeleteConfirm = true } label: { Label(L10n.t("Delete"), systemImage: "trash") }
        }
        .alert(L10n.t("Delete Invoice?"), isPresented: $showDeleteConfirm) {
            Button(L10n.t("Cancel"), role: .cancel) {}
            Button(L10n.t("Delete"), role: .destructive) { onDelete(invoice) }
        } message: {
            Text(L10n.t("Are you sure you want to delete invoice \(invoice.number ?? "")? This action cannot be undone."))
        }
    }
    
    private var statusBadge: some View {
        Text(invoice.status?.capitalized ?? "N/A")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(10)
    }
    
    private var statusColor: Color {
        switch invoice.status?.lowercased() {
        case "paid": return .green
        case "pending": return .orange
        case "overdue": return .red
        case "draft": return .gray
        default: return .blue
        }
    }
    
    private func getClientName(_ invoice: Document) -> String {
        // Safely access the client name using the new safe accessor
        if let client = invoice.safeClient {
            return client.name ?? L10n.t("No client")
        }
        return L10n.t("No client")
    }
}

// MARK: - Swipeable Invoice Row with Manual Swipe Detection
struct SwipeableInvoiceRow: View {
    @EnvironmentObject private var i18n: LocalizationService
    let invoice: Document
    let onEdit: (Document) -> Void
    let onDelete: (Document) -> Void
    
    @State private var showDeleteConfirm = false
    @State private var dragOffset: CGFloat = 0
    @State private var showingActions = false
    
    var body: some View {
        ZStack {
            // Background Delete Action
            HStack {
                Spacer()
                Button(action: { 
                    print("🔥 MANUAL DELETE BUTTON PRESSED - INVOICE")
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
                // Icône FACTURE
                Image(systemName: "doc.richtext")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(invoice.number ?? "N/A")
                            .font(DesignSystem.Typography.headline)
                        
                        // Badge FACTURE
                        Text("FACTURE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text(getClientName(invoice))
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    // Due date
                    if let dueDate = invoice.dueDate {
                        Text("Échéance: \(dueDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(isPastDue(dueDate) ? .red : .blue)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(formatCurrency(invoice.total?.doubleValue ?? 0))
                        .font(DesignSystem.Typography.headline)
                    Text(invoice.issueDate ?? Date(), style: .date)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                statusBadge(invoice: invoice)
                    .padding(.leading)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        print("📱 DRAG DETECTED - INVOICE: \(value.translation.width)")
                        if value.translation.width < 0 { // Swipe left
                            dragOffset = max(value.translation.width, -100)
                            showingActions = dragOffset < -30
                        }
                    }
                    .onEnded { value in
                        print("📱 DRAG ENDED - INVOICE: \(value.translation.width)")
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
                    onEdit(invoice)
                }
            }
        }
        .clipped()
        .contextMenu {
            Button { onEdit(invoice) } label: { 
                Label(L10n.t("Edit"), systemImage: "pencil") 
            }
            Button(role: .destructive) { showDeleteConfirm = true } label: { 
                Label(L10n.t("Delete"), systemImage: "trash") 
            }
        }
        .alert(L10n.t("Delete Invoice?"), isPresented: $showDeleteConfirm) {
            Button(L10n.t("Cancel"), role: .cancel) {}
            Button(L10n.t("Delete"), role: .destructive) { 
                print("✅ CONFIRMED DELETE - INVOICE")
                onDelete(invoice) 
            }
        } message: {
            Text(L10n.t("Are you sure you want to delete invoice \(invoice.number ?? "")?"))
        }
    }
    
    private func statusBadge(invoice: Document) -> some View {
        Text(statusDisplayName(invoice: invoice))
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor(invoice: invoice).opacity(0.2))
            .foregroundColor(statusColor(invoice: invoice))
            .cornerRadius(10)
    }
    
    private func statusDisplayName(invoice: Document) -> String {
        switch invoice.status?.lowercased() {
        case "draft": return "Brouillon"
        case "sent": return "Envoyé"
        case "paid": return "Payé"
        case "overdue": return "En retard"
        case "cancelled": return "Annulé"
        default: return invoice.status?.capitalized ?? "N/A"
        }
    }
    
    private func statusColor(invoice: Document) -> Color {
        switch invoice.status?.lowercased() {
        case "paid": return .green
        case "sent": return .blue
        case "overdue": return .red
        case "cancelled": return .gray
        case "draft": return .orange
        default: return .blue
        }
    }
    
    private func isPastDue(_ date: Date) -> Bool {
        date < Date()
    }
    
    private func getClientName(_ invoice: Document) -> String {
        if let client = invoice.safeClient {
            return client.name ?? L10n.t("No Client")
        }
        return L10n.t("No Client")
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

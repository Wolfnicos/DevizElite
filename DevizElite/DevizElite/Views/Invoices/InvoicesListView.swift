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
                }
            )
            
            StatusFilterView(selectedStatus: $selectedStatus)
            
            InvoiceStatsView(invoices: Array(invoices))
            
            List {
                ForEach(filteredInvoices) { invoice in
                    InvoiceRow(
                        invoice: invoice,
                        onEdit: { selectedInvoice = $0 },
                        onDelete: { deleteInvoice($0) }
                    )
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .listStyle(PlainListStyle())
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

    private func openInvoiceEditor(for document: Document?) {
        // Force BTP 2025 invoice template as default when opening
        UserDefaults.standard.set(TemplateStyle.BTP2025Invoice.rawValue, forKey: "templateStyle")
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
    
    var body: some View {
        HStack {
            TextField(L10n.t("Search invoices..."), text: $searchTerm)
                .textFieldStyle(ModernTextFieldStyle())
                .frame(maxWidth: 300)
            
            Spacer()
            
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
        .onTapGesture {
            onEdit(invoice)
        }
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

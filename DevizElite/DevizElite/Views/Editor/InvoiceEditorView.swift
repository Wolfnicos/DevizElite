//
//  InvoiceEditorView.swift
//  DevizElite
//
//  Created by App Gemini on 15/09/2025.
//

import SwiftUI
import CoreData

// VAT profiles for FR/BE construction
enum VATProfile: String, CaseIterable, Identifiable {
    case FR_Standard, FR_Intermediate, FR_Reduced, BE_Standard, BE_Renovation
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .FR_Standard: return "FR • TVA 20% (standard)"
        case .FR_Intermediate: return "FR • TVA 10% (renovation)"
        case .FR_Reduced: return "FR • TVA 5.5% (énergie)"
        case .BE_Standard: return "BE • TVA 21% (standard)"
        case .BE_Renovation: return "BE • TVA 6% (rénovation >10 ans)"
        }
    }
    var rate: Double {
        switch self {
        case .FR_Standard: return 20.0
        case .FR_Intermediate: return 10.0
        case .FR_Reduced: return 5.5
        case .BE_Standard: return 21.0
        case .BE_Renovation: return 6.0
        }
    }
}

struct InvoiceEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var i18n: LocalizationService
    
    @ObservedObject var document: Document
    @Binding var isPresented: Bool

    // Document fields
    @State private var invoiceNumber: String = ""
    @State private var issueDate: Date = Date()
    @State private var dueDate: Date = Date()
    @State private var selectedVATProfile: VATProfile = .FR_Standard
    // Construction-specific fields
    @State private var projectName: String = ""
    @State private var siteAddress: String = ""
    @State private var paymentTerms: String = ""
    @State private var validityDays: Int = 30
    @State private var retentionPercent: Double = 0
    
    // Client fields
    @State private var clientName: String = ""
    @State private var clientTaxId: String = ""
    @State private var clientAddress: String = ""
    @State private var clientPhone: String = ""
    @State private var clientEmail: String = ""

    // Line items
    @State private var lineItems: [ConstructionLineItem] = []
    
    // Totals
    @State private var subtotal: Double = 0
    @State private var totalTax: Double = 0
    @State private var totalAmount: Double = 0
    
    // UI State
    @State private var showCatalog = false

    var body: some View {
        HSplitView {
            editorForm
                .frame(minWidth: 500, idealWidth: 600)
            
            previewSection
                .frame(maxWidth: .infinity)
        }
        .onAppear(perform: loadDocumentData)
        .onAppear {
            // Apply default VAT from settings on first load for new docs
            if document.lineItems == nil || (document.lineItems as? Set<LineItem>)?.isEmpty == true {
                let rate = UserDefaults.standard.double(forKey: "defaultVATRate")
                if rate > 0 {
                    if rate == 20.0 { selectedVATProfile = .FR_Standard }
                    else if rate == 10.0 { selectedVATProfile = .FR_Intermediate }
                    else if rate == 5.5 { selectedVATProfile = .FR_Reduced }
                }
            }
        }
        .onChange(of: selectedVATProfile) { _, newVal in
            for idx in lineItems.indices { lineItems[idx].taxRate = newVal.rate }
            calculateTotals()
        }
    }
    
    private var editorForm: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    ClientSection(
                        name: $clientName,
                        taxId: $clientTaxId,
                        address: $clientAddress,
                        phone: $clientPhone,
                        email: $clientEmail
                    )
                    
                    InvoiceDetailsSection(
                        number: $invoiceNumber,
                        issueDate: $issueDate,
                        dueDate: $dueDate,
                        vatProfile: $selectedVATProfile,
                        projectName: $projectName,
                        siteAddress: $siteAddress,
                        paymentTerms: $paymentTerms,
                        validityDays: $validityDays,
                        retentionPercent: $retentionPercent
                    )
                    
                    ItemsSection(
                        lineItems: $lineItems,
                        vatDefault: selectedVATProfile.rate,
                        onAddFromCatalog: { showCatalog = true },
                        onChanged: calculateTotals
                    )
                    
                    TotalsSection(
                        subtotal: subtotal,
                        totalTax: totalTax,
                        totalAmount: totalAmount
                    )

                }
                .padding()
            }
            
            footerActions
        }
        .background(DesignSystem.Colors.surface)
        .sheet(isPresented: $showCatalog) {
            ConstructionCatalogSheet { selectedItem in
                var newItem = ConstructionLineItem(
                    description: selectedItem.name,
                    quantity: 1,
                    unit: selectedItem.unit,
                    unitPrice: selectedItem.price,
                    taxRate: selectedVATProfile.rate,
                    discount: 0
                )
                // ensure VAT from profile
                newItem.taxRate = selectedVATProfile.rate
                lineItems.append(newItem)
                calculateTotals()
            }
        }
    }

    private var previewSection: some View {
        // Scrollable PDF preview so header rămâne vizibil și conținutul curge în jos
        ScrollView {
            VStack(alignment: .leading) {
                let styleRaw = UserDefaults.standard.string(forKey: "templateStyle") ?? TemplateStyle.Modern.rawValue
                let style = TemplateStyle(rawValue: styleRaw) ?? .Modern
                PDFService.shared.sharedView(for: style, document: document)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .background(DesignSystem.Colors.background)
    }
    
    private var footerActions: some View {
        HStack {
            Button(role: .destructive) {
                deleteDocument()
                isPresented = false
            } label: {
                Label(L10n.t("Delete"), systemImage: "trash")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(L10n.t("Cancel")) {
                isPresented = false
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Spacer()
            
            Button(L10n.t("Save & Close")) {
                saveDocument()
                isPresented = false
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(DesignSystem.Colors.border), alignment: .top)
    }

    // MARK: - Data Logic

    private func loadDocumentData() {
        invoiceNumber = document.number ?? ""
        issueDate = document.issueDate ?? Date()
        dueDate = document.dueDate ?? Date()
        
        if let client = document.safeClient {
            clientName = client.name ?? ""
            clientTaxId = client.taxId ?? ""
            clientAddress = client.address ?? ""
            clientPhone = client.phone ?? ""
            clientEmail = client.contactEmail ?? ""
        }
        
        if let items = document.lineItems as? Set<LineItem> {
            lineItems = items
                .sorted { $0.position < $1.position }
                .compactMap { item in
                    guard !item.isFault else { return nil }
                    return ConstructionLineItem(
                        description: item.itemDescription ?? "",
                        quantity: (item.quantity as? Double) ?? 1.0,
                        unit: (item.value(forKey: "unit") as? String) ?? "",
                        unitPrice: (item.unitPrice as? Double) ?? 0.0,
                        taxRate: item.taxRate,
                        discount: item.discount
                    )
                }
        }
        // Load construction fields
        projectName = (document.value(forKey: "projectName") as? String) ?? ""
        siteAddress = (document.value(forKey: "siteAddress") as? String) ?? ""
        paymentTerms = (document.value(forKey: "paymentTerms") as? String) ?? ""
        if let vd = document.value(forKey: "validityDays") as? Int16 { validityDays = Int(vd) }
        retentionPercent = (document.value(forKey: "retentionPercent") as? Double) ?? 0
        calculateTotals()
    }

    private func deleteDocument() {
        viewContext.perform {
            viewContext.delete(document)
            do { try viewContext.save() } catch { print("Delete error: \(error)") }
        }
    }
    
    private func saveDocument() {
        viewContext.perform {
            document.number = invoiceNumber
            document.issueDate = issueDate
            document.dueDate = dueDate
            document.currencyCode = "EUR"
            
            // Save client
            let clientToUse: Client
            if let existingClient = document.safeClient {
                clientToUse = existingClient
            } else {
                clientToUse = Client(context: viewContext)
                clientToUse.id = UUID()
            }
            clientToUse.name = clientName
            clientToUse.taxId = clientTaxId
            clientToUse.address = clientAddress
            clientToUse.phone = clientPhone
            clientToUse.contactEmail = clientEmail
            document.client = clientToUse
            
            // Replace items
            if let existingItems = document.lineItems as? Set<LineItem> {
                existingItems.forEach(viewContext.delete)
            }
            for (index, item) in lineItems.enumerated() {
                let newItem = LineItem(context: viewContext)
                newItem.id = UUID()
                newItem.itemDescription = item.description
                newItem.quantity = NSDecimalNumber(value: item.quantity)
                newItem.unitPrice = NSDecimalNumber(value: item.unitPrice)
                newItem.taxRate = item.taxRate
                newItem.discount = item.discount
                newItem.setValue(item.unit, forKey: "unit")
                newItem.position = Int16(index)
                newItem.document = document
            }
            
            document.subtotal = NSDecimalNumber(value: subtotal)
            document.total = NSDecimalNumber(value: totalAmount)
            // Save construction-specific fields
            document.setValue(projectName, forKey: "projectName")
            document.setValue(siteAddress, forKey: "siteAddress")
            document.setValue(paymentTerms, forKey: "paymentTerms")
            document.setValue(Int16(validityDays), forKey: "validityDays")
            document.setValue(retentionPercent, forKey: "retentionPercent")

            do {
                try viewContext.save()
            } catch {
                print("Error saving document: \(error)")
            }
        }
    }
    
    private func calculateTotals() {
        subtotal = lineItems.reduce(0) { $0 + $1.total }
        totalTax = lineItems.reduce(0) { $0 + $1.taxAmount }
        totalAmount = subtotal + totalTax
    }
}

// MARK: - Subviews for Editor
private struct ClientSection: View {
    @Binding var name: String
    @Binding var taxId: String
    @Binding var address: String
    @Binding var phone: String
    @Binding var email: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Client").font(DesignSystem.Typography.title2)
            TextField("Name", text: $name).textFieldStyle(ModernTextFieldStyle())
            TextField("Tax ID", text: $taxId).textFieldStyle(ModernTextFieldStyle())
            TextField("Address", text: $address).textFieldStyle(ModernTextFieldStyle())
            TextField("Phone", text: $phone).textFieldStyle(ModernTextFieldStyle())
            TextField("Email", text: $email).textFieldStyle(ModernTextFieldStyle())
        }
    }
}

private struct InvoiceDetailsSection: View {
    @Binding var number: String
    @Binding var issueDate: Date
    @Binding var dueDate: Date
    @Binding var vatProfile: VATProfile
    @Binding var projectName: String
    @Binding var siteAddress: String
    @Binding var paymentTerms: String
    @Binding var validityDays: Int
    @Binding var retentionPercent: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Invoice Details").font(DesignSystem.Typography.title2)
            TextField("Invoice Number", text: $number).textFieldStyle(ModernTextFieldStyle())
            DatePicker("Issue Date", selection: $issueDate, displayedComponents: .date)
            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
            Picker("TVA", selection: $vatProfile) { ForEach(VATProfile.allCases) { p in Text(p.displayName).tag(p) } }
                .pickerStyle(.menu)
            Divider()
            Text("Construction").font(DesignSystem.Typography.headline)
            TextField("Project / Work name", text: $projectName).textFieldStyle(ModernTextFieldStyle())
            TextField("Site address", text: $siteAddress).textFieldStyle(ModernTextFieldStyle())
            TextField("Payment terms", text: $paymentTerms).textFieldStyle(ModernTextFieldStyle())
            HStack {
                TextField("Validity (days)", value: $validityDays, formatter: NumberFormatter()).frame(width: 140)
                TextField("Retention %", value: $retentionPercent, formatter: NumberFormatter()).frame(width: 140)
            }
        }
    }
}

private struct ItemsSection: View {
    @Binding var lineItems: [ConstructionLineItem]
    var vatDefault: Double
    var onAddFromCatalog: () -> Void
    var onChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Items").font(DesignSystem.Typography.title2)
            ForEach($lineItems) { $item in
                ItemRow(item: $item, onChanged: onChanged, onDelete: {
                    lineItems.removeAll { $0.id == item.id }
                    onChanged()
                })
            }
            HStack {
                Button(action: {
                    var it = ConstructionLineItem()
                    it.taxRate = vatDefault
                    lineItems.append(it)
                    onChanged()
                }) {
                    Label("Add Item", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: onAddFromCatalog) {
                    Label("Add from Catalog", systemImage: "book")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

private struct ItemRow: View {
    @Binding var item: ConstructionLineItem
    var onChanged: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            TextField("Description", text: $item.description)
            TextField("Qty", value: $item.quantity, formatter: NumberFormatter())
                .frame(width: 50)
            TextField("Unit", text: $item.unit)
                .frame(width: 60)
            TextField("Price", value: $item.unitPrice, formatter: NumberFormatter())
                .frame(width: 80)
            TextField("TVA %", value: $item.taxRate, formatter: NumberFormatter())
                .frame(width: 70)
            Button(action: onDelete) { Image(systemName: "trash") }
                .buttonStyle(PlainButtonStyle()).foregroundColor(.red)
        }
        .textFieldStyle(ModernTextFieldStyle(compact: true))
        .onChange(of: item) { _ in onChanged() }
    }
}

private struct TotalsSection: View {
    let subtotal: Double
    let totalTax: Double
    let totalAmount: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.sm) {
            HStack { Text("Subtotal:"); Spacer(); Text(formatCurrency(subtotal)) }
            HStack { Text("TVA:"); Spacer(); Text(formatCurrency(totalTax)) }
            HStack { Text("Total:").bold(); Spacer(); Text(formatCurrency(totalAmount)).bold() }
        }
        .font(DesignSystem.Typography.body)
    }
}

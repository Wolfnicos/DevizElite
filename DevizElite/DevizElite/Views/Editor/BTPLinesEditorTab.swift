import SwiftUI
import CoreData

struct BTPLinesEditorTab: View {
    @ObservedObject var document: Document
    @Binding var showingCatalog: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedLineItem: LineItem?
    @State private var groupByCorpsEtat = true
    @State private var showingCalculations = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("➕ Ajouter ligne") {
                    addNewLine()
                }
                .buttonStyle(.borderedProminent)
                
                Button("🏗️ Catalogue BTP") {
                    showingCatalog = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Toggle("Grouper par corps d'état", isOn: $groupByCorpsEtat)
                
                Button("🧮 Calculs") {
                    showingCalculations = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Liste des lignes
            if groupByCorpsEtat {
                GroupedLinesView(document: document, selectedLine: $selectedLineItem)
            } else {
                FlatLinesView(document: document, selectedLine: $selectedLineItem)
            }
        }
        .sheet(isPresented: $showingCalculations) {
            CalculationsDetailView(document: document)
        }
    }
    
    private func addNewLine() {
        let lineItem = LineItem(context: viewContext)
        lineItem.id = UUID()
        lineItem.itemDescription = "Nouvelle ligne"
        lineItem.quantity = NSDecimalNumber(value: 1)
        lineItem.unitPrice = NSDecimalNumber(value: 0)
        lineItem.taxRate = document.suggestedVATRate() * 100
        lineItem.position = Int16((document.lineItems?.count ?? 0) + 1)
        
        document.addToLineItems(lineItem)
        selectedLineItem = lineItem
        
        try? viewContext.save()
    }
}

// MARK: - Grouped Lines View
struct GroupedLinesView: View {
    @ObservedObject var document: Document
    @Binding var selectedLine: LineItem?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(groupedLineItems.keys.sorted(by: { $0?.rawValue ?? "zzz" < $1?.rawValue ?? "zzz" }), id: \.self) { corpsEtat in
                    CorpsEtatGroupView(
                        corpsEtat: corpsEtat,
                        lineItems: groupedLineItems[corpsEtat] ?? [],
                        selectedLine: $selectedLine,
                        document: document
                    )
                }
            }
            .padding()
        }
    }
    
    private var groupedLineItems: [CorpsEtat?: [LineItem]] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else {
            return [:]
        }
        
        return Dictionary(grouping: lineItems) { $0.corpsEtat }
    }
}

// MARK: - Corps d'État Group View
struct CorpsEtatGroupView: View {
    let corpsEtat: CorpsEtat?
    let lineItems: [LineItem]
    @Binding var selectedLine: LineItem?
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête du groupe
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: corpsEtat?.icon ?? "questionmark.circle")
                        .foregroundColor(corpsEtat?.color ?? .gray)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(corpsEtat?.localized ?? "Non classé")
                            .font(.headline)
                        
                        Text("\(lineItems.count) ligne(s) • Total: \(formatGroupTotal())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Badge catégorie
                    if let category = corpsEtat?.category {
                        Text(category.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(category.color.opacity(0.2))
                            .foregroundColor(category.color)
                            .cornerRadius(4)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(corpsEtat?.color.opacity(0.05) ?? Color.gray.opacity(0.05))
            )
            
            if isExpanded {
                // Lignes du groupe
                ForEach(lineItems.sorted(by: { $0.position < $1.position }), id: \.id) { lineItem in
                    BTPLineItemRow(
                        lineItem: lineItem,
                        isSelected: selectedLine == lineItem,
                        document: document
                    ) {
                        selectedLine = lineItem
                    }
                }
                
                // Bouton ajouter dans ce corps d'état
                Button(action: { addLineToCorpsEtat() }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Ajouter dans \(corpsEtat?.localized ?? "cette catégorie")")
                    }
                    .foregroundColor(.blue)
                    .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 20)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
    
    private func formatGroupTotal() -> String {
        let total = lineItems.reduce(0.0) { sum, item in
            let itemTotal = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
            let discount = itemTotal * (item.discount / 100.0)
            return sum + (itemTotal - discount)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: total)) ?? "0 €"
    }
    
    private func addLineToCorpsEtat() {
        let lineItem = LineItem(context: viewContext)
        lineItem.id = UUID()
        lineItem.itemDescription = "Nouvelle ligne \(corpsEtat?.localized ?? "")"
        lineItem.quantity = NSDecimalNumber(value: 1)
        lineItem.unitPrice = NSDecimalNumber(value: 0)
        lineItem.taxRate = document.suggestedVATRate() * 100
        lineItem.corpsEtat = corpsEtat
        lineItem.position = Int16((document.lineItems?.count ?? 0) + 1)
        
        document.addToLineItems(lineItem)
        selectedLine = lineItem
        
        try? viewContext.save()
    }
}

// MARK: - BTP Line Item Row
struct BTPLineItemRow: View {
    @ObservedObject var lineItem: LineItem
    let isSelected: Bool
    @ObservedObject var document: Document
    let onSelect: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingDetails = false
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Ligne principale
            HStack(spacing: 12) {
                // Sélection
                Button(action: onSelect) {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Lot number si défini
                if let lotNumber = lineItem.lotNumber, !lotNumber.isEmpty {
                    Text("LOT \(lotNumber)")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(3)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 2) {
                    if isEditing {
                        TextField("Description", text: Binding(
                            get: { lineItem.itemDescription ?? "" },
                            set: { lineItem.itemDescription = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text(lineItem.itemDescription ?? "")
                            .font(.system(size: 14))
                            .lineLimit(2)
                    }
                    
                    // Spécifications si définies
                    if let specs = lineItem.specifications, !specs.isEmpty {
                        Text("📋 \(specs)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Quantité et unité
                HStack(spacing: 4) {
                    if isEditing {
                        TextField("Qté", value: Binding(
                            get: { lineItem.quantity?.doubleValue ?? 0 },
                            set: { lineItem.quantity = NSDecimalNumber(value: $0) }
                        ), format: .number.precision(.fractionLength(0...2)))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    } else {
                        Text(String(format: "%.0f", lineItem.quantity?.doubleValue ?? 0))
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    // Unité BTP
                    UnitPickerView(lineItem: lineItem, isCompact: !isEditing)
                }
                
                // Prix unitaire
                VStack(alignment: .trailing, spacing: 1) {
                    if isEditing {
                        TextField("Prix HT", value: Binding(
                            get: { lineItem.unitPrice?.doubleValue ?? 0 },
                            set: { lineItem.unitPrice = NSDecimalNumber(value: $0) }
                        ), format: .currency(code: document.currencyCode ?? "EUR"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                    } else {
                        Text(formatCurrency(lineItem.unitPrice?.doubleValue ?? 0))
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    // Indicateur de marge si définie
                    if lineItem.marge > 0 {
                        Text("Marge: \(String(format: "%.1f", lineItem.marge))%")
                            .font(.caption2)
                            .foregroundColor(lineItem.isRentable ? .green : .orange)
                    }
                }
                
                // Total ligne
                VStack(alignment: .trailing, spacing: 1) {
                    Text(formatCurrency(lineTotal))
                        .font(.system(size: 14, weight: .semibold))
                    
                    if lineItem.discount > 0 {
                        Text("-\(String(format: "%.1f", lineItem.discount))%")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                // Actions
                HStack(spacing: 4) {
                    Button(action: { isEditing.toggle() }) {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingDetails = true }) {
                        Image(systemName: "ellipsis.circle")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
            
            // Planning dates si en mode détaillé
            if showingDetails {
                PlanningDatesView(lineItem: lineItem)
                    .padding(.top, 8)
            }
        }
        .onChange(of: isEditing) { oldValue, newValue in
            if !newValue {
                try? viewContext.save()
            }
        }
        .sheet(isPresented: $showingDetails) {
            LineItemDetailView(lineItem: lineItem, document: document)
        }
    }
    
    private var lineTotal: Double {
        let subtotal = (lineItem.unitPrice?.doubleValue ?? 0) * (lineItem.quantity?.doubleValue ?? 0)
        let discount = subtotal * (lineItem.discount / 100.0)
        return subtotal - discount
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

// MARK: - Unit Picker
struct UnitPickerView: View {
    @ObservedObject var lineItem: LineItem
    let isCompact: Bool
    
    var body: some View {
        if isCompact {
            Text(lineItem.uniteBTP?.rawValue ?? lineItem.unit ?? "u")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            Picker("Unité", selection: Binding(
                get: { lineItem.uniteBTP },
                set: { lineItem.uniteBTP = $0 }
            )) {
                Text("u").tag(nil as UniteBTP?)
                
                ForEach(UniteCategory.allCases, id: \.self) { category in
                    Section(category.rawValue) {
                        ForEach(UniteBTP.allCases.filter { $0.category == category }, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit as UniteBTP?)
                        }
                    }
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 60)
        }
    }
}

// MARK: - Planning Dates
struct PlanningDatesView: View {
    @ObservedObject var lineItem: LineItem
    
    var body: some View {
        HStack {
            Text("📅 Planning:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            DatePicker("Début", selection: Binding(
                get: { lineItem.workStartDate ?? Date() },
                set: { lineItem.workStartDate = $0 }
            ), displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(CompactDatePickerStyle())
            
            Text("→")
                .foregroundColor(.secondary)
            
            DatePicker("Fin", selection: Binding(
                get: { lineItem.workEndDate ?? Date() },
                set: { lineItem.workEndDate = $0 }
            ), displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(CompactDatePickerStyle())
            
            Spacer()
            
            Toggle("Terminé", isOn: Binding(
                get: { lineItem.isCompleted },
                set: { lineItem.isCompleted = $0 }
            ))
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(4)
    }
}

// MARK: - Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button(action: { configuration.isOn.toggle() }) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            configuration.label
                .font(.caption)
        }
    }
}

// MARK: - Flat Lines View
struct FlatLinesView: View {
    @ObservedObject var document: Document
    @Binding var selectedLine: LineItem?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if let lineItems = document.lineItems?.allObjects as? [LineItem] {
                    ForEach(lineItems.sorted(by: { $0.position < $1.position }), id: \.id) { lineItem in
                        BTPLineItemRow(
                            lineItem: lineItem,
                            isSelected: selectedLine == lineItem,
                            document: document
                        ) {
                            selectedLine = lineItem
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    
    return BTPLinesEditorTab(document: document, showingCatalog: .constant(false))
        .environment(\.managedObjectContext, context)
        .frame(width: 900, height: 600)
}
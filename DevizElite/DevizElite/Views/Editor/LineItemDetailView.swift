import SwiftUI
import CoreData

struct LineItemDetailView: View {
    @ObservedObject var lineItem: LineItem
    @ObservedObject var document: Document
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var editedDescription: String
    @State private var editedQuantity: Double
    @State private var editedUnitPrice: Double
    @State private var editedDiscount: Double
    @State private var editedTaxRate: Double
    @State private var editedUnit: String
    @State private var editedCorpsEtat: CorpsEtat?
    @State private var editedUniteBTP: UniteBTP?
    @State private var editedLotNumber: String
    @State private var editedSpecifications: String
    @State private var editedCoutAchat: Double
    @State private var editedMarge: Double
    @State private var editedWorkStartDate: Date?
    @State private var editedWorkEndDate: Date?
    @State private var editedIsCompleted: Bool
    
    init(lineItem: LineItem, document: Document) {
        self.lineItem = lineItem
        self.document = document
        self._editedDescription = State(initialValue: lineItem.itemDescription ?? "")
        self._editedQuantity = State(initialValue: lineItem.quantity?.doubleValue ?? 0.0)
        self._editedUnitPrice = State(initialValue: lineItem.unitPrice?.doubleValue ?? 0.0)
        self._editedDiscount = State(initialValue: lineItem.discount)
        self._editedTaxRate = State(initialValue: lineItem.taxRate)
        self._editedUnit = State(initialValue: lineItem.unit ?? "")
        self._editedCorpsEtat = State(initialValue: lineItem.corpsEtat)
        self._editedUniteBTP = State(initialValue: lineItem.uniteBTP)
        self._editedLotNumber = State(initialValue: lineItem.lotNumber ?? "")
        self._editedSpecifications = State(initialValue: lineItem.specifications ?? "")
        self._editedCoutAchat = State(initialValue: lineItem.coutAchat?.doubleValue ?? 0.0)
        self._editedMarge = State(initialValue: lineItem.marge)
        self._editedWorkStartDate = State(initialValue: lineItem.workStartDate)
        self._editedWorkEndDate = State(initialValue: lineItem.workEndDate)
        self._editedIsCompleted = State(initialValue: lineItem.isCompleted)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section("Informations de base") {
                    TextField("Description", text: $editedDescription)
                    
                    HStack {
                        TextField("Quantité", value: $editedQuantity, format: .number.precision(.fractionLength(0...3)))
                        
                        Picker("Unité", selection: $editedUniteBTP) {
                            Text("Standard").tag(nil as UniteBTP?)
                            
                            ForEach(UniteCategory.allCases, id: \.self) { category in
                                Section(category.rawValue) {
                                    ForEach(UniteBTP.allCases.filter { $0.category == category }, id: \.self) { unit in
                                        Text(unit.rawValue).tag(unit as UniteBTP?)
                                    }
                                }
                            }
                        }
                        .frame(width: 120)
                    }
                    
                    TextField("Prix unitaire HT", value: $editedUnitPrice, format: .currency(code: document.currencyCode ?? "EUR"))
                    
                    HStack {
                        TextField("Remise %", value: $editedDiscount, format: .percent.precision(.fractionLength(0...2)))
                        TextField("TVA %", value: $editedTaxRate, format: .percent.precision(.fractionLength(0...1)))
                    }
                }
                
                // BTP Classification
                Section("Classification BTP") {
                    Picker("Corps d'état", selection: $editedCorpsEtat) {
                        Text("Non défini").tag(nil as CorpsEtat?)
                        
                        ForEach(CorpsEtatCategory.allCases, id: \.self) { category in
                            Section(category.rawValue) {
                                ForEach(CorpsEtat.allCases.filter { $0.category == category }, id: \.self) { corps in
                                    HStack {
                                        Image(systemName: corps.icon)
                                            .foregroundColor(corps.color)
                                        Text(corps.localized)
                                    }
                                    .tag(corps as CorpsEtat?)
                                }
                            }
                        }
                    }
                    
                    TextField("Numéro de lot", text: $editedLotNumber)
                }
                
                // Technical Specifications
                Section("Spécifications techniques") {
                    TextField("Spécifications", text: $editedSpecifications, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Cost and Margin
                Section("Coûts et marge") {
                    TextField("Coût d'achat HT", value: $editedCoutAchat, format: .currency(code: document.currencyCode ?? "EUR"))
                    
                    if editedCoutAchat > 0 {
                        TextField("Marge %", value: $editedMarge, format: .percent.precision(.fractionLength(0...1)))
                        
                        HStack {
                            Text("Marge calculée:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(marginAmount))
                                .fontWeight(.semibold)
                                .foregroundColor(marginAmount > 0 ? .green : .red)
                        }
                        
                        HStack {
                            Text("Rentabilité:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(isRentable ? "✅ Rentable" : "⚠️ Non rentable")
                                .fontWeight(.semibold)
                                .foregroundColor(isRentable ? .green : .red)
                        }
                    }
                }
                
                // Planning
                Section("Planning") {
                    DatePicker("Date de début", selection: Binding(
                        get: { editedWorkStartDate ?? Date() },
                        set: { editedWorkStartDate = $0 }
                    ), displayedComponents: .date)
                    
                    DatePicker("Date de fin", selection: Binding(
                        get: { editedWorkEndDate ?? Date() },
                        set: { editedWorkEndDate = $0 }
                    ), displayedComponents: .date)
                    
                    Toggle("Travaux terminés", isOn: $editedIsCompleted)
                }
                
                // Totals
                Section("Totaux") {
                    HStack {
                        Text("Sous-total HT:")
                        Spacer()
                        Text(formatCurrency(subtotalHT))
                            .fontWeight(.semibold)
                    }
                    
                    if editedDiscount > 0 {
                        HStack {
                            Text("Remise:")
                            Spacer()
                            Text("-\(formatCurrency(discountAmount))")
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        Text("Net HT:")
                        Spacer()
                        Text(formatCurrency(netHT))
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("TVA:")
                        Spacer()
                        Text(formatCurrency(vatAmount))
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Total TTC:")
                        Spacer()
                        Text(formatCurrency(totalTTC))
                            .fontWeight(.bold)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Détails de ligne")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Enregistrer") {
                        saveChanges()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 600, height: 700)
    }
    
    // MARK: - Computed Properties
    
    private var subtotalHT: Double {
        editedQuantity * editedUnitPrice
    }
    
    private var discountAmount: Double {
        subtotalHT * (editedDiscount / 100.0)
    }
    
    private var netHT: Double {
        subtotalHT - discountAmount
    }
    
    private var vatAmount: Double {
        netHT * (editedTaxRate / 100.0)
    }
    
    private var totalTTC: Double {
        netHT + vatAmount
    }
    
    private var marginAmount: Double {
        let totalCost = editedCoutAchat * editedQuantity
        return netHT - totalCost
    }
    
    private var isRentable: Bool {
        guard editedCoutAchat > 0 else { return true }
        let totalCost = editedCoutAchat * editedQuantity
        return netHT > totalCost
    }
    
    // MARK: - Methods
    
    private func saveChanges() {
        lineItem.itemDescription = editedDescription
        lineItem.quantity = NSDecimalNumber(value: editedQuantity)
        lineItem.unitPrice = NSDecimalNumber(value: editedUnitPrice)
        lineItem.discount = editedDiscount
        lineItem.taxRate = editedTaxRate
        lineItem.unit = editedUnit
        lineItem.corpsEtat = editedCorpsEtat
        lineItem.uniteBTP = editedUniteBTP
        lineItem.lotNumber = editedLotNumber.isEmpty ? nil : editedLotNumber
        lineItem.specifications = editedSpecifications.isEmpty ? nil : editedSpecifications
        lineItem.coutAchat = NSDecimalNumber(value: editedCoutAchat)
        lineItem.marge = editedMarge
        lineItem.workStartDate = editedWorkStartDate
        lineItem.workEndDate = editedWorkEndDate
        lineItem.isCompleted = editedIsCompleted
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Erreur sauvegarde: \(error)")
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    let lineItem = LineItem(context: context)
    lineItem.itemDescription = "Test item"
    lineItem.quantity = NSDecimalNumber(value: 10)
    lineItem.unitPrice = NSDecimalNumber(value: 25.50)
    
    return LineItemDetailView(lineItem: lineItem, document: document)
        .environment(\.managedObjectContext, context)
}
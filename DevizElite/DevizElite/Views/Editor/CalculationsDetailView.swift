import SwiftUI
import CoreData

struct CalculationsDetailView: View {
    @ObservedObject var document: Document
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedTab = 0
    @State private var targetMargin: Double = 20.0
    @State private var showingExportOptions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tabs
                Picker("Vue", selection: $selectedTab) {
                    Text("Résumé").tag(0)
                    Text("Par Corps d'État").tag(1)
                    Text("Marges").tag(2)
                    Text("Rentabilité").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Divider()
                
                // Content based on selected tab
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        SummaryCalculationsView(document: document)
                    case 1:
                        CorpsEtatCalculationsView(document: document)
                    case 2:
                        MarginCalculationsView(document: document, targetMargin: $targetMargin)
                    case 3:
                        ProfitabilityAnalysisView(document: document)
                    default:
                        SummaryCalculationsView(document: document)
                    }
                }
            }
            .navigationTitle("Calculs Détaillés")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu("Actions") {
                        Button("📊 Export Excel") {
                            showingExportOptions = true
                        }
                        
                        Button("🧮 Calculateur Marge") {
                            // Open margin calculator
                        }
                        
                        Button("📋 Copier Résumé") {
                            copyCalculationsSummary()
                        }
                    }
                }
            }
        }
        .frame(width: 900, height: 700)
        .sheet(isPresented: $showingExportOptions) {
            ExcelExportView()
        }
    }
    
    private func copyCalculationsSummary() {
        let calculations = DocumentCalculations(document: document)
        let profitability = ProfitabilityCalculations(document: document)
        
        let summary = """
        RÉSUMÉ DES CALCULS - \(document.number ?? "N/A")
        
        TOTAUX FINANCIERS:
        - Sous-total HT: \(formatCurrency(calculations.subtotal))
        - Remises totales: \(formatCurrency(calculations.totalDiscounts))
        - Net HT: \(formatCurrency(calculations.netAmount))
        - TVA totale: \(formatCurrency(calculations.totalVAT))
        - Total TTC: \(formatCurrency(calculations.totalWithVAT))
        
        RENTABILITÉ:
        - Marge globale: \(String(format: "%.1f", profitability.globalMargin))%
        - Bénéfice: \(formatCurrency(profitability.totalProfit))
        - Rentabilité: \(String(format: "%.1f", profitability.profitability))%
        - Lignes rentables: \(profitability.profitableLines)/\(profitability.totalLines)
        
        Date: \(Date().formatted(date: .abbreviated, time: .shortened))
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(summary, forType: .string)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

// MARK: - Margin Calculator View
struct MarginCalculatorView: View {
    @ObservedObject var document: Document
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var baseCost: Double = 0
    @State private var targetMargin: Double = 20
    @State private var laborHours: Double = 0
    @State private var laborRate: Double = 45
    @State private var materialCost: Double = 0
    @State private var overheadPercent: Double = 15
    @State private var selectedCorpsEtat: CorpsEtat = .grosOeuvre
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                GroupBox("🧮 Calculateur de Marge") {
                    VStack(alignment: .leading, spacing: 16) {
                        // Input fields
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Paramètres de base")
                                .font(.headline)
                            
                            HStack {
                                Text("Corps d'état:")
                                    .frame(width: 120, alignment: .leading)
                                Picker("Corps d'état", selection: $selectedCorpsEtat) {
                                    ForEach(CorpsEtat.allCases, id: \.self) { corps in
                                        Text(corps.localized).tag(corps)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            HStack {
                                Text("Heures de travail:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Heures", value: $laborHours, format: .number.precision(.fractionLength(0...2)))
                                    .frame(width: 100)
                                Text("h")
                            }
                            
                            HStack {
                                Text("Taux horaire:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Taux", value: $laborRate, format: .currency(code: "EUR"))
                                    .frame(width: 100)
                            }
                            
                            HStack {
                                Text("Coût matériaux:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Matériaux", value: $materialCost, format: .currency(code: "EUR"))
                                    .frame(width: 100)
                            }
                            
                            HStack {
                                Text("Frais généraux:")
                                    .frame(width: 120, alignment: .leading)
                                Slider(value: $overheadPercent, in: 0...30, step: 1)
                                Text("\(String(format: "%.0f", overheadPercent))%")
                                    .frame(width: 40)
                            }
                            
                            HStack {
                                Text("Marge cible:")
                                    .frame(width: 120, alignment: .leading)
                                Slider(value: $targetMargin, in: 0...50, step: 1)
                                Text("\(String(format: "%.0f", targetMargin))%")
                                    .frame(width: 40)
                            }
                        }
                        
                        Divider()
                        
                        // Calculations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Résultats")
                                .font(.headline)
                            
                            HStack {
                                Text("Coût main-d'œuvre:")
                                Spacer()
                                Text(formatCurrency(laborCost))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Coût total direct:")
                                Spacer()
                                Text(formatCurrency(directCost))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Frais généraux:")
                                Spacer()
                                Text(formatCurrency(overheadCost))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Coût total:")
                                Spacer()
                                Text(formatCurrency(totalCost))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Prix de vente HT:")
                                Spacer()
                                Text(formatCurrency(sellingPrice))
                                    .fontWeight(.bold)
                                    .font(.title3)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Bénéfice:")
                                Spacer()
                                Text(formatCurrency(profit))
                                    .fontWeight(.bold)
                                    .foregroundColor(profit > 0 ? .green : .red)
                            }
                        }
                        
                        Divider()
                        
                        // Action buttons
                        HStack {
                            Button("Créer ligne de devis") {
                                createLineItem()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Spacer()
                            
                            Button("Réinitialiser") {
                                resetValues()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Calculateur de Marge")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Fermer") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
    
    // MARK: - Computed Properties
    
    private var laborCost: Double {
        laborHours * laborRate
    }
    
    private var directCost: Double {
        laborCost + materialCost
    }
    
    private var overheadCost: Double {
        directCost * (overheadPercent / 100)
    }
    
    private var totalCost: Double {
        directCost + overheadCost
    }
    
    private var sellingPrice: Double {
        totalCost * (1 + targetMargin / 100)
    }
    
    private var profit: Double {
        sellingPrice - totalCost
    }
    
    // MARK: - Methods
    
    private func createLineItem() {
        let lineItem = LineItem(context: viewContext)
        lineItem.id = UUID()
        lineItem.itemDescription = "Travaux \(selectedCorpsEtat.localized)"
        lineItem.quantity = NSDecimalNumber(value: 1)
        lineItem.unitPrice = NSDecimalNumber(value: sellingPrice)
        lineItem.taxRate = document.suggestedVATRate() * 100
        lineItem.corpsEtat = selectedCorpsEtat
        lineItem.coutAchat = NSDecimalNumber(value: totalCost)
        lineItem.marge = targetMargin
        lineItem.position = Int16((document.lineItems?.count ?? 0) + 1)
        
        document.addToLineItems(lineItem)
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Erreur création ligne: \(error)")
        }
    }
    
    private func resetValues() {
        baseCost = 0
        targetMargin = 20
        laborHours = 0
        laborRate = 45
        materialCost = 0
        overheadPercent = 15
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    
    return CalculationsDetailView(document: document)
        .environment(\.managedObjectContext, context)
}
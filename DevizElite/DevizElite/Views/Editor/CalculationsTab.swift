import SwiftUI
import CoreData

struct CalculationsTab: View {
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedCalculationType = 0
    @State private var showingMarginCalculator = false
    @State private var targetMargin: Double = 20.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Picker("Calculs", selection: $selectedCalculationType) {
                    Text("Résumé").tag(0)
                    Text("Par Corps d'État").tag(1)
                    Text("Marges").tag(2)
                    Text("Rentabilité").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 350)
                
                Spacer()
                
                Button("🧮 Calculateur") {
                    showingMarginCalculator = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Contenu selon le type de calcul sélectionné
            switch selectedCalculationType {
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
        .sheet(isPresented: $showingMarginCalculator) {
            MarginCalculatorView(document: document)
        }
    }
}

// MARK: - Summary Calculations
struct SummaryCalculationsView: View {
    @ObservedObject var document: Document
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Résumé financier principal
                FinancialSummaryCard(document: document)
                
                // Répartition TVA
                VATBreakdownCard(document: document)
                
                // Indicateurs de rentabilité
                ProfitabilityKPICard(document: document)
                
                // Comparaison avec les taux suggérés
                RecommendationsCard(document: document)
            }
            .padding()
        }
    }
}

struct FinancialSummaryCard: View {
    @ObservedObject var document: Document
    
    var body: some View {
        GroupBox("💰 Résumé Financier") {
            VStack(spacing: 12) {
                FinancialRow(label: "Sous-total HT", amount: calculations.subtotal, currency: document.currencyCode ?? "EUR")
                FinancialRow(label: "Remises totales", amount: calculations.totalDiscounts, currency: document.currencyCode ?? "EUR", isNegative: true)
                FinancialRow(label: "Net HT", amount: calculations.netAmount, currency: document.currencyCode ?? "EUR", isHighlighted: true)
                FinancialRow(label: "TVA totale", amount: calculations.totalVAT, currency: document.currencyCode ?? "EUR")
                
                Divider()
                
                FinancialRow(label: "Total TTC", amount: calculations.totalWithVAT, currency: document.currencyCode ?? "EUR", isTotal: true)
                
                if calculations.advance > 0 {
                    FinancialRow(label: "Acompte", amount: calculations.advance, currency: document.currencyCode ?? "EUR", isNegative: true)
                    FinancialRow(label: "Reste à payer", amount: calculations.remainingAmount, currency: document.currencyCode ?? "EUR", isHighlighted: true)
                }
            }
        }
    }
    
    private var calculations: DocumentCalculations {
        DocumentCalculations(document: document)
    }
}

struct FinancialRow: View {
    let label: String
    let amount: Double
    let currency: String
    var isNegative = false
    var isHighlighted = false
    var isTotal = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .body)
                .fontWeight(isHighlighted || isTotal ? .semibold : .regular)
            
            Spacer()
            
            Text(formatAmount(amount))
                .font(isTotal ? .headline : .body)
                .fontWeight(isHighlighted || isTotal ? .semibold : .regular)
                .foregroundColor(colorForAmount)
        }
    }
    
    private var colorForAmount: Color {
        if isTotal { return .primary }
        if isNegative { return .red }
        if isHighlighted { return .blue }
        return .primary
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return isNegative ? "-\(formatted)" : formatted
    }
}

struct VATBreakdownCard: View {
    @ObservedObject var document: Document
    
    var body: some View {
        GroupBox("📊 Répartition TVA") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(vatBreakdown, id: \.rate) { breakdown in
                    HStack {
                        Text("TVA \(String(format: "%.1f", breakdown.rate))%")
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Base: \(formatCurrency(breakdown.base))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatCurrency(breakdown.amount))
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private var vatBreakdown: [VATBreakdown] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return [] }
        
        let grouped = Dictionary(grouping: lineItems) { $0.taxRate }
        
        return grouped.map { rate, items in
            let base = items.reduce(0.0) { sum, item in
                let itemTotal = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
                let discount = itemTotal * (item.discount / 100.0)
                return sum + (itemTotal - discount)
            }
            let vatAmount = base * (rate / 100.0)
            
            return VATBreakdown(rate: rate, base: base, amount: vatAmount)
        }.sorted { $0.rate < $1.rate }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

struct VATBreakdown {
    let rate: Double
    let base: Double
    let amount: Double
}

// MARK: - Corps d'État Calculations
struct CorpsEtatCalculationsView: View {
    @ObservedObject var document: Document
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(corpsEtatBreakdown, id: \.corpsEtat) { breakdown in
                    CorpsEtatCalculationCard(breakdown: breakdown, document: document)
                }
            }
            .padding()
        }
    }
    
    private var corpsEtatBreakdown: [CorpsEtatBreakdown] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return [] }
        
        let grouped = Dictionary(grouping: lineItems) { $0.corpsEtat }
        
        return grouped.compactMap { corpsEtat, items in
            guard !items.isEmpty else { return nil }
            
            let subtotal = items.reduce(0.0) { sum, item in
                return sum + ((item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0))
            }
            
            let discounts = items.reduce(0.0) { sum, item in
                let itemTotal = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
                return sum + (itemTotal * (item.discount / 100.0))
            }
            
            let costs = items.reduce(0.0) { sum, item in
                return sum + ((item.coutAchat?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0))
            }
            
            return CorpsEtatBreakdown(
                corpsEtat: corpsEtat,
                itemCount: items.count,
                subtotal: subtotal,
                discounts: discounts,
                costs: costs,
                netAmount: subtotal - discounts
            )
        }.sorted { ($0.corpsEtat?.rawValue ?? "zzz") < ($1.corpsEtat?.rawValue ?? "zzz") }
    }
}

struct CorpsEtatBreakdown {
    let corpsEtat: CorpsEtat?
    let itemCount: Int
    let subtotal: Double
    let discounts: Double
    let costs: Double
    let netAmount: Double
    
    var margin: Double {
        guard costs > 0 else { return 0 }
        return ((netAmount - costs) / costs) * 100
    }
    
    var marginAmount: Double {
        return netAmount - costs
    }
}

struct CorpsEtatCalculationCard: View {
    let breakdown: CorpsEtatBreakdown
    @ObservedObject var document: Document
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // En-tête
                HStack {
                    HStack {
                        Image(systemName: breakdown.corpsEtat?.icon ?? "questionmark.circle")
                            .foregroundColor(breakdown.corpsEtat?.color ?? .gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(breakdown.corpsEtat?.localized ?? "Non classé")
                                .font(.headline)
                            
                            Text("\(breakdown.itemCount) ligne(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Badge catégorie
                    if let category = breakdown.corpsEtat?.category {
                        Text(category.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(category.color.opacity(0.2))
                            .foregroundColor(category.color)
                            .cornerRadius(4)
                    }
                }
                
                // Calculs
                VStack(spacing: 6) {
                    FinancialRow(label: "Sous-total", amount: breakdown.subtotal, currency: document.currencyCode ?? "EUR")
                    
                    if breakdown.discounts > 0 {
                        FinancialRow(label: "Remises", amount: breakdown.discounts, currency: document.currencyCode ?? "EUR", isNegative: true)
                    }
                    
                    FinancialRow(label: "Net", amount: breakdown.netAmount, currency: document.currencyCode ?? "EUR", isHighlighted: true)
                    
                    if breakdown.costs > 0 {
                        FinancialRow(label: "Coûts", amount: breakdown.costs, currency: document.currencyCode ?? "EUR", isNegative: true)
                        FinancialRow(label: "Marge", amount: breakdown.marginAmount, currency: document.currencyCode ?? "EUR")
                        
                        HStack {
                            Text("Taux de marge")
                            Spacer()
                            Text("\(String(format: "%.1f", breakdown.margin))%")
                                .fontWeight(.semibold)
                                .foregroundColor(breakdown.margin > 15 ? .green : breakdown.margin > 5 ? .orange : .red)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Margin Calculations
struct MarginCalculationsView: View {
    @ObservedObject var document: Document
    @Binding var targetMargin: Double
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Contrôles de marge cible
                GroupBox("🎯 Marge Cible") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Marge cible:")
                            Slider(value: $targetMargin, in: 0...50, step: 1)
                            Text("\(String(format: "%.0f", targetMargin))%")
                                .frame(width: 40)
                        }
                        
                        Button("Appliquer à toutes les lignes") {
                            applyTargetMargin()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // Analyse des marges par ligne
                GroupBox("📋 Analyse par Ligne") {
                    LazyVStack(spacing: 8) {
                        ForEach(marginAnalysis, id: \.lineItemId) { analysis in
                            MarginAnalysisRow(analysis: analysis, document: document)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var marginAnalysis: [LineMarginAnalysis] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return [] }
        
        return lineItems.map { item in
            let revenue = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
            let discount = revenue * (item.discount / 100.0)
            let netRevenue = revenue - discount
            let cost = (item.coutAchat?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
            
            let currentMargin = cost > 0 ? ((netRevenue - cost) / cost) * 100 : 0
            let targetPrice = cost > 0 ? cost * (1 + targetMargin / 100) : netRevenue
            
            return LineMarginAnalysis(
                lineItemId: item.id ?? UUID(),
                description: item.itemDescription ?? "",
                currentPrice: item.unitPrice?.doubleValue ?? 0.0,
                currentMargin: currentMargin,
                targetPrice: targetPrice / (item.quantity?.doubleValue ?? 1.0),
                targetMargin: targetMargin,
                cost: item.coutAchat?.doubleValue ?? 0.0,
                corpsEtat: item.corpsEtat
            )
        }
    }
    
    private func applyTargetMargin() {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return }
        
        for item in lineItems {
            guard let cost = item.coutAchat, cost.doubleValue > 0 else { continue }
            
            let targetPrice = cost.doubleValue * (1 + targetMargin / 100)
            item.unitPrice = NSDecimalNumber(value: targetPrice)
            item.marge = targetMargin
        }
        
        try? document.managedObjectContext?.save()
    }
}

struct LineMarginAnalysis {
    let lineItemId: UUID
    let description: String
    let currentPrice: Double
    let currentMargin: Double
    let targetPrice: Double
    let targetMargin: Double
    let cost: Double
    let corpsEtat: CorpsEtat?
}

struct MarginAnalysisRow: View {
    let analysis: LineMarginAnalysis
    @ObservedObject var document: Document
    
    var body: some View {
        HStack {
            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.description)
                    .font(.body)
                    .lineLimit(1)
                
                if let corpsEtat = analysis.corpsEtat {
                    Text(corpsEtat.localized)
                        .font(.caption)
                        .foregroundColor(corpsEtat.color)
                }
            }
            
            Spacer()
            
            // Prix et marges
            VStack(alignment: .trailing, spacing: 2) {
                HStack {
                    Text("Actuel:")
                    Text(formatCurrency(analysis.currentPrice))
                    Text("(\(String(format: "%.1f", analysis.currentMargin))%)")
                        .foregroundColor(marginColor(analysis.currentMargin))
                }
                .font(.caption)
                
                HStack {
                    Text("Cible:")
                    Text(formatCurrency(analysis.targetPrice))
                        .fontWeight(.semibold)
                    Text("(\(String(format: "%.1f", analysis.targetMargin))%)")
                        .foregroundColor(.blue)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func marginColor(_ margin: Double) -> Color {
        if margin > 20 { return .green }
        if margin > 10 { return .orange }
        return .red
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Profitability Analysis
struct ProfitabilityAnalysisView: View {
    @ObservedObject var document: Document
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Indicateurs clés
                ProfitabilityKPICard(document: document)
                
                // Analyse par corps d'état
                ProfitabilityByTradeCard(document: document)
                
                // Recommandations
                RecommendationsCard(document: document)
            }
            .padding()
        }
    }
}

struct ProfitabilityKPICard: View {
    @ObservedObject var document: Document
    
    var body: some View {
        GroupBox("📊 Indicateurs Clés") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                KPIIndicator(
                    title: "Marge Globale",
                    value: "\(String(format: "%.1f", calculations.globalMargin))%",
                    color: calculations.globalMargin > 15 ? .green : calculations.globalMargin > 5 ? .orange : .red,
                    icon: "percent"
                )
                
                KPIIndicator(
                    title: "Bénéfice",
                    value: formatCurrency(calculations.totalProfit),
                    color: calculations.totalProfit > 0 ? .green : .red,
                    icon: "banknote"
                )
                
                KPIIndicator(
                    title: "Rentabilité",
                    value: "\(String(format: "%.1f", calculations.profitability))%",
                    color: calculations.profitability > 10 ? .green : calculations.profitability > 3 ? .orange : .red,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                KPIIndicator(
                    title: "Lignes Rentables",
                    value: "\(calculations.profitableLines)/\(calculations.totalLines)",
                    color: calculations.profitableLines == calculations.totalLines ? .green : .orange,
                    icon: "checkmark.circle"
                )
            }
        }
    }
    
    private var calculations: ProfitabilityCalculations {
        ProfitabilityCalculations(document: document)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

struct KPIIndicator: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Document Calculations Helper
struct DocumentCalculations {
    let document: Document
    
    init(document: Document) {
        self.document = document
    }
    
    var subtotal: Double {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return 0 }
        
        return lineItems.reduce(0.0) { sum, item in
            sum + ((item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0))
        }
    }
    
    var totalDiscounts: Double {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return 0 }
        
        return lineItems.reduce(0.0) { sum, item in
            let itemTotal = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
            return sum + (itemTotal * (item.discount / 100.0))
        }
    }
    
    var netAmount: Double {
        return subtotal - totalDiscounts
    }
    
    var totalVAT: Double {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return 0 }
        
        return lineItems.reduce(0.0) { sum, item in
            let itemTotal = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
            let discount = itemTotal * (item.discount / 100.0)
            let netItemAmount = itemTotal - discount
            return sum + (netItemAmount * (item.taxRate / 100.0))
        }
    }
    
    var totalWithVAT: Double {
        return netAmount + totalVAT
    }
    
    var advance: Double {
        return document.advance?.doubleValue ?? 0.0
    }
    
    var remainingAmount: Double {
        return totalWithVAT - advance
    }
}

struct ProfitabilityCalculations {
    let document: Document
    
    init(document: Document) {
        self.document = document
    }
    
    var globalMargin: Double {
        let totalRevenue = DocumentCalculations(document: document).netAmount
        guard totalRevenue > 0, let lineItems = document.lineItems?.allObjects as? [LineItem] else { return 0 }
        
        let totalCosts = lineItems.reduce(0.0) { sum, item in
            sum + ((item.coutAchat?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0))
        }
        
        guard totalCosts > 0 else { return 0 }
        return ((totalRevenue - totalCosts) / totalCosts) * 100
    }
    
    var totalProfit: Double {
        let totalRevenue = DocumentCalculations(document: document).netAmount
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return 0 }
        
        let totalCosts = lineItems.reduce(0.0) { sum, item in
            sum + ((item.coutAchat?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0))
        }
        
        return totalRevenue - totalCosts
    }
    
    var profitability: Double {
        let totalRevenue = DocumentCalculations(document: document).netAmount
        guard totalRevenue > 0 else { return 0 }
        return (totalProfit / totalRevenue) * 100
    }
    
    var totalLines: Int {
        return document.lineItems?.count ?? 0
    }
    
    var profitableLines: Int {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return 0 }
        
        return lineItems.filter { $0.isRentable }.count
    }
}

struct ProfitabilityByTradeCard: View {
    @ObservedObject var document: Document
    
    var body: some View {
        GroupBox("🔧 Rentabilité par Corps d'État") {
            LazyVStack(spacing: 8) {
                ForEach(tradeAnalysis, id: \.corpsEtat) { analysis in
                    TradeAnalysisRow(analysis: analysis)
                }
            }
        }
    }
    
    private var tradeAnalysis: [TradeAnalysis] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else { return [] }
        
        let grouped = Dictionary(grouping: lineItems) { $0.corpsEtat }
        
        return grouped.compactMap { corpsEtat, items in
            let revenue = items.reduce(0.0) { sum, item in
                let itemTotal = (item.unitPrice?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0)
                let discount = itemTotal * (item.discount / 100.0)
                return sum + (itemTotal - discount)
            }
            
            let costs = items.reduce(0.0) { sum, item in
                return sum + ((item.coutAchat?.doubleValue ?? 0.0) * (item.quantity?.doubleValue ?? 0.0))
            }
            
            let margin = costs > 0 ? ((revenue - costs) / costs) * 100 : 0
            
            return TradeAnalysis(
                corpsEtat: corpsEtat,
                revenue: revenue,
                costs: costs,
                margin: margin,
                lineCount: items.count
            )
        }.sorted { ($0.corpsEtat?.rawValue ?? "zzz") < ($1.corpsEtat?.rawValue ?? "zzz") }
    }
}

struct TradeAnalysis {
    let corpsEtat: CorpsEtat?
    let revenue: Double
    let costs: Double
    let margin: Double
    let lineCount: Int
}

struct TradeAnalysisRow: View {
    let analysis: TradeAnalysis
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: analysis.corpsEtat?.icon ?? "questionmark.circle")
                    .foregroundColor(analysis.corpsEtat?.color ?? .gray)
                
                Text(analysis.corpsEtat?.localized ?? "Non classé")
                    .font(.body)
            }
            
            Spacer()
            
            Text("\(String(format: "%.1f", analysis.margin))%")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(analysis.margin > 15 ? .green : analysis.margin > 5 ? .orange : .red)
        }
        .padding(.vertical, 2)
    }
}

struct RecommendationsCard: View {
    @ObservedObject var document: Document
    
    var body: some View {
        GroupBox("💡 Recommandations") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text(recommendation)
                            .font(.body)
                    }
                }
            }
        }
    }
    
    private var recommendations: [String] {
        var suggestions: [String] = []
        
        let calculations = ProfitabilityCalculations(document: document)
        
        if calculations.globalMargin < 10 {
            suggestions.append("Considérez augmenter vos prix pour améliorer la marge globale")
        }
        
        if calculations.profitableLines < calculations.totalLines {
            suggestions.append("Analysez les lignes non rentables et ajustez les coûts ou prix")
        }
        
        if DocumentCalculations(document: document).totalDiscounts > DocumentCalculations(document: document).subtotal * 0.1 {
            suggestions.append("Les remises représentent plus de 10% du chiffre, vérifiez leur pertinence")
        }
        
        return suggestions.isEmpty ? ["Votre devis présente une bonne rentabilité"] : suggestions
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    
    return CalculationsTab(document: document)
        .environment(\.managedObjectContext, context)
        .frame(width: 900, height: 600)
}
import SwiftUI
import Combine

// MARK: - ChatBot Core cu Multiple Capabilități
class BTPIntelligentBot: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    
    // Servicii integrate
    private let priceService = PriceSearchService()
    private let analysisService = DocumentAnalysisService()
    private let aiService = AIService()
    
    init() {
        messages.append(ChatMessage(
            text: """
            🤖 Assistant BTP Intelligent disponible!
            
            Je peux:
            • 🔍 Rechercher prix actuels (matériaux, main d'œuvre)
            • 📊 Analyser vos factures/devis
            • 💰 Comparer fournisseurs en temps réel
            • 📈 Prédire coûts selon marché
            • ⚡ Calculer automatiquement quantités
            • 🏗 Suggérer alternatives économiques
            
            Comment puis-je vous aider?
            """,
            isBot: true,
            type: .welcome
        ))
    }
    
    func processMessage(_ text: String, context: Document? = nil) async {
        await MainActor.run {
            messages.append(ChatMessage(text: text, isBot: false))
            isLoading = true
        }
        
        // Analyse intention
        let intent = analyzeIntent(text)
        
        switch intent {
        case .searchPrice(let product):
            await searchRealTimePrice(product)
            
        case .analyzeDocument:
            if let doc = context {
                await analyzeDocument(doc)
            }
            
        case .compareSuppliers(let item):
            await compareSuppliers(item)
            
        case .calculateQuantity(let specs):
            await calculateNeededQuantity(specs)
            
        case .marketTrends(let category):
            await getMarketTrends(category)
            
        case .smartSuggestion:
            await provideSuggestions(context: context)
            
        default:
            await generalAIResponse(text, context: context)
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Intent Analysis
    private func analyzeIntent(_ text: String) -> BotIntent {
        let lowercased = text.lowercased()
        
        // Prix search patterns
        if lowercased.contains("prix") || lowercased.contains("coût") || lowercased.contains("tarif") {
            let product = extractProduct(from: text)
            return .searchPrice(product)
        }
        
        // Analysis patterns
        if lowercased.contains("analys") || lowercased.contains("vérif") || lowercased.contains("contrôl") {
            return .analyzeDocument
        }
        
        // Comparison patterns
        if lowercased.contains("compar") || lowercased.contains("fournisseur") {
            let item = extractItem(from: text)
            return .compareSuppliers(item)
        }
        
        // Quantity calculation patterns
        if lowercased.contains("calcul") || lowercased.contains("quantité") {
            let specs = extractSpecs(from: text)
            return .calculateQuantity(specs)
        }
        
        // Market trends patterns
        if lowercased.contains("tendance") || lowercased.contains("marché") || lowercased.contains("évolution") {
            let category = extractCategory(from: text)
            return .marketTrends(category)
        }
        
        // Suggestion patterns
        if lowercased.contains("optimis") || lowercased.contains("amélio") || lowercased.contains("conseil") {
            return .smartSuggestion
        }
        
        return .general
    }
    
    // MARK: - Prix en Temps Réel
    @MainActor
    private func searchRealTimePrice(_ product: String) async {
        let results = await priceService.searchCurrentPrices(for: product)
        
        var response = "📊 **Prix actuels pour \(product)**\n\n"
        
        for result in results.prefix(5) {
            response += """
            **\(result.supplier)**
            • Prix: \(String(format: "%.2f", result.price))€/\(result.unit)
            • Dispo: \(result.availability)
            • Mis à jour: \(DateFormatter.current.string(from: result.lastUpdate))
            
            """
        }
        
        // Analyse
        if let min = results.min(by: { $0.price < $1.price }),
           let max = results.max(by: { $0.price < $1.price }),
           !results.isEmpty {
            let avg = results.reduce(0) { $0 + $1.price } / Double(results.count)
            
            response += """
            
            📈 **Analyse marché:**
            • Meilleur prix: \(String(format: "%.2f", min.price))€ (\(min.supplier))
            • Prix moyen: \(String(format: "%.2f", avg))€
            • Écart max: \(String(format: "%.0f", ((max.price - min.price) / min.price) * 100))%
            
            💡 **Conseil:** Négociez avec \(min.supplier) pour quantité importante
            """
        }
        
        messages.append(ChatMessage(text: response, isBot: true, type: .priceSearch))
    }
    
    // MARK: - Analyse de Document
    @MainActor
    private func analyzeDocument(_ document: Document) async {
        let analysis = await analysisService.analyzeDocument(document)
        
        var response = "📊 **Analyse de votre document**\n\n"
        
        // Analyse des prix
        if !analysis.priceAnalysis.warnings.isEmpty {
            response += "⚠️ **Alertes Prix:**\n"
            for warning in analysis.priceAnalysis.warnings {
                response += "• \(warning)\n"
            }
            response += "\n"
        }
        
        // Catégories
        response += "📋 **Répartition par catégorie:**\n"
        for category in analysis.priceAnalysis.categories.prefix(5) {
            response += "• \(category.name): \(String(format: "%.0f", category.percentage))% (\(String(format: "%.2f", category.total))€)\n"
        }
        response += "\n"
        
        // Anomalies
        if !analysis.anomalies.isEmpty {
            response += "🔍 **Anomalies détectées:**\n"
            for anomaly in analysis.anomalies {
                response += "• \(anomaly)\n"
            }
            response += "\n"
        }
        
        // Optimisations
        if !analysis.optimizations.isEmpty {
            response += "💡 **Suggestions d'optimisation:**\n"
            for optimization in analysis.optimizations {
                response += "• \(optimization)\n"
            }
        }
        
        messages.append(ChatMessage(text: response, isBot: true, type: .documentAnalysis))
    }
    
    // MARK: - Comparison Fournisseurs
    @MainActor
    private func compareSuppliers(_ item: String) async {
        let results = await priceService.searchCurrentPrices(for: item)
        let groupedBySupplier = Dictionary(grouping: results) { $0.supplier }
        
        var response = "🔍 **Comparaison fournisseurs pour \(item)**\n\n"
        
        for (supplier, products) in groupedBySupplier.sorted(by: { $0.key < $1.key }) {
            let avgPrice = products.reduce(0) { $0 + $1.price } / Double(products.count)
            let availability = products.first?.availability ?? "N/A"
            
            response += """
            **\(supplier)**
            • Prix moyen: \(String(format: "%.2f", avgPrice))€
            • Disponibilité: \(availability)
            • Produits: \(products.count)
            
            """
        }
        
        messages.append(ChatMessage(text: response, isBot: true, type: .supplierComparison))
    }
    
    // MARK: - Calcul Quantités
    @MainActor
    private func calculateNeededQuantity(_ specs: String) async {
        // Simulation de calcul intelligent
        var response = "⚡ **Calcul automatique des quantités**\n\n"
        
        if specs.contains("m²") || specs.contains("surface") {
            response += """
            Pour une surface, voici les quantités typiques:
            • Béton: 0.15 m³/m² (dalle 15cm)
            • Armature: 15-20 kg/m³ de béton
            • Coffrage: 2-3 m²/m² de dalle
            • Main d'œuvre: 2-3h/m²
            
            💡 Ajoutez 10% de perte pour les matériaux
            """
        } else {
            response += """
            🤖 J'analyse vos spécifications...
            
            Pour un calcul précis, précisez:
            • Type de travaux (dalle, mur, cloison...)
            • Dimensions exactes
            • Matériaux souhaités
            """
        }
        
        messages.append(ChatMessage(text: response, isBot: true, type: .quantityCalculation))
    }
    
    // MARK: - Tendances Marché
    @MainActor
    private func getMarketTrends(_ category: String) async {
        var response = "📈 **Tendances marché 2025 - \(category)**\n\n"
        
        // Simulation données marché réelles
        let trends = [
            "Béton": (trend: "+8%", reason: "Hausse ciment et transport"),
            "Acier": (trend: "+15%", reason: "Tensions géopolitiques"),
            "Bois": (trend: "-5%", reason: "Surproduction nordique"),
            "Isolation": (trend: "+3%", reason: "Nouvelles normes RE2020"),
            "Électricité": (trend: "+12%", reason: "Hausse cuivre et électronique")
        ]
        
        for (material, info) in trends {
            if category.lowercased().contains(material.lowercased()) || category.isEmpty {
                response += """
                **\(material)**
                • Évolution: \(info.trend) vs 2024
                • Raison: \(info.reason)
                
                """
            }
        }
        
        response += """
        🎯 **Recommandations:**
        • Commandez tôt les matériaux en hausse
        • Profitez des baisses pour stocker
        • Négociez prix fixes pour gros projets
        """
        
        messages.append(ChatMessage(text: response, isBot: true, type: .marketTrends))
    }
    
    // MARK: - Suggestions Intelligentes
    @MainActor
    private func provideSuggestions(context: Document?) async {
        var response = "💡 **Suggestions d'optimisation**\n\n"
        
        if let doc = context {
            // Analyse du document pour suggestions contextuelles
            let total = doc.total?.doubleValue ?? 0
            
            if total > 10000 {
                response += """
                **Pour ce projet important (\(String(format: "%.0f", total))€):**
                • Négociez remises quantité (5-10%)
                • Étalez livraisons pour optimiser trésorerie
                • Vérifiez TVA selon zone géographique
                • Demandez garanties étendues
                
                """
            }
            
            // Suggestions selon le type
            if doc.type == "estimate" {
                response += """
                **Optimisations devis:**
                • Ajoutez marge négociation (10-15%)
                • Précisez conditions de révision prix
                • Incluez variantes économiques
                """
            } else {
                response += """
                **Optimisations facture:**
                • Vérifiez échéances paiement
                • Appliquez escompte si paiement comptant
                • Contrôlez TVA et retenues
                """
            }
        } else {
            response += """
            **Conseils généraux BTP 2025:**
            • Privilégiez matériaux locaux (-20% transport)
            • Planifiez selon météo (gains productivité)
            • Groupez commandes fournisseurs
            • Utilisez outils numériques (gains 15%)
            """
        }
        
        messages.append(ChatMessage(text: response, isBot: true, type: .suggestions))
    }
    
    // MARK: - Réponse IA Générale
    @MainActor
    private func generalAIResponse(_ text: String, context: Document?) async {
        // Détection si c'est une demande ChatGPT explicite
        let isGPTRequest = text.contains("[GPT]") || text.lowercased().contains("chatgpt") || text.lowercased().contains("gpt")
        
        let response = await aiService.generateSmartResponse(
            query: text,
            context: context,
            priceData: nil
        )
        
        // Ajouter indicateur ChatGPT si demandé
        let finalResponse = isGPTRequest ? "🤖 **ChatGPT Expert BTP:**\n\n\(response)" : response
        
        messages.append(ChatMessage(text: finalResponse, isBot: true, type: .general))
    }
    
    // MARK: - Helper Methods
    private func extractProduct(from text: String) -> String {
        // Extraction simple - améliorer avec NLP
        let products = ["béton", "ciment", "parpaing", "brique", "placo", "isolation", "acier", "fer"]
        for product in products {
            if text.lowercased().contains(product) {
                return product
            }
        }
        return "matériau de construction"
    }
    
    private func extractItem(from text: String) -> String {
        return extractProduct(from: text)
    }
    
    private func extractSpecs(from text: String) -> String {
        return text
    }
    
    private func extractCategory(from text: String) -> String {
        let categories = ["gros œuvre", "second œuvre", "finition", "électricité", "plomberie"]
        for category in categories {
            if text.lowercased().contains(category) {
                return category
            }
        }
        return ""
    }
}

// MARK: - Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isBot: Bool
    let timestamp = Date()
    let type: MessageType
    
    init(text: String, isBot: Bool, type: MessageType = .general) {
        self.text = text
        self.isBot = isBot
        self.type = type
    }
}

enum MessageType {
    case welcome
    case general
    case priceSearch
    case documentAnalysis
    case supplierComparison
    case quantityCalculation
    case marketTrends
    case suggestions
}

enum BotIntent {
    case searchPrice(String)
    case analyzeDocument
    case compareSuppliers(String)
    case calculateQuantity(String)
    case marketTrends(String)
    case smartSuggestion
    case general
}

// MARK: - Extensions
extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
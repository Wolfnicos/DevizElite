import Foundation

// MARK: - Analyse Intelligente de Documents
class DocumentAnalysisService {
    
    func analyzeDocument(_ document: Document) async -> DocumentAnalysis {
        var analysis = DocumentAnalysis()
        
        // 1. Analyse des prix
        analysis.priceAnalysis = analyzePrices(document)
        
        // 2. Détection anomalies
        analysis.anomalies = detectAnomalies(document)
        
        // 3. Suggestions optimisation
        analysis.optimizations = findOptimizations(document)
        
        // 4. Comparaison marché
        analysis.marketComparison = await compareWithMarket(document)
        
        // 5. Analyse TVA et conformité
        analysis.taxAnalysis = analyzeTaxCompliance(document)
        
        // 6. Analyse rentabilité
        analysis.profitabilityAnalysis = analyzeProfitability(document)
        
        return analysis
    }
    
    // MARK: - Analyse des Prix
    private func analyzePrices(_ doc: Document) -> PriceAnalysis {
        var analysis = PriceAnalysis()
        
        guard let lineItems = doc.lineItems?.allObjects as? [LineItem] else {
            return analysis
        }
        
        // Groupement par catégorie (Corps d'État)
        let grouped = Dictionary(grouping: lineItems) { $0.corpsEtat }
        let totalHT = doc.subtotal?.doubleValue ?? 0.0
        
        for (corpsEtat, items) in grouped {
            let categoryTotal = items.reduce(0.0) { sum, item in
                let quantity = item.quantity?.doubleValue ?? 0.0
                let unitPrice = item.unitPrice?.doubleValue ?? 0.0
                return sum + (quantity * unitPrice)
            }
            
            let percentage = totalHT > 0 ? (categoryTotal / totalHT) * 100 : 0
            
            analysis.categories.append(
                CategoryAnalysis(
                    name: corpsEtat?.localized ?? "Non classé",
                    total: categoryTotal,
                    percentage: percentage,
                    itemCount: items.count,
                    averageUnitPrice: categoryTotal / Double(items.count)
                )
            )
        }
        
        // Détection prix suspects
        for item in lineItems {
            let productName = item.itemDescription ?? "Produit inconnu"
            let unitPrice = item.unitPrice?.doubleValue ?? 0.0
            let marketPrice = getEstimatedMarketPrice(for: productName, category: item.corpsEtat)
            
            if marketPrice > 0 {
                let deviation = abs(unitPrice - marketPrice) / marketPrice
                
                if deviation > 0.3 { // Plus de 30% de différence
                    let status = unitPrice > marketPrice ? "⬆️ Cher" : "⬇️ Économique"
                    analysis.warnings.append(
                        "\(status) \(productName): \(String(format: "%.2f", unitPrice))€ (marché: \(String(format: "%.2f", marketPrice))€)"
                    )
                }
                
                if deviation > 0.5 { // Plus de 50% de différence - alerte rouge
                    analysis.criticalWarnings.append(
                        "🚨 Prix suspect: \(productName) - Écart de \(String(format: "%.0f", deviation * 100))% vs marché"
                    )
                }
            }
        }
        
        // Analyse des quantités
        analysis.quantityAnalysis = analyzeQuantities(lineItems)
        
        return analysis
    }
    
    // MARK: - Détection Anomalies
    private func detectAnomalies(_ doc: Document) -> [String] {
        var anomalies: [String] = []
        
        guard let lineItems = doc.lineItems?.allObjects as? [LineItem] else {
            return anomalies
        }
        
        // 1. Anomalies TVA
        let tvaAnomalies = detectTVAAnomalies(doc, lineItems: lineItems)
        anomalies.append(contentsOf: tvaAnomalies)
        
        // 2. Quantités suspectes
        let quantityAnomalies = detectQuantityAnomalies(lineItems)
        anomalies.append(contentsOf: quantityAnomalies)
        
        // 3. Prix incohérents
        let priceAnomalies = detectPriceAnomalies(lineItems)
        anomalies.append(contentsOf: priceAnomalies)
        
        // 4. Doublons potentiels
        let duplicateAnomalies = detectPotentialDuplicates(lineItems)
        anomalies.append(contentsOf: duplicateAnomalies)
        
        // 5. Cohérence dates
        let dateAnomalies = detectDateAnomalies(doc)
        anomalies.append(contentsOf: dateAnomalies)
        
        return anomalies
    }
    
    private func detectTVAAnomalies(_ doc: Document, lineItems: [LineItem]) -> [String] {
        var anomalies: [String] = []
        
        // Vérification selon le pays et type de travaux
        if doc.btpCountry == .france {
            for item in lineItems {
                let description = item.itemDescription?.lowercased() ?? ""
                let taxRate = item.taxRate
                
                // TVA réduite 5.5% pour rénovation énergétique
                if (description.contains("isolation") || description.contains("chaudière") || 
                    description.contains("fenêtre") || description.contains("pompe à chaleur")) && 
                   doc.typeTravaux?.isEnergyRenovation == true && taxRate != 5.5 {
                    anomalies.append("TVA 5.5% recommandée pour \(item.itemDescription ?? "cet item") (rénovation énergétique)")
                }
                
                // TVA 10% pour rénovation
                if doc.typeTravaux?.isRenovation == true && taxRate == 20.0 && 
                   !description.contains("neuf") {
                    anomalies.append("TVA 10% possible pour \(item.itemDescription ?? "cet item") (rénovation)")
                }
                
                // TVA 20% pour construction neuve
                if doc.typeTravaux?.isNewConstruction == true && taxRate != 20.0 {
                    anomalies.append("TVA 20% requise pour \(item.itemDescription ?? "cet item") (construction neuve)")
                }
            }
        } else if doc.btpCountry == .belgium {
            // Règles TVA Belgique
            for item in lineItems {
                let taxRate = item.taxRate
                if taxRate != 21.0 && taxRate != 6.0 {
                    anomalies.append("TVA Belgique: 21% standard ou 6% réduite attendue pour \(item.itemDescription ?? "cet item")")
                }
            }
        }
        
        return anomalies
    }
    
    private func detectQuantityAnomalies(_ lineItems: [LineItem]) -> [String] {
        var anomalies: [String] = []
        
        for item in lineItems {
            let quantity = item.quantity?.doubleValue ?? 0.0
            let unit = item.uniteBTP
            let description = item.itemDescription ?? ""
            
            // Quantités suspectes selon l'unité
            switch unit {
            case .m2:
                if quantity > 1000 {
                    anomalies.append("Quantité importante en m²: \(String(format: "%.0f", quantity))m² pour \(description)")
                }
            case .m3:
                if quantity > 500 {
                    anomalies.append("Volume important: \(String(format: "%.1f", quantity))m³ pour \(description)")
                }
            case .unite:
                if quantity > 10000 {
                    anomalies.append("Quantité très élevée: \(String(format: "%.0f", quantity)) unités pour \(description)")
                }
            default:
                break
            }
            
            // Quantités nulles ou négatives
            if quantity <= 0 {
                anomalies.append("Quantité nulle ou négative pour \(description)")
            }
        }
        
        return anomalies
    }
    
    private func detectPriceAnomalies(_ lineItems: [LineItem]) -> [String] {
        var anomalies: [String] = []
        
        for item in lineItems {
            let unitPrice = item.unitPrice?.doubleValue ?? 0.0
            let description = item.itemDescription ?? ""
            
            // Prix suspects
            if unitPrice <= 0 {
                anomalies.append("Prix unitaire nul pour \(description)")
            } else if unitPrice > 10000 {
                anomalies.append("Prix unitaire très élevé: \(String(format: "%.2f", unitPrice))€ pour \(description)")
            }
            
            // Cohérence prix/description
            if description.lowercased().contains("main d'œuvre") && unitPrice > 100 {
                anomalies.append("Prix main d'œuvre élevé: \(String(format: "%.2f", unitPrice))€/h pour \(description)")
            }
        }
        
        return anomalies
    }
    
    private func detectPotentialDuplicates(_ lineItems: [LineItem]) -> [String] {
        var anomalies: [String] = []
        var descriptions: [String: Int] = [:]
        
        for item in lineItems {
            let description = item.itemDescription ?? ""
            descriptions[description, default: 0] += 1
        }
        
        for (description, count) in descriptions where count > 1 {
            anomalies.append("Possible doublon: '\(description)' apparaît \(count) fois")
        }
        
        return anomalies
    }
    
    private func detectDateAnomalies(_ doc: Document) -> [String] {
        var anomalies: [String] = []
        
        // Vérification cohérence dates
        if let issueDate = doc.issueDate, let dueDate = doc.dueDate {
            if dueDate < issueDate {
                anomalies.append("Date d'échéance antérieure à la date d'émission")
            }
            
            let daysDifference = Calendar.current.dateComponents([.day], from: issueDate, to: dueDate).day ?? 0
            if daysDifference > 365 {
                anomalies.append("Échéance très lointaine: \(daysDifference) jours")
            }
        }
        
        // Vérification validité devis
        if doc.type == "estimate", let issueDate = doc.issueDate {
            let validityDate = Calendar.current.date(byAdding: .day, value: 30, to: issueDate) ?? issueDate
            if validityDate < Date() {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                anomalies.append("Devis expiré depuis le \(formatter.string(from: validityDate))")
            }
        }
        
        return anomalies
    }
    
    // MARK: - Suggestions d'Optimisation
    private func findOptimizations(_ doc: Document) -> [String] {
        var optimizations: [String] = []
        
        guard let lineItems = doc.lineItems?.allObjects as? [LineItem] else {
            return optimizations
        }
        
        let totalHT = doc.subtotal?.doubleValue ?? 0.0
        
        // 1. Optimisations budgétaires
        if totalHT > 50000 {
            optimizations.append("💰 Projet important: négociez remises quantité (5-10% possible)")
            optimizations.append("📅 Étalez les livraisons pour optimiser la trésorerie")
        }
        
        // 2. Optimisations TVA
        if doc.btpCountry == .france && doc.typeTravaux?.allowsReducedVAT == true {
            optimizations.append("💡 Vérifiez l'éligibilité à la TVA réduite (10% ou 5.5%)")
        }
        
        // 3. Regroupements possibles
        let supplierGroups = groupItemsBySupplier(lineItems)
        if supplierGroups.count > 3 {
            optimizations.append("🏭 Regroupez les achats par fournisseur pour réduire les frais de livraison")
        }
        
        // 4. Alternatives économiques
        optimizations.append(contentsOf: findCheaperAlternatives(lineItems))
        
        // 5. Optimisations de planning
        optimizations.append("⏰ Planifiez selon la météo pour optimiser la productivité")
        optimizations.append("📱 Utilisez des outils numériques pour gains de 15% en efficacité")
        
        return optimizations
    }
    
    // MARK: - Comparaison Marché
    private func compareWithMarket(_ doc: Document) async -> MarketComparison {
        var comparison = MarketComparison()
        
        guard let lineItems = doc.lineItems?.allObjects as? [LineItem] else {
            return comparison
        }
        
        let totalHT = doc.subtotal?.doubleValue ?? 0.0
        var marketTotal = 0.0
        
        for item in lineItems {
            let quantity = item.quantity?.doubleValue ?? 0.0
            let unitPrice = item.unitPrice?.doubleValue ?? 0.0
            _ = quantity * unitPrice
            
            let marketPrice = getEstimatedMarketPrice(for: item.itemDescription ?? "", category: item.corpsEtat)
            let marketItemTotal = quantity * marketPrice
            
            marketTotal += marketItemTotal
        }
        
        comparison.documentTotal = totalHT
        comparison.marketEstimate = marketTotal
        comparison.deviation = totalHT > 0 ? ((totalHT - marketTotal) / marketTotal) * 100 : 0
        comparison.savings = max(0, marketTotal - totalHT)
        comparison.overpayment = max(0, totalHT - marketTotal)
        
        if abs(comparison.deviation) > 10 {
            comparison.recommendation = comparison.deviation > 0 ? 
                "Prix supérieur au marché de \(String(format: "%.1f", comparison.deviation))%" :
                "Prix inférieur au marché de \(String(format: "%.1f", abs(comparison.deviation)))% - Vérifiez la qualité"
        } else {
            comparison.recommendation = "Prix en ligne avec le marché"
        }
        
        return comparison
    }
    
    // MARK: - Analyse TVA et Conformité
    private func analyzeTaxCompliance(_ doc: Document) -> TaxAnalysis {
        var analysis = TaxAnalysis()
        
        guard let lineItems = doc.lineItems?.allObjects as? [LineItem] else {
            return analysis
        }
        
        // Calcul TVA par taux
        var taxBreakdown: [Double: Double] = [:]
        
        for item in lineItems {
            let quantity = item.quantity?.doubleValue ?? 0.0
            let unitPrice = item.unitPrice?.doubleValue ?? 0.0
            let taxRate = item.taxRate
            let totalHT = quantity * unitPrice
            let taxAmount = totalHT * (taxRate / 100.0)
            
            taxBreakdown[taxRate, default: 0] += taxAmount
        }
        
        analysis.taxBreakdown = taxBreakdown
        analysis.totalTax = taxBreakdown.values.reduce(0, +)
        analysis.effectiveRate = (doc.subtotal?.doubleValue ?? 0) > 0 ? 
            (analysis.totalTax / (doc.subtotal?.doubleValue ?? 1)) * 100 : 0
        
        // Vérification conformité
        analysis.complianceIssues = []
        
        if doc.btpCountry == .france {
            if analysis.effectiveRate > 20.1 {
                analysis.complianceIssues.append("Taux effectif TVA > 20% - Vérifiez les calculs")
            }
        }
        
        return analysis
    }
    
    // MARK: - Analyse Rentabilité
    private func analyzeProfitability(_ doc: Document) -> ProfitabilityAnalysis {
        var analysis = ProfitabilityAnalysis()
        
        let totalHT = doc.subtotal?.doubleValue ?? 0.0
        
        // Estimation coûts selon catégories standard BTP
        let laborCostRatio = 0.4 // 40% main d'œuvre
        let materialCostRatio = 0.5 // 50% matériaux
        let overheadRatio = 0.1 // 10% frais généraux
        
        analysis.estimatedLaborCost = totalHT * laborCostRatio
        analysis.estimatedMaterialCost = totalHT * materialCostRatio
        analysis.estimatedOverhead = totalHT * overheadRatio
        analysis.estimatedTotalCost = analysis.estimatedLaborCost + analysis.estimatedMaterialCost + analysis.estimatedOverhead
        
        // Marge brute estimée
        analysis.grossProfit = totalHT - analysis.estimatedTotalCost
        analysis.grossMargin = totalHT > 0 ? (analysis.grossProfit / totalHT) * 100 : 0
        
        // Recommandations
        if analysis.grossMargin < 10 {
            analysis.recommendations.append("⚠️ Marge faible (<10%) - Revoyez vos prix")
        } else if analysis.grossMargin > 30 {
            analysis.recommendations.append("📈 Marge élevée (>30%) - Position concurrentielle forte")
        }
        
        return analysis
    }
    
    // MARK: - Helper Methods
    private func analyzeQuantities(_ lineItems: [LineItem]) -> QuantityAnalysis {
        var analysis = QuantityAnalysis()
        
        // Groupement par unité
        let unitGroups = Dictionary(grouping: lineItems) { $0.uniteBTP }
        
        for (unit, items) in unitGroups {
            let totalQuantity = items.reduce(0.0) { sum, item in
                sum + (item.quantity?.doubleValue ?? 0.0)
            }
            
            analysis.quantityByUnit[unit?.rawValue ?? "unknown"] = totalQuantity
        }
        
        return analysis
    }
    
    private func getEstimatedMarketPrice(for product: String, category: CorpsEtat?) -> Double {
        // Base de données prix simplifiée - en production, utiliser vraie API
        let priceDatabase: [String: Double] = [
            "béton": 85.0,
            "ciment": 12.5,
            "parpaing": 1.8,
            "brique": 0.45,
            "placo": 8.2,
            "isolation": 15.0,
            "carrelage": 25.0,
            "peinture": 35.0,
            "main d'œuvre": 45.0
        ]
        
        let productLower = product.lowercased()
        
        for (key, price) in priceDatabase {
            if productLower.contains(key) {
                // Ajustement selon catégorie
                let categoryMultiplier = getCategoryPriceMultiplier(category)
                return price * categoryMultiplier
            }
        }
        
        return 0.0 // Prix inconnu
    }
    
    private func getCategoryPriceMultiplier(_ category: CorpsEtat?) -> Double {
        guard let category = category else { return 1.0 }
        
        switch category {
        case .grosOeuvre:
            return 1.0
        case .charpente:
            return 1.2
        case .menuiserieExt:
            return 1.5
        case .cloisons:
            return 0.9
        case .sols:
            return 1.3
        case .peinture:
            return 1.1
        case .plomberie:
            return 1.4
        case .chauffage:
            return 1.6
        case .electricite:
            return 1.3
        case .vrd:
            return 1.1
        default:
            return 1.0
        }
    }
    
    private func groupItemsBySupplier(_ lineItems: [LineItem]) -> [String: [LineItem]] {
        // Simulation - en production, extraire vraie info fournisseur
        return Dictionary(grouping: lineItems) { item in
            let description = item.itemDescription?.lowercased() ?? ""
            if description.contains("point p") {
                return "Point P"
            } else if description.contains("leroy") {
                return "Leroy Merlin"
            } else if description.contains("brico") {
                return "Brico Dépôt"
            } else {
                return "Fournisseur local"
            }
        }
    }
    
    private func findCheaperAlternatives(_ lineItems: [LineItem]) -> [String] {
        var alternatives: [String] = []
        
        for item in lineItems {
            let description = item.itemDescription?.lowercased() ?? ""
            let unitPrice = item.unitPrice?.doubleValue ?? 0.0
            
            // Suggestions d'alternatives économiques
            if description.contains("brique") && unitPrice > 0.50 {
                alternatives.append("🧱 Alternative: Parpaing à la place de brique (économie ~30%)")
            }
            
            if description.contains("placo") && unitPrice > 10 {
                alternatives.append("🏠 Alternative: Carreau plâtre pour cloisons (économie ~20%)")
            }
            
            if description.contains("carrelage") && unitPrice > 30 {
                alternatives.append("🎨 Alternative: Sol souple ou stratifié (économie ~50%)")
            }
        }
        
        return alternatives
    }
}

// MARK: - Analysis Models
struct DocumentAnalysis {
    var priceAnalysis = PriceAnalysis()
    var anomalies: [String] = []
    var optimizations: [String] = []
    var marketComparison = MarketComparison()
    var taxAnalysis = TaxAnalysis()
    var profitabilityAnalysis = ProfitabilityAnalysis()
}

struct PriceAnalysis {
    var categories: [CategoryAnalysis] = []
    var warnings: [String] = []
    var criticalWarnings: [String] = []
    var quantityAnalysis = QuantityAnalysis()
}

struct CategoryAnalysis {
    let name: String
    let total: Double
    let percentage: Double
    let itemCount: Int
    let averageUnitPrice: Double
}

struct QuantityAnalysis {
    var quantityByUnit: [String: Double] = [:]
}

struct MarketComparison {
    var documentTotal: Double = 0
    var marketEstimate: Double = 0
    var deviation: Double = 0
    var savings: Double = 0
    var overpayment: Double = 0
    var recommendation: String = ""
}

struct TaxAnalysis {
    var taxBreakdown: [Double: Double] = [:]
    var totalTax: Double = 0
    var effectiveRate: Double = 0
    var complianceIssues: [String] = []
}

struct ProfitabilityAnalysis {
    var estimatedLaborCost: Double = 0
    var estimatedMaterialCost: Double = 0
    var estimatedOverhead: Double = 0
    var estimatedTotalCost: Double = 0
    var grossProfit: Double = 0
    var grossMargin: Double = 0
    var recommendations: [String] = []
}

// MARK: - Extensions pour TypeTravaux
extension TypeTravaux {
    var isEnergyRenovation: Bool {
        switch self {
        case .renovation:
            return true
        default:
            return false
        }
    }
    
    var isRenovation: Bool {
        switch self {
        case .renovation, .amenagement:
            return true
        default:
            return false
        }
    }
    
    var isNewConstruction: Bool {
        switch self {
        case .neuf:
            return true
        default:
            return false
        }
    }
    
    var allowsReducedVAT: Bool {
        return isRenovation || isEnergyRenovation
    }
}

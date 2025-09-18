import Foundation

// MARK: - Service Recherche Prix en Temps Réel
class PriceSearchService {
    
    struct PriceResult {
        let product: String
        let supplier: String
        let price: Double
        let unit: String
        let availability: String
        let lastUpdate: Date
        let url: String?
        let category: String
        let isPromotional: Bool
    }
    
    private let session = URLSession.shared
    
    func searchCurrentPrices(for product: String) async -> [PriceResult] {
        var results: [PriceResult] = []
        
        // 1. Recherche parallèle multi-fournisseurs
        async let pointP = searchPointP(product)
        async let leroyMerlin = searchLeroyMerlin(product)
        async let bricoDepot = searchBricoDepot(product)
        async let castorama = searchCastorama(product)
        
        // 2. Bases de données professionnelles
        async let indexBTP = searchIndexBTP(product)
        async let batiweb = searchBatiweb(product)
        
        // 3. Agrégation des résultats
        results.append(contentsOf: await pointP)
        results.append(contentsOf: await leroyMerlin)
        results.append(contentsOf: await bricoDepot)
        results.append(contentsOf: await castorama)
        results.append(contentsOf: await indexBTP)
        results.append(contentsOf: await batiweb)
        
        // 4. Ajout prix historiques simulés pour référence
        results.append(contentsOf: getHistoricalPrices(for: product))
        
        return results.sorted { $0.price < $1.price }
    }
    
    // MARK: - Point.P Professional
    private func searchPointP(_ query: String) async -> [PriceResult] {
        // Simulation API Point.P (remplacer par vraie API)
        let mockResults = generateMockResults(for: query, supplier: "Point.P", priceRange: (50, 200))
        
        // En production, utiliser:
        // let url = "https://api.pointp.fr/search?q=\(query.urlEncoded)"
        
        return mockResults
    }
    
    // MARK: - Leroy Merlin
    private func searchLeroyMerlin(_ query: String) async -> [PriceResult] {
        // Simulation scraping Leroy Merlin
        return generateMockResults(for: query, supplier: "Leroy Merlin", priceRange: (40, 180))
    }
    
    // MARK: - Brico Dépôt
    private func searchBricoDepot(_ query: String) async -> [PriceResult] {
        // Simulation Brico Dépôt (prix généralement plus bas)
        return generateMockResults(for: query, supplier: "Brico Dépôt", priceRange: (30, 150))
    }
    
    // MARK: - Castorama
    private func searchCastorama(_ query: String) async -> [PriceResult] {
        return generateMockResults(for: query, supplier: "Castorama", priceRange: (45, 175))
    }
    
    // MARK: - Index BTP Officiel
    private func searchIndexBTP(_ category: String) async -> [PriceResult] {
        // Base de données officielle des prix BTP
        let currentIndices: [String: Double] = [
            "béton": 115.4,
            "ciment": 142.7,
            "parpaing": 108.2,
            "brique": 121.5,
            "placo": 118.9,
            "isolation": 125.3,
            "acier": 189.2,
            "bois": 95.7
        ]
        
        var results: [PriceResult] = []
        
        for (material, index) in currentIndices {
            if category.lowercased().contains(material) {
                let basePrice = getBasePriceForMaterial(material)
                let adjustedPrice = basePrice * (index / 100.0)
                
                results.append(PriceResult(
                    product: "\(material.capitalized) (Index BTP)",
                    supplier: "Index BTP Officiel",
                    price: adjustedPrice,
                    unit: getUnitForMaterial(material),
                    availability: "Référence marché",
                    lastUpdate: Date(),
                    url: nil,
                    category: "Référence",
                    isPromotional: false
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Batiweb Professional Database
    private func searchBatiweb(_ query: String) async -> [PriceResult] {
        // Simulation base Batiweb
        return generateMockResults(for: query, supplier: "Batiweb Pro", priceRange: (60, 220))
    }
    
    // MARK: - Prix Historiques pour Référence
    private func getHistoricalPrices(for product: String) -> [PriceResult] {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        
        return [
            PriceResult(
                product: "\(product) (Prix il y a 1 mois)",
                supplier: "Historique",
                price: Double.random(in: 50...150),
                unit: "unité",
                availability: "Référence",
                lastUpdate: oneMonthAgo,
                url: nil,
                category: "Historique",
                isPromotional: false
            ),
            PriceResult(
                product: "\(product) (Prix il y a 6 mois)",
                supplier: "Historique",
                price: Double.random(in: 40...140),
                unit: "unité",
                availability: "Référence",
                lastUpdate: sixMonthsAgo,
                url: nil,
                category: "Historique",
                isPromotional: false
            )
        ]
    }
    
    // MARK: - Helper Methods
    private func generateMockResults(for query: String, supplier: String, priceRange: (Double, Double)) -> [PriceResult] {
        let variations = [
            ("Standard", 1.0),
            ("Premium", 1.3),
            ("Économique", 0.7),
            ("Professionnel", 1.15)
        ]
        
        var results: [PriceResult] = []
        
        for (variant, multiplier) in variations.prefix(Int.random(in: 2...4)) {
            let basePrice = Double.random(in: priceRange.0...priceRange.1)
            let finalPrice = basePrice * multiplier
            
            results.append(PriceResult(
                product: "\(query.capitalized) \(variant)",
                supplier: supplier,
                price: finalPrice,
                unit: getRandomUnit(),
                availability: getRandomAvailability(),
                lastUpdate: getRandomRecentDate(),
                url: "https://\(supplier.lowercased().replacingOccurrences(of: " ", with: "")).fr",
                category: categorizeProduct(query),
                isPromotional: Double.random(in: 0...1) < 0.2 // 20% chance of promo
            ))
        }
        
        return results
    }
    
    private func getRandomUnit() -> String {
        ["unité", "m²", "m³", "kg", "sac", "palette", "m", "lot"].randomElement() ?? "unité"
    }
    
    private func getRandomAvailability() -> String {
        [
            "En stock",
            "Sur commande (2-3j)",
            "Disponible sous 24h",
            "Stock limité",
            "Sur commande (1 semaine)"
        ].randomElement() ?? "En stock"
    }
    
    private func getRandomRecentDate() -> Date {
        let daysAgo = Int.random(in: 0...7)
        return Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }
    
    private func categorizeProduct(_ product: String) -> String {
        let categories: [String: String] = [
            "béton": "Gros œuvre",
            "ciment": "Gros œuvre",
            "parpaing": "Gros œuvre",
            "brique": "Gros œuvre",
            "placo": "Second œuvre",
            "isolation": "Second œuvre",
            "carrelage": "Finition",
            "peinture": "Finition",
            "électricité": "Équipements",
            "plomberie": "Équipements"
        ]
        
        for (key, category) in categories {
            if product.lowercased().contains(key) {
                return category
            }
        }
        
        return "Divers"
    }
    
    private func getBasePriceForMaterial(_ material: String) -> Double {
        let basePrices: [String: Double] = [
            "béton": 85.0,
            "ciment": 12.5,
            "parpaing": 1.8,
            "brique": 0.45,
            "placo": 8.2,
            "isolation": 15.0,
            "acier": 1.2,
            "bois": 450.0
        ]
        
        return basePrices[material] ?? 50.0
    }
    
    private func getUnitForMaterial(_ material: String) -> String {
        let units: [String: String] = [
            "béton": "m³",
            "ciment": "sac 25kg",
            "parpaing": "unité",
            "brique": "unité",
            "placo": "m²",
            "isolation": "m²",
            "acier": "kg",
            "bois": "m³"
        ]
        
        return units[material] ?? "unité"
    }
}

// MARK: - Extensions
extension String {
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
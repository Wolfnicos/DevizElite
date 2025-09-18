import Foundation
import SwiftUI
import Combine

// MARK: - BTP AI Assistant for pricing and product recommendations
class BTPAIAssistant: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isProcessing = false
    
    private let catalog = CatalogBTP()
    
    init() {
        // Add welcome message
        addBotMessage("""
        🤖 Bonjour! Je suis votre assistant BTP.
        
        Je peux vous aider avec:
        • 💰 Prix actuels des matériaux 2024-2025
        • 🔍 Recherche de produits dans le catalogue
        • 📊 Calculs de quantités et surfaces
        • ⚖️ Vérification des taux de TVA applicables
        • 🏗️ Recommandations par type de travaux
        • 💡 Produits éligibles aux aides (MaPrimeRénov', CEE)
        
        Que puis-je faire pour vous aujourd'hui?
        """)
    }
    
    func processUserMessage(_ text: String, for document: Document? = nil) {
        addUserMessage(text)
        isProcessing = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.generateResponse(for: text, document: document)
            self.isProcessing = false
        }
    }
    
    private func generateResponse(for query: String, document: Document?) {
        let lowercaseQuery = query.lowercased()
        
        if lowercaseQuery.contains("prix") || lowercaseQuery.contains("coût") || lowercaseQuery.contains("tarif") {
            handlePriceQuery(query)
        } else if lowercaseQuery.contains("tva") || lowercaseQuery.contains("taxe") {
            handleVATQuery(document)
        } else if lowercaseQuery.contains("isolation") {
            handleInsulationQuery()
        } else if lowercaseQuery.contains("chauffage") || lowercaseQuery.contains("pompe") || lowercaseQuery.contains("radiateur") {
            handleHeatingQuery()
        } else if lowercaseQuery.contains("catalogue") || lowercaseQuery.contains("produit") {
            handleCatalogQuery(query)
        } else if lowercaseQuery.contains("aide") || lowercaseQuery.contains("subvention") || lowercaseQuery.contains("maprimerenov") {
            handleGrantsQuery()
        } else if lowercaseQuery.contains("quantité") || lowercaseQuery.contains("calcul") || lowercaseQuery.contains("surface") {
            handleCalculationQuery(query)
        } else {
            handleGeneralQuery(query)
        }
    }
    
    private func handlePriceQuery(_ query: String) {
        let response = """
        📊 **Prix BTP actuels (Janvier 2025)**
        
        **Gros Œuvre:**
        • Béton C25/30 prêt à l'emploi: 320€/m³ (+8% vs 2024)
        • Mur parpaing 20cm: 75€/m² 
        • Dalle béton 15cm: 95€/m²
        
        **Isolation (éligible aides):**
        • Laine de verre R=5: 32€/m² (TVA 5.5%)
        • ITE polystyrène 140mm: 125€/m² (TVA 5.5%)
        • Laine de roche soufflée R=7: 18€/m² (TVA 5.5%)
        
        **Chauffage (éligible MaPrimeRénov'):**
        • PAC air/eau 14kW: 15 800€ (TVA 5.5%)
        • Chaudière gaz condensation: 3 200€ (TVA 5.5%)
        • Poêle à granulés 10kW: 4 500€ (TVA 5.5%)
        
        💡 Les prix incluent la pose et varient selon la région (+/-10%).
        """
        
        addBotMessage(response)
    }
    
    private func handleVATQuery(_ document: Document?) {
        let country = document?.btpCountry ?? .france
        let workType = document?.typeTravaux
        
        var response = "⚖️ **Taux de TVA applicables - \(country.flag) \(country.displayName)**\n\n"
        
        switch country {
        case .france:
            response += """
            **France 2024-2025:**
            • TVA 20% - Construction neuve, extension
            • TVA 10% - Rénovation (logement +2 ans)
            • TVA 5.5% - Rénovation énergétique éligible
            • TVA 2.1% - Logement social spécifique
            
            **Votre projet:**
            """
            if let type = workType {
                let suggestedRate = document?.suggestedVATRate() ?? 0.20
                response += "• \(type.localized): TVA \(Int(suggestedRate * 100))%"
            } else {
                response += "• Précisez le type de travaux pour le taux optimal"
            }
            
        case .belgium:
            response += """
            **Belgique 2024-2025:**
            • TVA 21% - Construction neuve
            • TVA 12% - Rénovation (logement +10 ans)
            • TVA 6% - Rénovation énergétique, logement social
            • TVA 0% - Exonérations spécifiques
            """
            
        case .luxembourg:
            response += """
            **Luxembourg 2024-2025:**
            • TVA 17% - Construction neuve
            • TVA 14% - Parking
            • TVA 8% - Rénovation
            • TVA 3% - Rénovation énergétique
            """
        }
        
        response += "\n\n💡 Consultez votre comptable pour validation finale."
        addBotMessage(response)
    }
    
    private func handleInsulationQuery() {
        let response = """
        🏠 **Produits isolation recommandés (éligibles aides 2025)**
        
        **Combles perdus:**
        • Laine de roche soufflée R=7: 18€/m² (TVA 5.5%)
        • Ouate de cellulose R=7: 22€/m² (TVA 5.5%)
        
        **Murs par l'extérieur (ITE):**
        • PSE TH32 140mm + enduit: 125€/m² (TVA 5.5%)
        • Laine de roche + bardage: 160€/m² (TVA 5.5%)
        
        **Murs par l'intérieur:**
        • Laine de verre R=5: 32€/m² (TVA 5.5%)
        • Polyuréthane projeté R=4.5: 35€/m² (TVA 5.5%)
        
        ✅ **Éligibilité MaPrimeRénov' 2025:**
        - Résistance thermique minimum: R≥3.7 (murs), R≥7 (combles)
        - Certification ACERMI obligatoire
        - Pose par professionnel RGE
        
        💰 **Aides cumulables:**
        - MaPrimeRénov': jusqu'à 100€/m²
        - CEE: jusqu'à 30€/m²
        - Éco-PTZ: financement 0% jusqu'à 50k€
        """
        
        addBotMessage(response)
    }
    
    private func handleHeatingQuery() {
        let response = """
        🔥 **Solutions chauffage recommandées (éligibles aides 2025)**
        
        **Pompes à chaleur (coup de pouce 2025):**
        • PAC air/eau 14kW COP 4.5: 15 800€ (TVA 5.5%)
        • PAC géothermique 12kW: 22 000€ (TVA 5.5%)
        • Aide MaPrimeRénov': jusqu'à 5 000€
        
        **Chaudières performantes:**
        • Gaz condensation 25kW: 3 200€ (TVA 5.5%)
        • Granulés/pellets 20kW: 8 500€ (TVA 5.5%)
        • Aide MaPrimeRénov': jusqu'à 3 000€
        
        **Chauffage bois:**
        • Poêle granulés étanche 10kW: 4 500€ (TVA 5.5%)
        • Insert/foyer fermé: 2 800€ (TVA 5.5%)
        • Aide MaPrimeRénov': jusqu'à 2 500€
        
        **Émetteurs basse température:**
        • Plancher chauffant hydraulique: 95€/m² (TVA 5.5%)
        • Radiateurs haute performance: 220€/u (TVA 5.5%)
        
        ⚡ **Conditions 2025:**
        - Installation par professionnel RGE QualiPAC/QualiBois
        - Étude thermique recommandée
        - Remplacement obligatoire chaudière >15 ans
        """
        
        addBotMessage(response)
    }
    
    private func handleCatalogQuery(_ query: String) {
        let searchResults = catalog.searchItems(query: query)
        
        if searchResults.isEmpty {
            addBotMessage("🔍 Aucun produit trouvé pour '\(query)'. Essayez avec d'autres mots-clés comme 'isolation', 'chauffage', 'carrelage', etc.")
            return
        }
        
        var response = "🔍 **Produits trouvés dans le catalogue:**\n\n"
        
        for (index, item) in searchResults.prefix(5).enumerated() {
            response += """
            **\(index + 1). \(item.designation)**
            • Code: \(item.code)
            • Prix: \(String(format: "%.2f", item.priceHT))€ HT/\(item.unit)
            • TVA: \(item.vatPercentage)%
            • Prix TTC: \(String(format: "%.2f", item.priceTTC))€
            """
            if let description = item.description {
                response += "\n• \(description)"
            }
            response += "\n\n"
        }
        
        if searchResults.count > 5 {
            response += "... et \(searchResults.count - 5) autres produits dans le catalogue.\n"
        }
        
        response += "💡 Cliquez sur 'Catalogue BTP' pour voir tous les produits et les ajouter à votre devis."
        
        addBotMessage(response)
    }
    
    private func handleGrantsQuery() {
        let response = """
        💰 **Aides et subventions BTP 2025**
        
        **MaPrimeRénov' (fusionnée CITE + ANAH):**
        • Isolation: jusqu'à 100€/m²
        • PAC air/eau: jusqu'à 5 000€
        • Chaudière biomasse: jusqu'à 8 000€
        • Poêle granulés: jusqu'à 2 500€
        
        **Conditions d'éligibilité:**
        - Logement de +2 ans
        - Professionnel certifié RGE
        - Devis avant signature MaPrimeRénov'
        - Plafonds de ressources selon couleur
        
        **CEE (Certificats Économies Énergie):**
        • Cumulable avec MaPrimeRénov'
        • Isolation combles: 10-30€/m²
        • PAC: 450-900€
        • Chaudière performante: 350-550€
        
        **Éco-PTZ 2025:**
        • Jusqu'à 50 000€ à taux 0%
        • Durée: 15-20 ans
        • Cumulable avec MaPrimeRénov'
        • 1 seul bouquet de travaux
        
        **TVA réduite 5.5%:**
        • Rénovation énergétique éligible
        • Pose + matériel inclus
        • Attestation client obligatoire
        
        🎯 **Conseil:** Planifiez les travaux par bouquets pour maximiser les aides!
        """
        
        addBotMessage(response)
    }
    
    private func handleCalculationQuery(_ query: String) {
        let response = """
        📐 **Calculateur BTP - Aide aux quantités**
        
        **Surfaces courantes:**
        • Mur: Longueur × Hauteur - ouvertures
        • Sol: Longueur × Largeur
        • Toiture: Surface au sol × 1.15 (pente 30°)
        
        **Volumes béton:**
        • Fondation: Longueur × Largeur × Épaisseur
        • Dalle: Surface × Épaisseur (+ 5% chute)
        • Poteaux: Section × Hauteur × Nombre
        
        **Isolation thermique:**
        • Combles perdus: Surface plancher × 1.1
        • Murs: Surface totale - 15% (ponts thermiques)
        • Toiture: Surface rampants × 1.05
        
        **Carrelage/peinture:**
        • Surface nette + 10% (découpes/chutes)
        • Joints: 1kg/10m² pour carrelage
        • Peinture: 1L pour 10-12m² (2 couches)
        
        **Quantités courantes:**
        • Mortier colle: 3-5kg/m² carrelage
        • Enduit: 1.5kg/m² en 2mm
        • Parpaing 20cm: 10 blocs/m²
        
        💡 Précisez vos mesures pour un calcul personnalisé!
        """
        
        addBotMessage(response)
    }
    
    private func handleGeneralQuery(_ query: String) {
        let response = """
        🤖 Je n'ai pas bien compris votre demande. 
        
        Voici ce que je peux faire pour vous:
        
        **Questions fréquentes:**
        • "Prix isolation 2025"
        • "TVA rénovation France"
        • "Aides pompe à chaleur"
        • "Calcul surface toiture"
        • "Produits chauffage catalogue"
        
        **Commandes rapides:**
        • Tapez "prix" pour les tarifs actuels
        • Tapez "tva" pour les taux applicables
        • Tapez "aides" pour les subventions 2025
        • Tapez "catalogue" pour rechercher des produits
        
        Que souhaitez-vous savoir exactement?
        """
        
        addBotMessage(response)
    }
    
    // MARK: - Helper methods
    private func addUserMessage(_ text: String) {
        let message = AIMessage(content: text, isBot: false)
        messages.append(message)
    }
    
    private func addBotMessage(_ text: String) {
        let message = AIMessage(content: text, isBot: true)
        messages.append(message)
    }
    
    // MARK: - Quick actions
    func getCurrentPrices() {
        handlePriceQuery("prix actuels")
    }
    
    func getVATInfo(for document: Document?) {
        handleVATQuery(document)
    }
    
    func getGrantsInfo() {
        handleGrantsQuery()
    }
    
    func searchProducts(_ query: String) {
        handleCatalogQuery(query)
    }
}

// MARK: - AI Message Model
struct AIMessage: Identifiable {
    let id = UUID()
    let content: String
    let isBot: Bool
    let timestamp = Date()
}

// MARK: - Extensions
extension Country {
    var displayName: String {
        switch self {
        case .france: return "France"
        case .belgium: return "Belgique" 
        case .luxembourg: return "Luxembourg"
        }
    }
}
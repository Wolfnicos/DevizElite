import Foundation

// MARK: - Intelligence Artificielle avec GPT Integration
class AIService {
    private let apiKey = "YOUR_OPENAI_API_KEY" // À configurer dans les settings
    private let model = "gpt-4"
    private let session = URLSession.shared
    
    func generateSmartResponse(
        query: String,
        context: Document?,
        priceData: [PriceSearchService.PriceResult]?
    ) async -> String {
        
        // Si pas d'API key, utiliser réponses pré-définies
        if apiKey == "YOUR_OPENAI_API_KEY" {
            return generateLocalResponse(query: query, context: context, priceData: priceData)
        }
        
        var systemPrompt = """
        Tu es un expert BTP avec 20 ans d'expérience en France et Belgique.
        Spécialités: factures, devis, prix, réglementation, optimisation.
        
        Contexte: Factures/Devis pour construction en France/Belgique.
        
        Données actuelles:
        - Date: \(DateFormatter.current.string(from: Date()))
        - Index BTP France: 115.2 (+2.3% vs 2024)
        - TVA France: 20% (normal), 10% (rénovation), 5.5% (énergie)
        - TVA Belgique: 21% (normal), 6% (réduite)
        
        Règles importantes:
        - Toujours donner des conseils pratiques et concrets
        - Mentionner la réglementation quand pertinent
        - Proposer des alternatives économiques
        - Utiliser des émojis pour clarifier
        - Être précis sur les prix et pourcentages
        """
        
        if let doc = context {
            let totalHT = doc.subtotal?.doubleValue ?? 0.0
            let itemCount = (doc.lineItems?.allObjects as? [LineItem])?.count ?? 0
            
            systemPrompt += """
            
            Document actuel:
            - Type: \(doc.type == "invoice" ? "Facture" : "Devis")
            - Client: \(doc.client?.name ?? "Non défini")
            - Pays: \(doc.btpCountry.name)
            - Total HT: \(String(format: "%.2f", totalHT))€
            - Articles: \(itemCount)
            - Type travaux: \(doc.typeTravaux?.localized ?? "Non défini")
            - Zone: \(doc.zoneTravaux?.localized ?? "Non définie")
            """
        }
        
        if let prices = priceData, !prices.isEmpty {
            systemPrompt += """
            
            Prix marché actuels trouvés:
            \(prices.prefix(5).map { "- \($0.product): \(String(format: "%.2f", $0.price))€/\($0.unit) chez \($0.supplier)" }.joined(separator: "\n"))
            """
        }
        
        let messages = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": query]
        ]
        
        // Appel OpenAI API
        let response = await callOpenAI(messages: messages)
        return response.isEmpty ? generateLocalResponse(query: query, context: context, priceData: priceData) : response
    }
    
    private func callOpenAI(messages: [[String: String]]) async -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return "Erreur configuration API"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500,
            "top_p": 1.0,
            "frequency_penalty": 0.0,
            "presence_penalty": 0.0
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return "Erreur API: \((response as? HTTPURLResponse)?.statusCode ?? 0)"
            }
            
            let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return json.choices.first?.message.content ?? "Pas de réponse de l'IA"
            
        } catch {
            print("Erreur OpenAI API: \(error)")
            return "Erreur de connexion à l'IA: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Réponses Locales Intelligentes
    private func generateLocalResponse(
        query: String,
        context: Document?,
        priceData: [PriceSearchService.PriceResult]?
    ) -> String {
        
        let queryLower = query.lowercased()
        
        // Réponses contextuelles selon le type de question
        if queryLower.contains("prix") || queryLower.contains("coût") {
            return generatePriceResponse(query: query, context: context, priceData: priceData)
        }
        
        if queryLower.contains("tva") || queryLower.contains("taxe") {
            return generateTaxResponse(context: context)
        }
        
        if queryLower.contains("optimis") || queryLower.contains("économi") {
            return generateOptimizationResponse(context: context)
        }
        
        if queryLower.contains("réglementation") || queryLower.contains("norme") {
            return generateRegulationResponse(context: context)
        }
        
        if queryLower.contains("marge") || queryLower.contains("rentabilité") {
            return generateProfitabilityResponse(context: context)
        }
        
        if queryLower.contains("fournisseur") || queryLower.contains("supplier") {
            return generateSupplierResponse(priceData: priceData)
        }
        
        if queryLower.contains("planning") || queryLower.contains("délai") {
            return generatePlanningResponse(context: context)
        }
        
        // Réponse générale avec conseils BTP
        return generateGeneralBTPResponse(query: query, context: context)
    }
    
    private func generatePriceResponse(query: String, context: Document?, priceData: [PriceSearchService.PriceResult]?) -> String {
        var response = "💰 **Analyse des prix BTP**\n\n"
        
        if let prices = priceData, !prices.isEmpty {
            response += "🔍 **Prix trouvés sur le marché:**\n"
            for price in prices.prefix(3) {
                response += "• \(price.supplier): \(String(format: "%.2f", price.price))€/\(price.unit)\n"
            }
            response += "\n"
        }
        
        response += """
        📊 **Conseils tarification 2025:**
        • Index BTP en hausse (+2.3% vs 2024)
        • Matériaux: +5 à +15% selon catégorie
        • Main d'œuvre: +3.5% (accords sociaux)
        • Transport: +8% (carburant et péages)
        
        💡 **Optimisations:**
        • Commandez tôt les matériaux stratégiques
        • Négociez prix fixes pour gros volumes
        • Privilégiez fournisseurs locaux (-20% transport)
        """
        
        if let doc = context {
            let total = doc.subtotal?.doubleValue ?? 0.0
            if total > 50000 {
                response += "\n\n🏗 **Pour votre projet (\(String(format: "%.0f", total))€):**\n"
                response += "• Remise quantité négociable: 5-10%\n"
                response += "• Échelonnement possible des paiements\n"
                response += "• Vérifiez garanties décennales incluses"
            }
        }
        
        return response
    }
    
    private func generateTaxResponse(context: Document?) -> String {
        var response = "📋 **Guide TVA BTP 2025**\n\n"
        
        if let doc = context {
            switch doc.btpCountry {
            case .france:
                response += """
                🇫🇷 **Taux TVA France:**
                • 20% - Construction neuve
                • 10% - Rénovation (logement +2 ans)
                • 5.5% - Rénovation énergétique
                • 2.1% - Médicaments (rare en BTP)
                
                """
                
                if let typeT = doc.typeTravaux {
                    switch typeT {
                    case .neuf:
                        response += "✅ **Votre projet:** TVA 20% (construction neuve)\n"
                    case .renovation:
                        response += "✅ **Votre projet:** TVA 10% possible (rénovation)\n"
                    case .amenagement:
                        response += "✅ **Votre projet:** TVA 5.5% possible (amélioration énergétique)\n"
                    case .entretien:
                        response += "✅ **Votre projet:** TVA 10% (entretien/réparation)\n"
                    case .reparation:
                        response += "✅ **Votre projet:** TVA 10% (réparation)\n"
                    case .extension:
                        response += "✅ **Votre projet:** TVA 20% (extension = neuf)\n"
                    }
                }
                
            case .belgium:
                response += """
                🇧🇪 **Taux TVA Belgique:**
                • 21% - Taux normal construction
                • 6% - Rénovation/démolition/reconstruction
                • 0% - Exportations (rare)
                
                ✅ **Votre projet:** Vérifiez éligibilité taux réduit 6%
                """
                
            case .luxembourg:
                response += """
                🇱🇺 **Taux TVA Luxembourg:**
                • 17% - Taux normal
                • 8% - Travaux sur logements
                • 3% - Cas particuliers
                """
            }
        } else {
            response += """
            **Règles générales:**
            • France: 20%/10%/5.5% selon type
            • Belgique: 21%/6%
            • Luxembourg: 17%/8%/3%
            
            💡 **Conseil:** Documentez bien le type de travaux
            """
        }
        
        response += """
        
        ⚠️ **Attention:**
        • Justificatifs obligatoires pour TVA réduite
        • Vérifiez âge du logement (>2 ans)
        • Listez précisément les travaux éligibles
        """
        
        return response
    }
    
    private func generateOptimizationResponse(context: Document?) -> String {
        var response = "⚡ **Guide d'optimisation BTP**\n\n"
        
        if let doc = context {
            let total = doc.subtotal?.doubleValue ?? 0.0
            let itemCount = (doc.lineItems?.allObjects as? [LineItem])?.count ?? 0
            
            response += "🎯 **Analyse de votre projet:**\n"
            response += "• Budget: \(String(format: "%.0f", total))€\n"
            response += "• Postes: \(itemCount) articles\n\n"
            
            if total < 5000 {
                response += """
                **Optimisations petit projet:**
                • Groupez commandes avec autres chantiers
                • Privilégiez magasins de proximité
                • Négociez enlèvement/livraison gratuite
                """
            } else if total < 25000 {
                response += """
                **Optimisations projet moyen:**
                • Demandez devis à 3 fournisseurs min
                • Négociez remise 3-5% sur total
                • Planifiez livraisons selon avancement
                """
            } else {
                response += """
                **Optimisations gros projet:**
                • Appel d'offres fournisseurs (10-15% économie)
                • Contrat cadre annuel si récurrent
                • Négociez conditions paiement (60-90j)
                • Stock intermédiaire si place disponible
                """
            }
        }
        
        response += """
        
        🏭 **Optimisations générales 2025:**
        • Circuit court: -15 à -25% vs grande distribution
        • Commandes groupées: -5 à -10%
        • Hors saison: -10 à -20% (novembre-février)
        • Digital: apps fournisseurs = -5% en moyenne
        
        ⏰ **Planning optimisé:**
        • Gros œuvre: printemps/été
        • Second œuvre: automne/hiver
        • Finitions: toute l'année
        """
        
        return response
    }
    
    private func generateRegulationResponse(context: Document?) -> String {
        return """
        📋 **Réglementation BTP 2025**
        
        🇫🇷 **France - Nouveautés:**
        • RE2020 obligatoire (construction neuve)
        • DPE nouvelle version depuis juillet 2024
        • Obligation recyclage déchets BTP
        • Carnet numérique logement
        
        🇧🇪 **Belgique:**
        • PEB (Performance Énergétique Bâtiment)
        • Normes NBN pour construction
        • Certificat conformité électrique
        
        ⚠️ **Points d'attention:**
        • Assurance décennale obligatoire
        • Déclaration préalable/permis selon surface
        • Respect normes accessibilité PMR
        • Gestion déchets avec bordereau
        
        📱 **Outils conformité:**
        • Attestation fin travaux
        • Certificats matériaux (CE)
        • PV réception travaux
        • Garanties constructeur
        """
    }
    
    private func generateProfitabilityResponse(context: Document?) -> String {
        var response = "📈 **Analyse rentabilité BTP**\n\n"
        
        if let doc = context {
            let total = doc.subtotal?.doubleValue ?? 0.0
            
            // Estimation marges standard BTP
            let estimatedCosts = total * 0.75 // 75% coûts moyens
            let grossProfit = total - estimatedCosts
            let margin = total > 0 ? (grossProfit / total) * 100 : 0
            
            response += """
            💰 **Votre projet (\(String(format: "%.0f", total))€):**
            • Coûts estimés: \(String(format: "%.0f", estimatedCosts))€ (75%)
            • Marge brute estimée: \(String(format: "%.0f", grossProfit))€
            • Taux marge: \(String(format: "%.1f", margin))%
            
            """
            
            if margin < 15 {
                response += "⚠️ **Marge faible:** Revoyez vos prix ou optimisez coûts\n"
            } else if margin > 30 {
                response += "✅ **Bonne marge:** Position concurrentielle forte\n"
            } else {
                response += "👍 **Marge correcte:** Dans la fourchette marché\n"
            }
        }
        
        response += """
        
        📊 **Marges moyennes BTP 2025:**
        • Gros œuvre: 12-18%
        • Charpente: 20-25%
        • Menuiserie: 25-35%
        • Électricité: 20-30%
        • Plomberie: 18-28%
        • Peinture: 30-40%
        
        💡 **Optimisation marge:**
        • Productivité: formation + outils
        • Négociation amont: fournisseurs
        • Spécialisation: niches rentables
        • Digital: réduction admin (5-10%)
        """
        
        return response
    }
    
    private func generateSupplierResponse(priceData: [PriceSearchService.PriceResult]?) -> String {
        var response = "🏭 **Guide fournisseurs BTP**\n\n"
        
        if let prices = priceData, !prices.isEmpty {
            let suppliers = Set(prices.map { $0.supplier })
            
            response += "🔍 **Fournisseurs identifiés:**\n"
            for supplier in suppliers.sorted() {
                let supplierPrices = prices.filter { $0.supplier == supplier }
                let avgPrice = supplierPrices.reduce(0) { $0 + $1.price } / Double(supplierPrices.count)
                response += "• \(supplier): ~\(String(format: "%.0f", avgPrice))€ en moyenne\n"
            }
            response += "\n"
        }
        
        response += """
        🎯 **Stratégie fournisseurs 2025:**
        
        **Gros volumes (>50k€):**
        • Point.P, Gedimat: négociation directe
        • Centrales d'achats: prix cadre
        • Producteurs: béton, granulats
        
        **Volumes moyens (10-50k€):**
        • Leroy Merlin Pro, Castorama Pro
        • Négociants locaux: relation durable
        • Groupements artisans: pouvoir d'achat
        
        **Dépannage/urgent:**
        • Brico Dépôt: prix bas, stock
        • Magasins de proximité: service
        • Plateformes en ligne: comparaison
        
        💡 **Conseils négociation:**
        • Demandez tarifs professionnels
        • Négociez délais paiement (30-60j)
        • Condition "prix révisable" si >6 mois
        • Clause force majeure (pénurie)
        """
        
        return response
    }
    
    private func generatePlanningResponse(context: Document?) -> String {
        return """
        ⏰ **Planning optimal BTP 2025**
        
        🌤 **Saisonnalité:**
        • Mars-Juin: gros œuvre (météo stable)
        • Juillet-Août: finitions extérieures
        • Sept-Nov: second œuvre intérieur
        • Déc-Fév: travaux intérieurs uniquement
        
        📅 **Délais moyens 2025:**
        • Permis construire: 2-3 mois
        • Livraison matériaux: +15-30% vs 2024
        • Gros œuvre: +10% (main d'œuvre rare)
        • Menuiserie sur mesure: 8-12 semaines
        
        ⚡ **Optimisation délais:**
        • Commande matériaux: +4 semaines sécurité
        • Planning glissant: 20% marge temporelle
        • Equipes polyvalentes: flexibilité
        • Stock tampon: 1 semaine matériaux critiques
        
        🎯 **Planning type maison 120m²:**
        • Terrassement: 1 semaine
        • Fondations: 1 semaine
        • Gros œuvre: 4-6 semaines
        • Charpente/couverture: 2 semaines
        • Clos/couvert: 2 semaines
        • Second œuvre: 8-10 semaines
        • Finitions: 4-6 semaines
        **Total: 5-7 mois**
        """
    }
    
    private func generateGeneralBTPResponse(query: String, context: Document?) -> String {
        let queryLower = query.lowercased()
        
        // Analyse contextuelle plus intelligente
        if queryLower.contains("comment") || queryLower.contains("pourquoi") {
            return generateExpertAdvice(query: query, context: context)
        }
        
        if queryLower.contains("combien") || queryLower.contains("coût") {
            return generateCostEstimation(query: query, context: context)
        }
        
        if queryLower.contains("meilleur") || queryLower.contains("recommand") {
            return generateRecommendations(query: query, context: context)
        }
        
        // Réponse contextuelle selon le document
        var response = "🏗️ **Expert BTP - Analyse personnalisée**\n\n"
        
        if let doc = context {
            let total = doc.total?.doubleValue ?? 0
            let country = doc.btpCountry.name
            let type = doc.type == "invoice" ? "facture" : "devis"
            
            response += "📊 **Contexte de votre \(type):**\n"
            response += "• Montant: \(String(format: "%.0f", total))€\n"
            response += "• Pays: \(country)\n"
            
            if total > 50000 {
                response += "\n💡 **Conseils pour gros projet:**\n"
                response += "• Négociez remise quantité 5-10%\n"
                response += "• Demandez garanties étendues\n"
                response += "• Planifiez livraisons étalées\n"
            }
            
            // Conseils spécifiques selon le pays
            switch doc.btpCountry {
            case .france:
                response += "\n🇫🇷 **Spécificités France:**\n"
                response += "• TVA: 20% neuf, 10% rénovation, 5.5% énergie\n"
                response += "• Index BTP: +2.3% en 2025\n"
                response += "• RE2020 obligatoire construction neuve\n"
            case .belgium:
                response += "\n🇧🇪 **Spécificités Belgique:**\n"
                response += "• TVA: 21% normal, 6% rénovation\n"
                response += "• PEB obligatoire\n"
                response += "• Normes NBN construction\n"
            case .luxembourg:
                response += "\n🇱🇺 **Spécificités Luxembourg:**\n"
                response += "• TVA: 17% normal, 8% logements\n"
                response += "• Marché stable, prix élevés\n"
            }
        }
        
        response += """
        
        🎯 **Questions que vous pouvez me poser:**
        
        💬 **Exemples concrets:**
        • "Quel est le prix actuel du béton C25/30?"
        • "Comment optimiser ce devis de 45k€?"
        • "Quelle TVA pour rénovation énergétique?"
        • "Comparez Point.P vs Leroy Merlin pour l'isolation"
        • "Planning optimal pour maison 120m²"
        • "Marges normales en électricité?"
        
        🚀 **Je peux analyser:**
        • Vos documents (anomalies, optimisations)
        • Prix marché en temps réel
        • Tendances BTP 2025
        • Réglementation par pays
        """
        
        return response
    }
    
    private func generateExpertAdvice(query: String, context: Document?) -> String {
        return """
        👨‍🔧 **Conseil d'expert BTP:**
        
        Basé sur 20 ans d'expérience dans le secteur, voici mon analyse:
        
        🎯 **Approche recommandée:**
        • Analysez d'abord le marché local
        • Comparez 3 fournisseurs minimum
        • Vérifiez la réglementation applicable
        • Planifiez selon la saisonnalité
        
        📊 **Facteurs clés 2025:**
        • Inflation matériaux: +5 à +15%
        • Pénurie main d'œuvre qualifiée
        • Normes environnementales renforcées
        • Digitalisation des processus
        
        💡 **Astuce professionnelle:**
        Privilégiez toujours la qualité à long terme plutôt que l'économie immédiate. Un bon matériau aujourd'hui évite 3x plus de coûts demain.
        """
    }
    
    private func generateCostEstimation(query: String, context: Document?) -> String {
        return """
        💰 **Estimation coûts BTP 2025:**
        
        📈 **Fourchettes moyennes (France):**
        • Gros œuvre: 800-1200€/m²
        • Charpente bois: 50-80€/m²
        • Couverture tuiles: 45-65€/m²
        • Isolation combles: 20-40€/m²
        • Électricité complète: 80-120€/m²
        • Plomberie sanitaire: 70-100€/m²
        • Carrelage pose: 35-60€/m²
        
        ⚠️ **Variables importantes:**
        • +20% en zone tendue (Paris, Lyon...)
        • +15% pour chantiers difficiles d'accès
        • -10% pour gros volumes négociés
        • +25% pour finitions haut de gamme
        
        🎯 **Pour estimation précise:**
        Précisez: surface, localisation, type de travaux, niveau de finition souhaité.
        """
    }
    
    private func generateRecommendations(query: String, context: Document?) -> String {
        return """
        🏆 **Recommandations d'expert BTP:**
        
        🥇 **Top fournisseurs 2025:**
        
        **Gros volumes professionnel:**
        • Point.P - Leader, service, stock
        • Gedimat - Réseau dense, conseil technique
        • BigMat - Indépendants, prix négociables
        
        **Volume moyen/particulier:**
        • Leroy Merlin Pro - Gamme large, prix fixes
        • Castorama Pro - Promotions fréquentes
        • Brico Dépôt - Discount, basique
        
        **Spécialisés:**
        • Saint-Gobain - Innovation, technique
        • Lafarge - Bétons, granulats
        • Isover - Isolation thermique
        
        💡 **Stratégie gagnante:**
        1. Négociez prix cadre annuel (>5% économie)
        2. Groupez commandes entre chantiers
        3. Payez comptant = -2% escompte
        4. Livraisons programmées = service gratuit
        """
    }
}

// MARK: - OpenAI Response Models
struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let current: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
}
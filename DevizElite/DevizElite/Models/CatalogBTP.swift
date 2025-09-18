import Foundation
import SwiftUI
import CoreData

// MARK: - Catalog Produits/Services Construction
class CatalogBTP: ObservableObject {
    
    enum Category: String, CaseIterable, Identifiable {
        case grosOeuvre = "Gros Œuvre"
        case maconnerie = "Maçonnerie" 
        case charpente = "Charpente"
        case couverture = "Couverture"
        case menuiserie = "Menuiserie"
        case plomberie = "Plomberie"
        case electricite = "Électricité"
        case isolation = "Isolation"
        case carrelage = "Carrelage"
        case peinture = "Peinture"
        case terrassement = "Terrassement"
        case chauffage = "Chauffage"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .grosOeuvre: return "building.2"
            case .maconnerie: return "rectangle.stack"
            case .charpente: return "house.lodge"
            case .couverture: return "house"
            case .menuiserie: return "door.left.hand.open"
            case .plomberie: return "drop"
            case .electricite: return "bolt"
            case .isolation: return "thermometer"
            case .carrelage: return "grid"
            case .peinture: return "paintbrush"
            case .terrassement: return "mountain.2"
            case .chauffage: return "flame"
            }
        }
        
        var color: Color {
            switch self {
            case .grosOeuvre: return .brown
            case .maconnerie: return .gray
            case .charpente: return Color(red: 0.6, green: 0.4, blue: 0.2)
            case .couverture: return .red
            case .menuiserie: return Color(red: 0.8, green: 0.6, blue: 0.4)
            case .plomberie: return .blue
            case .electricite: return .yellow
            case .isolation: return .green
            case .carrelage: return .purple
            case .peinture: return .pink
            case .terrassement: return Color(red: 0.4, green: 0.3, blue: 0.2)
            case .chauffage: return .orange
            }
        }
    }
    
    struct CatalogItem: Codable, Identifiable {
        var id = UUID()
        var code: String
        var designation: String
        var description: String?
        var category: String
        var unit: String // m², ml, u, forfait
        var priceHT: Double
        var vatRate: Double // 0.055, 0.10 ou 0.20
        var image: String? // nom de l'image
        
        // Prix selon type de travaux
        var priceNeuf: Double?
        var priceRenovation: Double?
        
        // Propriétés calculées
        var priceTTC: Double {
            priceHT * (1 + vatRate)
        }
        
        var vatPercentage: Int {
            Int(vatRate * 100)
        }
    }
    
    @Published var catalogItems: [CatalogItem] = []
    
    init() {
        loadCatalog()
    }
    
    private func loadCatalog() {
        catalogItems = [
            // GROS ŒUVRE - Prix 2024-2025 actualisés (+8% inflation)
            CatalogItem(
                code: "GO001",
                designation: "Fondation béton armé C25/30",
                description: "Béton prêt à l'emploi, ferraillage HA10-HA12, coffrage bois/métal inclus",
                category: Category.grosOeuvre.rawValue,
                unit: "m³",
                priceHT: 320.00,
                vatRate: 0.20
            ),
            CatalogItem(
                code: "GO002",
                designation: "Mur parpaing 20cm",
                description: "Parpaing creux 20x20x50, mortier colle, joints horizontaux",
                category: Category.grosOeuvre.rawValue,
                unit: "m²",
                priceHT: 75.00,
                vatRate: 0.20
            ),
            CatalogItem(
                code: "GO003",
                designation: "Dalle béton 15cm",
                description: "Béton C25/30 sur polyane, treillis ST25C, finition talochée",
                category: Category.grosOeuvre.rawValue,
                unit: "m²",
                priceHT: 95.00,
                vatRate: 0.20
            ),
            CatalogItem(
                code: "GO004",
                designation: "Poteau béton armé",
                description: "Béton C25/30, armatures HA10-HA16, coffrage modulaire",
                category: Category.grosOeuvre.rawValue,
                unit: "ml",
                priceHT: 135.00,
                vatRate: 0.20
            ),
            
            // COUVERTURE
            CatalogItem(
                code: "CO001",
                designation: "Tuiles terre cuite",
                description: "Tuiles mécaniques, pose et liteaux",
                category: Category.couverture.rawValue,
                unit: "m²",
                priceHT: 75.00,
                vatRate: 0.10,
                priceNeuf: 75.00,
                priceRenovation: 95.00
            ),
            CatalogItem(
                code: "CO002",
                designation: "Ardoises naturelles",
                description: "Ardoises 40x20, crochets inox",
                category: Category.couverture.rawValue,
                unit: "m²",
                priceHT: 120.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "CO003",
                designation: "Zinc joint debout",
                description: "Zinc VMZ, soudures étain",
                category: Category.couverture.rawValue,
                unit: "m²",
                priceHT: 95.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "CO004",
                designation: "Gouttière zinc 25cm",
                description: "Zinc naturel, crochets inclus",
                category: Category.couverture.rawValue,
                unit: "ml",
                priceHT: 45.00,
                vatRate: 0.10
            ),
            
            // ISOLATION - Prix 2024-2025 avec éligibilité MaPrimeRénov'
            CatalogItem(
                code: "IS001",
                designation: "Isolation laine de verre 200mm R=5.0",
                description: "Éligible MaPrimeRénov' - Laine de verre semi-rigide, pare-vapeur inclus",
                category: Category.isolation.rawValue,
                unit: "m²",
                priceHT: 32.00,
                vatRate: 0.055 // TVA réduite 5.5% rénovation énergétique
            ),
            CatalogItem(
                code: "IS002",
                designation: "ITE Polystyrène 140mm + enduit",
                description: "Éligible MaPrimeRénov' - PSE TH32, fixation mécanique, enduit mince",
                category: Category.isolation.rawValue,
                unit: "m²",
                priceHT: 125.00,
                vatRate: 0.055
            ),
            CatalogItem(
                code: "IS003",
                designation: "Laine de roche soufflée combles R=7",
                description: "Éligible MaPrimeRénov' - Laine de roche vrac, pont thermique réduit",
                category: Category.isolation.rawValue,
                unit: "m²",
                priceHT: 18.00,
                vatRate: 0.055
            ),
            CatalogItem(
                code: "IS004",
                designation: "Polyuréthane projeté 100mm",
                description: "Isolation continue, performance thermique optimale R=4.5",
                category: Category.isolation.rawValue,
                unit: "m²",
                priceHT: 35.00,
                vatRate: 0.055
            ),
            
            // MENUISERIE
            CatalogItem(
                code: "ME001",
                designation: "Fenêtre PVC double vitrage",
                description: "2 vantaux, 120x140cm, Uw=1.3",
                category: Category.menuiserie.rawValue,
                unit: "unité",
                priceHT: 420.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "ME002",
                designation: "Porte d'entrée PVC",
                description: "Porte pleine, serrure 5 points",
                category: Category.menuiserie.rawValue,
                unit: "unité",
                priceHT: 850.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "ME003",
                designation: "Volet roulant électrique",
                description: "Aluminium, moteur Somfy",
                category: Category.menuiserie.rawValue,
                unit: "unité",
                priceHT: 650.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "ME004",
                designation: "Cloison placo 70mm",
                description: "Rails 70, montants, BA13",
                category: Category.menuiserie.rawValue,
                unit: "m²",
                priceHT: 45.00,
                vatRate: 0.10
            ),
            
            // PLOMBERIE
            CatalogItem(
                code: "PL001",
                designation: "WC suspendu complet",
                description: "Bâti support, cuvette, plaque",
                category: Category.plomberie.rawValue,
                unit: "unité",
                priceHT: 580.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "PL002",
                designation: "Chauffe-eau thermodynamique 200L",
                description: "COP 3.5, garantie 5 ans",
                category: Category.plomberie.rawValue,
                unit: "unité",
                priceHT: 2450.00,
                vatRate: 0.055
            ),
            CatalogItem(
                code: "PL003",
                designation: "Douche italienne",
                description: "Receveur 90x120, paroi verre",
                category: Category.plomberie.rawValue,
                unit: "forfait",
                priceHT: 1200.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "PL004",
                designation: "Réseau eau froide/chaude",
                description: "PER 16/20, collecteurs inclus",
                category: Category.plomberie.rawValue,
                unit: "poste",
                priceHT: 320.00,
                vatRate: 0.10
            ),
            
            // ÉLECTRICITÉ
            CatalogItem(
                code: "EL001",
                designation: "Tableau électrique 3 rangées",
                description: "Coffret équipé, disjoncteurs, différentiels",
                category: Category.electricite.rawValue,
                unit: "unité",
                priceHT: 650.00,
                vatRate: 0.20
            ),
            CatalogItem(
                code: "EL002",
                designation: "Point lumineux simple",
                description: "Câblage, interrupteur, boîte DCL",
                category: Category.electricite.rawValue,
                unit: "unité",
                priceHT: 85.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "EL003",
                designation: "Prise de courant 16A",
                description: "Prise 2P+T, câblage 2.5mm²",
                category: Category.electricite.rawValue,
                unit: "unité",
                priceHT: 45.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "EL004",
                designation: "Éclairage LED encastré",
                description: "Spot LED 7W, blanc chaud",
                category: Category.electricite.rawValue,
                unit: "unité",
                priceHT: 65.00,
                vatRate: 0.10
            ),
            
            // CARRELAGE
            CatalogItem(
                code: "CA001",
                designation: "Carrelage grès cérame 60x60",
                description: "Pose droite, colle, joints",
                category: Category.carrelage.rawValue,
                unit: "m²",
                priceHT: 65.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "CA002",
                designation: "Faïence murale",
                description: "30x60, pose droite",
                category: Category.carrelage.rawValue,
                unit: "m²",
                priceHT: 55.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "CA003",
                designation: "Parquet chêne massif",
                description: "14mm, vernis usine",
                category: Category.carrelage.rawValue,
                unit: "m²",
                priceHT: 85.00,
                vatRate: 0.10
            ),
            
            // PEINTURE
            CatalogItem(
                code: "PE001",
                designation: "Peinture murs et plafonds",
                description: "2 couches, impression, enduit",
                category: Category.peinture.rawValue,
                unit: "m²",
                priceHT: 18.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "PE002",
                designation: "Peinture façade",
                description: "Traitement, fixateur, 2 couches",
                category: Category.peinture.rawValue,
                unit: "m²",
                priceHT: 35.00,
                vatRate: 0.10
            ),
            CatalogItem(
                code: "PE003",
                designation: "Enduit décoratif intérieur",
                description: "Enduit à effet, finition lissée",
                category: Category.peinture.rawValue,
                unit: "m²",
                priceHT: 45.00,
                vatRate: 0.10
            ),
            
            // CHAUFFAGE - Prix 2024-2025 avec éligibilités aides
            CatalogItem(
                code: "CH001",
                designation: "Radiateur aluminium haute performance",
                description: "Éligible MaPrimeRénov' - 1500W, robinet thermostatique, classe A",
                category: Category.chauffage.rawValue,
                unit: "unité",
                priceHT: 220.00,
                vatRate: 0.055
            ),
            CatalogItem(
                code: "CH002",
                designation: "Pompe à chaleur air/eau 14kW",
                description: "Éligible MaPrimeRénov' Bleu/Jaune - COP 4.5, SCOP A+++, ballon 300L",
                category: Category.chauffage.rawValue,
                unit: "forfait",
                priceHT: 15800.00,
                vatRate: 0.055
            ),
            CatalogItem(
                code: "CH003",
                designation: "Plancher chauffant hydraulique basse température",
                description: "Éligible CEE - Tube PER Ø16, collecteur laiton, régulation zone",
                category: Category.chauffage.rawValue,
                unit: "m²",
                priceHT: 95.00,
                vatRate: 0.055
            ),
            CatalogItem(
                code: "CH004",
                designation: "Chaudière gaz condensation 25kW",
                description: "Éligible MaPrimeRénov' - Rendement 109%, classe A, régulation",
                category: Category.chauffage.rawValue,
                unit: "forfait",
                priceHT: 3200.00,
                vatRate: 0.055
            ),
            CatalogItem(
                code: "CH005",
                designation: "Poêle à granulés étanche 10kW",
                description: "Éligible MaPrimeRénov' - Flamme Verte 7*, programmable, ventilé",
                category: Category.chauffage.rawValue,
                unit: "forfait",
                priceHT: 4500.00,
                vatRate: 0.055
            ),
            
            // TERRASSEMENT
            CatalogItem(
                code: "TE001",
                designation: "Terrassement général",
                description: "Décapage, fouilles, remblais",
                category: Category.terrassement.rawValue,
                unit: "m³",
                priceHT: 45.00,
                vatRate: 0.20
            ),
            CatalogItem(
                code: "TE002",
                designation: "Raccordement tout-à-l'égout",
                description: "Tranchée, tube PVC 160, regard",
                category: Category.terrassement.rawValue,
                unit: "ml",
                priceHT: 120.00,
                vatRate: 0.20
            ),
            CatalogItem(
                code: "TE003",
                designation: "Allée carrossable",
                description: "Concassé, géotextile, béton 15cm",
                category: Category.terrassement.rawValue,
                unit: "m²",
                priceHT: 95.00,
                vatRate: 0.20
            )
        ]
    }
    
    // MARK: - Recherche dans le catalogue
    func searchItems(query: String? = nil, category: Category? = nil) -> [CatalogItem] {
        var results = catalogItems
        
        if let category = category {
            results = results.filter { $0.category == category.rawValue }
        }
        
        if let query = query?.lowercased(), !query.isEmpty {
            results = results.filter {
                $0.designation.lowercased().contains(query) ||
                $0.code.lowercased().contains(query) ||
                ($0.description?.lowercased().contains(query) ?? false)
            }
        }
        
        return results.sorted { $0.designation < $1.designation }
    }
    
    // MARK: - Filtres par prix
    func filterByPriceRange(items: [CatalogItem], min: Double? = nil, max: Double? = nil) -> [CatalogItem] {
        return items.filter { item in
            let price = item.priceHT
            let meetsMin = min == nil || price >= min!
            let meetsMax = max == nil || price <= max!
            return meetsMin && meetsMax
        }
    }
    
    // MARK: - Items par catégorie
    func itemsByCategory() -> [Category: [CatalogItem]] {
        return Dictionary(grouping: catalogItems) { item in
            Category(rawValue: item.category) ?? .grosOeuvre
        }
    }
    
    // MARK: - Stats du catalogue
    var categoryStats: [(category: Category, count: Int, avgPrice: Double)] {
        let grouped = itemsByCategory()
        
        return Category.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            let avgPrice = items.map(\.priceHT).reduce(0, +) / Double(items.count)
            return (category, items.count, avgPrice)
        }.sorted { $0.count > $1.count }
    }
}

// MARK: - Extension pour conversion vers LineItem
extension CatalogBTP.CatalogItem {
    func toLineItem(context: NSManagedObjectContext, quantity: Double = 1.0) -> LineItem {
        let lineItem = LineItem(context: context)
        lineItem.id = UUID()
        lineItem.itemDescription = self.designation
        lineItem.quantity = NSDecimalNumber(value: quantity)
        lineItem.unitPrice = NSDecimalNumber(value: self.priceHT)
        lineItem.taxRate = self.vatRate * 100 // Convert to percentage
        lineItem.position = 0 // Will be set when adding to document
        
        // Set unit if exists in the lineItem model
        if lineItem.entity.attributesByName["unit"] != nil {
            lineItem.setValue(self.unit, forKey: "unit")
        }
        
        return lineItem
    }
}

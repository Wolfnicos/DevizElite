// MARK: - Construction Database for Factures App
// Version: 2025.1
// Markets: France & Belgium
// Last Update: January 2025

import Foundation
import SwiftUI

// MARK: - Data Models

struct ConstructionCategory: Codable, Identifiable {
    var id = UUID()
    let codeNAF: String
    let codeNACE: String
    let codeCPV: String
    let nameFR: String
    let nameNL: String
    let icon: String
    var products: [ConstructionProduct]
}

struct ConstructionProduct: Codable, Identifiable, Equatable {
    var id = UUID()
    let code: String
    let nameFR: String
    let nameNL: String
    let unit: String
    let priceFR: Double
    let priceBE: Double
    let laborHours: Double
    let laborRateHour: Double
    let vatRate: Double // expressed as fraction (e.g., 0.20)
    let description: String
}

// MARK: - Complete Construction Database

class ConstructionDatabase: ObservableObject {
    static let shared = ConstructionDatabase()
    
    @Published var categories: [ConstructionCategory] = []
    @Published var selectedCountry: Country = .france
    
    enum Country: String, CaseIterable {
        case france = "FR"
        case belgium = "BE"
        
        var vatRate: Double {
            switch self {
            case .france: return 0.20
            case .belgium: return 0.21
            }
        }
        
        var currency: String { "€" }
    }
    
    init() {
        loadDatabase()
        // If ever empty (bundle edits), ensure at least one category to avoid blank UI
        if categories.isEmpty {
            categories = [ConstructionCategory(
                codeNAF: "00.00",
                codeNACE: "00.00",
                codeCPV: "00000000",
                nameFR: "Catalogue",
                nameNL: "Catalogus",
                icon: "📦",
                products: []
            )]
        }
    }
    
    private func loadDatabase() {
        categories = [
            // MARK: - 1. GROS ŒUVRE / RUWBOUW
            ConstructionCategory(
                codeNAF: "43.99C",
                codeNACE: "43.99",
                codeCPV: "45262000",
                nameFR: "Gros œuvre - Maçonnerie",
                nameNL: "Ruwbouw - Metselwerk",
                icon: "🏗️",
                products: [
                    ConstructionProduct(
                        code: "GO001",
                        nameFR: "Fondation béton armé",
                        nameNL: "Gewapend beton fundering",
                        unit: "m³",
                        priceFR: 285.00,
                        priceBE: 295.00,
                        laborHours: 8.0,
                        laborRateHour: 45.00,
                        vatRate: 0.10,
                        description: "Béton C25/30 avec armatures HA12"
                    ),
                    ConstructionProduct(
                        code: "GO002",
                        nameFR: "Mur parpaing 20cm",
                        nameNL: "Betonblok muur 20cm",
                        unit: "m²",
                        priceFR: 65.00,
                        priceBE: 68.00,
                        laborHours: 1.2,
                        laborRateHour: 42.00,
                        vatRate: 0.10,
                        description: "Bloc béton 20x20x50 + mortier"
                    ),
                    ConstructionProduct(
                        code: "GO003",
                        nameFR: "Dalle béton 15cm",
                        nameNL: "Betonvloer 15cm",
                        unit: "m²",
                        priceFR: 95.00,
                        priceBE: 98.00,
                        laborHours: 1.5,
                        laborRateHour: 45.00,
                        vatRate: 0.10,
                        description: "Béton C20/25 avec treillis soudé"
                    ),
                    ConstructionProduct(
                        code: "GO004",
                        nameFR: "Linteau béton préfabriqué",
                        nameNL: "Prefab betonlatei",
                        unit: "ml",
                        priceFR: 125.00,
                        priceBE: 130.00,
                        laborHours: 0.5,
                        laborRateHour: 42.00,
                        vatRate: 0.10,
                        description: "Linteau BA 20x20cm portée 3m"
                    ),
                    ConstructionProduct(
                        code: "GO005",
                        nameFR: "Escalier béton",
                        nameNL: "Betonnen trap",
                        unit: "marche",
                        priceFR: 185.00,
                        priceBE: 195.00,
                        laborHours: 2.0,
                        laborRateHour: 48.00,
                        vatRate: 0.10,
                        description: "Marche béton coulé sur place"
                    )
                ]
            ),
            
            // MARK: - 2. TOITURE / DAKWERKEN
            ConstructionCategory(
                codeNAF: "43.91A",
                codeNACE: "43.91",
                codeCPV: "45261000",
                nameFR: "Couverture - Toiture",
                nameNL: "Dakbedekking",
                icon: "🏠",
                products: [
                    ConstructionProduct(
                        code: "CT001",
                        nameFR: "Tuiles terre cuite",
                        nameNL: "Keramische dakpannen",
                        unit: "m²",
                        priceFR: 45.00,
                        priceBE: 48.00,
                        laborHours: 0.8,
                        laborRateHour: 48.00,
                        vatRate: 0.10,
                        description: "Tuiles mécaniques rouge naturel"
                    ),
                    ConstructionProduct(
                        code: "CT002",
                        nameFR: "Ardoises naturelles",
                        nameNL: "Natuurleien",
                        unit: "m²",
                        priceFR: 85.00,
                        priceBE: 90.00,
                        laborHours: 1.5,
                        laborRateHour: 52.00,
                        vatRate: 0.10,
                        description: "Ardoise 40x24 pose au crochet"
                    ),
                    ConstructionProduct(
                        code: "CT003",
                        nameFR: "Gouttière zinc",
                        nameNL: "Zinken dakgoot",
                        unit: "ml",
                        priceFR: 55.00,
                        priceBE: 58.00,
                        laborHours: 0.5,
                        laborRateHour: 45.00,
                        vatRate: 0.10,
                        description: "Gouttière demi-ronde développé 33"
                    ),
                    ConstructionProduct(
                        code: "CT004",
                        nameFR: "Fenêtre de toit VELUX",
                        nameNL: "VELUX dakraam",
                        unit: "u",
                        priceFR: 680.00,
                        priceBE: 720.00,
                        laborHours: 3.0,
                        laborRateHour: 50.00,
                        vatRate: 0.055,
                        description: "GGL MK04 78x98cm confort"
                    ),
                    ConstructionProduct(
                        code: "CT005",
                        nameFR: "Étanchéité EPDM toiture plate",
                        nameNL: "EPDM plat dak",
                        unit: "m²",
                        priceFR: 38.00,
                        priceBE: 40.00,
                        laborHours: 0.4,
                        laborRateHour: 48.00,
                        vatRate: 0.10,
                        description: "Membrane EPDM 1.5mm collée"
                    )
                ]
            ),
            
            // MARK: - 3. MENUISERIE / SCHRIJNWERK
            ConstructionCategory(
                codeNAF: "43.32A",
                codeNACE: "43.32",
                codeCPV: "45421000",
                nameFR: "Menuiserie",
                nameNL: "Schrijnwerk",
                icon: "🚪",
                products: [
                    ConstructionProduct(
                        code: "MN001",
                        nameFR: "Fenêtre PVC double vitrage",
                        nameNL: "PVC raam dubbel glas",
                        unit: "m²",
                        priceFR: 420.00,
                        priceBE: 445.00,
                        laborHours: 2.0,
                        laborRateHour: 45.00,
                        vatRate: 0.055,
                        description: "PVC blanc Uw=1.3 W/m²K"
                    ),
                    ConstructionProduct(
                        code: "MN002",
                        nameFR: "Porte d'entrée aluminium",
                        nameNL: "Aluminium voordeur",
                        unit: "u",
                        priceFR: 2850.00,
                        priceBE: 2950.00,
                        laborHours: 4.0,
                        laborRateHour: 48.00,
                        vatRate: 0.055,
                        description: "Porte alu thermique avec serrure 5 points"
                    ),
                    ConstructionProduct(
                        code: "MN003",
                        nameFR: "Volet roulant électrique",
                        nameNL: "Elektrisch rolluik",
                        unit: "m²",
                        priceFR: 285.00,
                        priceBE: 295.00,
                        laborHours: 1.5,
                        laborRateHour: 45.00,
                        vatRate: 0.055,
                        description: "Volet alu motorisé Somfy"
                    ),
                    ConstructionProduct(
                        code: "MN004",
                        nameFR: "Porte intérieure bois",
                        nameNL: "Houten binnendeur",
                        unit: "u",
                        priceFR: 320.00,
                        priceBE: 340.00,
                        laborHours: 1.5,
                        laborRateHour: 42.00,
                        vatRate: 0.10,
                        description: "Porte postformée 83cm avec huisserie"
                    ),
                    ConstructionProduct(
                        code: "MN005",
                        nameFR: "Parquet contrecollé chêne",
                        nameNL: "Meerlaags eiken parket",
                        unit: "m²",
                        priceFR: 68.00,
                        priceBE: 72.00,
                        laborHours: 0.8,
                        laborRateHour: 40.00,
                        vatRate: 0.10,
                        description: "Parquet 14mm pose flottante"
                    )
                ]
            ),
            
            // MARK: - 4. ISOLATION / ISOLATIE
            ConstructionCategory(
                codeNAF: "43.29A",
                codeNACE: "43.29",
                codeCPV: "45321000",
                nameFR: "Isolation thermique",
                nameNL: "Thermische isolatie",
                icon: "🔥",
                products: [
                    ConstructionProduct(
                        code: "IS001",
                        nameFR: "Isolation combles laine de verre",
                        nameNL: "Zolderisolatie glaswol",
                        unit: "m²",
                        priceFR: 28.00,
                        priceBE: 30.00,
                        laborHours: 0.3,
                        laborRateHour: 38.00,
                        vatRate: 0.055,
                        description: "Laine de verre 300mm R=7.5"
                    ),
                    ConstructionProduct(
                        code: "IS002",
                        nameFR: "Isolation murs ITE polystyrène",
                        nameNL: "Buitenmuurisolatie EPS",
                        unit: "m²",
                        priceFR: 125.00,
                        priceBE: 135.00,
                        laborHours: 1.5,
                        laborRateHour: 42.00,
                        vatRate: 0.055,
                        description: "PSE graphité 140mm + enduit"
                    ),
                    ConstructionProduct(
                        code: "IS003",
                        nameFR: "Isolation sol polyuréthane",
                        nameNL: "Vloerisolatie PUR",
                        unit: "m²",
                        priceFR: 45.00,
                        priceBE: 48.00,
                        laborHours: 0.4,
                        laborRateHour: 40.00,
                        vatRate: 0.055,
                        description: "PUR 100mm R=4.5"
                    ),
                    ConstructionProduct(
                        code: "IS004",
                        nameFR: "Isolation phonique cloison",
                        nameNL: "Akoestische isolatie",
                        unit: "m²",
                        priceFR: 22.00,
                        priceBE: 24.00,
                        laborHours: 0.3,
                        laborRateHour: 38.00,
                        vatRate: 0.10,
                        description: "Laine de roche 75mm"
                    ),
                    ConstructionProduct(
                        code: "IS005",
                        nameFR: "Pare-vapeur",
                        nameNL: "Dampscherm",
                        unit: "m²",
                        priceFR: 8.50,
                        priceBE: 9.00,
                        laborHours: 0.15,
                        laborRateHour: 35.00,
                        vatRate: 0.10,
                        description: "Membrane pare-vapeur Sd=18m"
                    )
                ]
            ),
            
            // MARK: - 5. PLOMBERIE / LOODGIETERIJ
            ConstructionCategory(
                codeNAF: "43.22A",
                codeNACE: "43.22",
                codeCPV: "45330000",
                nameFR: "Plomberie - Sanitaire",
                nameNL: "Sanitair",
                icon: "🚿",
                products: [
                    ConstructionProduct(
                        code: "PB001",
                        nameFR: "WC suspendu complet",
                        nameNL: "Hangtoilet compleet",
                        unit: "u",
                        priceFR: 580.00,
                        priceBE: 620.00,
                        laborHours: 3.0,
                        laborRateHour: 48.00,
                        vatRate: 0.10,
                        description: "Geberit + cuvette + plaque double"
                    ),
                    ConstructionProduct(
                        code: "PB002",
                        nameFR: "Lavabo avec meuble",
                        nameNL: "Wastafel met meubel",
                        unit: "u",
                        priceFR: 450.00,
                        priceBE: 480.00,
                        laborHours: 2.5,
                        laborRateHour: 45.00,
                        vatRate: 0.10,
                        description: "Meuble 60cm + vasque + robinet"
                    ),
                    ConstructionProduct(
                        code: "PB003",
                        nameFR: "Douche à l'italienne 90x90",
                        nameNL: "Inloopdouche 90x90",
                        unit: "u",
                        priceFR: 1250.00,
                        priceBE: 1350.00,
                        laborHours: 8.0,
                        laborRateHour: 50.00,
                        vatRate: 0.10,
                        description: "Receveur extra-plat + paroi verre"
                    ),
                    ConstructionProduct(
                        code: "PB004",
                        nameFR: "Chauffe-eau thermodynamique 200L",
                        nameNL: "Warmtepomp boiler 200L",
                        unit: "u",
                        priceFR: 2450.00,
                        priceBE: 2550.00,
                        laborHours: 4.0,
                        laborRateHour: 52.00,
                        vatRate: 0.055,
                        description: "COP 3.5 classe A+"
                    ),
                    ConstructionProduct(
                        code: "PB005",
                        nameFR: "Tuyauterie PER + collecteur",
                        nameNL: "PER leidingen + verdeler",
                        unit: "ml",
                        priceFR: 18.00,
                        priceBE: 19.50,
                        laborHours: 0.3,
                        laborRateHour: 45.00,
                        vatRate: 0.10,
                        description: "PER 16mm avec isolation"
                    )
                ]
            ),
            
            // MARK: - 6. ÉLECTRICITÉ / ELEKTRICITEIT
            ConstructionCategory(
                codeNAF: "43.21A",
                codeNACE: "43.21",
                codeCPV: "45310000",
                nameFR: "Installation électrique",
                nameNL: "Elektrische installatie",
                icon: "⚡",
                products: [
                    ConstructionProduct(
                        code: "EL001",
                        nameFR: "Tableau électrique 3 rangées",
                        nameNL: "Elektrisch bord 3 rijen",
                        unit: "u",
                        priceFR: 850.00,
                        priceBE: 890.00,
                        laborHours: 4.0,
                        laborRateHour: 50.00,
                        vatRate: 0.10,
                        description: "Tableau pré-équipé 39 modules"
                    ),
                    ConstructionProduct(
                        code: "EL002",
                        nameFR: "Point lumineux simple",
                        nameNL: "Lichtpunt enkel",
                        unit: "u",
                        priceFR: 85.00,
                        priceBE: 90.00,
                        laborHours: 1.0,
                        laborRateHour: 45.00,
                        vatRate: 0.10,
                        description: "Interrupteur + câblage + boîte"
                    ),
                    ConstructionProduct(
                        code: "EL003",
                        nameFR: "Prise de courant 16A",
                        nameNL: "Stopcontact 16A",
                        unit: "u",
                        priceFR: 65.00,
                        priceBE: 68.00,
                        laborHours: 0.8,
                        laborRateHour: 45.00,
                        vatRate: 0.10,
                        description: "Prise 2P+T encastrée"
                    ),
                    ConstructionProduct(
                        code: "EL004",
                        nameFR: "Prise RJ45 Cat 6",
                        nameNL: "RJ45 aansluiting Cat 6",
                        unit: "u",
                        priceFR: 95.00,
                        priceBE: 98.00,
                        laborHours: 1.2,
                        laborRateHour: 48.00,
                        vatRate: 0.10,
                        description: "Prise réseau avec câblage"
                    ),
                    ConstructionProduct(
                        code: "EL005",
                        nameFR: "Spot LED encastré",
                        nameNL: "LED inbouwspot",
                        unit: "u",
                        priceFR: 45.00,
                        priceBE: 48.00,
                        laborHours: 0.5,
                        laborRateHour: 42.00,
                        vatRate: 0.10,
                        description: "Spot LED 7W dimmable"
                    )
                ]
            ),
            
            // MARK: - 7. CHAUFFAGE / VERWARMING
            ConstructionCategory(
                codeNAF: "43.22B",
                codeNACE: "43.22",
                codeCPV: "45331000",
                nameFR: "Chauffage - Climatisation",
                nameNL: "Verwarming - Airco",
                icon: "🔥",
                products: [
                    ConstructionProduct(
                        code: "CH001",
                        nameFR: "Chaudière gaz condensation",
                        nameNL: "Condensatieketel gas",
                        unit: "u",
                        priceFR: 3850.00,
                        priceBE: 3950.00,
                        laborHours: 8.0,
                        laborRateHour: 55.00,
                        vatRate: 0.055,
                        description: "24kW rendement 109%"
                    ),
                    ConstructionProduct(
                        code: "CH002",
                        nameFR: "Pompe à chaleur air/eau",
                        nameNL: "Warmtepomp lucht/water",
                        unit: "u",
                        priceFR: 8500.00,
                        priceBE: 8900.00,
                        laborHours: 12.0,
                        laborRateHour: 60.00,
                        vatRate: 0.055,
                        description: "PAC 8kW COP 4.5"
                    ),
                    ConstructionProduct(
                        code: "CH003",
                        nameFR: "Radiateur acier 600x1000",
                        nameNL: "Stalen radiator 600x1000",
                        unit: "u",
                        priceFR: 185.00,
                        priceBE: 195.00,
                        laborHours: 1.5,
                        laborRateHour: 48.00,
                        vatRate: 0.10,
                        description: "Type 22 avec robinet thermostatique"
                    ),
                    ConstructionProduct(
                        code: "CH004",
                        nameFR: "Plancher chauffant",
                        nameNL: "Vloerverwarming",
                        unit: "m²",
                        priceFR: 68.00,
                        priceBE: 72.00,
                        laborHours: 1.0,
                        laborRateHour: 50.00,
                        vatRate: 0.10,
                        description: "Tubes PER + collecteur + régulation"
                    ),
                    ConstructionProduct(
                        code: "CH005",
                        nameFR: "Climatisation réversible mono-split",
                        nameNL: "Reversibele airco mono-split",
                        unit: "u",
                        priceFR: 1850.00,
                        priceBE: 1950.00,
                        laborHours: 4.0,
                        laborRateHour: 52.00,
                        vatRate: 0.055,
                        description: "2.5kW inverter A++"
                    )
                ]
            ),
            
            // MARK: - 8. PLÂTRERIE / PLEISTERWERK
            ConstructionCategory(
                codeNAF: "43.31Z",
                codeNACE: "43.31",
                codeCPV: "45410000",
                nameFR: "Plâtrerie - Cloisons",
                nameNL: "Pleisterwerk - Wanden",
                icon: "🏗️",
                products: [
                    ConstructionProduct(
                        code: "PL001",
                        nameFR: "Cloison placo 72mm",
                        nameNL: "Gipsplaat wand 72mm",
                        unit: "m²",
                        priceFR: 42.00,
                        priceBE: 45.00,
                        laborHours: 0.6,
                        laborRateHour: 40.00,
                        vatRate: 0.10,
                        description: "BA13 + rails + isolation"
                    ),
                    ConstructionProduct(
                        code: "PL002",
                        nameFR: "Faux plafond suspendu",
                        nameNL: "Verlaagd plafond",
                        unit: "m²",
                        priceFR: 58.00,
                        priceBE: 62.00,
                        laborHours: 0.8,
                        laborRateHour: 42.00,
                        vatRate: 0.10,
                        description: "Placo + ossature + suspentes"
                    ),
                    ConstructionProduct(
                        code: "PL003",
                        nameFR: "Enduit plâtre manuel",
                        nameNL: "Handmatig pleisterwerk",
                        unit: "m²",
                        priceFR: 22.00,
                        priceBE: 24.00,
                        laborHours: 0.5,
                        laborRateHour: 38.00,
                        vatRate: 0.10,
                        description: "Enduit plâtre 2 couches"
                    ),
                    ConstructionProduct(
                        code: "PL004",
                        nameFR: "Doublage thermique 100mm",
                        nameNL: "Thermische voorzetwand 100mm",
                        unit: "m²",
                        priceFR: 48.00,
                        priceBE: 52.00,
                        laborHours: 0.7,
                        laborRateHour: 40.00,
                        vatRate: 0.055,
                        description: "Placo + PSE 100mm"
                    ),
                    ConstructionProduct(
                        code: "PL005",
                        nameFR: "Trappe de visite",
                        nameNL: "Inspectieluik",
                        unit: "u",
                        priceFR: 125.00,
                        priceBE: 135.00,
                        laborHours: 1.0,
                        laborRateHour: 40.00,
                        vatRate: 0.10,
                        description: "Trappe 60x60 invisible"
                    )
                ]
            ),
            
            // MARK: - 9. PEINTURE / SCHILDERWERK
            ConstructionCategory(
                codeNAF: "43.34Z",
                codeNACE: "43.34",
                codeCPV: "45442100",
                nameFR: "Peinture - Décoration",
                nameNL: "Schilderwerk - Decoratie",
                icon: "🎨",
                products: [
                    ConstructionProduct(
                        code: "PE001",
                        nameFR: "Peinture mur acrylique",
                        nameNL: "Muurverf acryl",
                        unit: "m²",
                        priceFR: 12.50,
                        priceBE: 13.50,
                        laborHours: 0.25,
                        laborRateHour: 38.00,
                        vatRate: 0.10,
                        description: "2 couches mat ou satin"
                    ),
                    ConstructionProduct(
                        code: "PE002",
                        nameFR: "Peinture plafond",
                        nameNL: "Plafondverf",
                        unit: "m²",
                        priceFR: 10.50,
                        priceBE: 11.50,
                        laborHours: 0.20,
                        laborRateHour: 38.00,
                        vatRate: 0.10,
                        description: "2 couches mat blanc"
                    ),
                    ConstructionProduct(
                        code: "PE003",
                        nameFR: "Laque boiserie",
                        nameNL: "Houtlak",
                        unit: "m²",
                        priceFR: 28.00,
                        priceBE: 30.00,
                        laborHours: 0.5,
                        laborRateHour: 40.00,
                        vatRate: 0.10,
                        description: "Ponçage + 2 couches satinée"
                    ),
                    ConstructionProduct(
                        code: "PE004",
                        nameFR: "Papier peint intissé",
                        nameNL: "Vliesbehang",
                        unit: "m²",
                        priceFR: 35.00,
                        priceBE: 38.00,
                        laborHours: 0.4,
                        laborRateHour: 38.00,
                        vatRate: 0.10,
                        description: "Pose collée + fourniture"
                    ),
                    ConstructionProduct(
                        code: "PE005",
                        nameFR: "Enduit décoratif",
                        nameNL: "Decoratief pleister",
                        unit: "m²",
                        priceFR: 65.00,
                        priceBE: 68.00,
                        laborHours: 1.0,
                        laborRateHour: 42.00,
                        vatRate: 0.10,
                        description: "Enduit à la chaux taloché"
                    )
                ]
            ),
            
            // MARK: - 10. CARRELAGE / TEGELS
            ConstructionCategory(
                codeNAF: "43.33Z",
                codeNACE: "43.33",
                codeCPV: "45431000",
                nameFR: "Carrelage - Revêtements",
                nameNL: "Tegels - Vloerbedekking",
                icon: "🔲",
                products: [
                    ConstructionProduct(
                        code: "CR001",
                        nameFR: "Carrelage sol 60x60",
                        nameNL: "Vloertegels 60x60",
                        unit: "m²",
                        priceFR: 68.00,
                        priceBE: 72.00,
                        laborHours: 1.2,
                        laborRateHour: 42.00,
                        vatRate: 0.10,
                        description: "Grès cérame + joints"
                    ),
                    ConstructionProduct(
                        code: "CR002",
                        nameFR: "Faïence murale",
                        nameNL: "Wandtegels",
                        unit: "m²",
                        priceFR: 55.00,
                        priceBE: 58.00,
                        laborHours: 1.0,
                        laborRateHour: 40.00,
                        vatRate: 0.10,
                        description: "Faïence 30x60 blanc"
                    ),
                    ConstructionProduct(
                        code: "CR003",
                        nameFR: "Chape fluide anhydrite",
                        nameNL: "Vloeibare dekvloer",
                        unit: "m²",
                        priceFR: 28.00,
                        priceBE: 30.00,
                        laborHours: 0.2,
                        laborRateHour: 38.00,
                        vatRate: 0.10,
                        description: "Épaisseur 5cm autonivelante"
                    ),
                    ConstructionProduct(
                        code: "CR004",
                        nameFR: "Plinthes carrelage",
                        nameNL: "Tegelplinten",
                        unit: "ml",
                        priceFR: 18.00,
                        priceBE: 19.50,
                        laborHours: 0.3,
                        laborRateHour: 38.00,
                        vatRate: 0.10,
                        description: "Plinthes assorties 8cm"
                    ),
                    ConstructionProduct(
                        code: "CR005",
                        nameFR: "Sol PVC/Vinyle clipsable",
                        nameNL: "PVC/Vinyl klikvloer",
                        unit: "m²",
                        priceFR: 45.00,
                        priceBE: 48.00,
                        laborHours: 0.5,
                        laborRateHour: 38.00,
                        vatRate: 0.10,
                        description: "LVT 5mm aspect bois"
                    )
                ]
            ),
            
            // MARK: - 11. TERRASSEMENT / GRONDWERK
            ConstructionCategory(
                codeNAF: "43.12A",
                codeNACE: "43.12",
                codeCPV: "45112000",
                nameFR: "Terrassement - VRD",
                nameNL: "Grondwerk - Riolering",
                icon: "🚜",
                products: [
                    ConstructionProduct(
                        code: "TR001",
                        nameFR: "Excavation terre végétale",
                        nameNL: "Afgraven teelaarde",
                        unit: "m³",
                        priceFR: 28.00,
                        priceBE: 30.00,
                        laborHours: 0.3,
                        laborRateHour: 45.00,
                        vatRate: 0.20,
                        description: "Décapage + évacuation"
                    ),
                    ConstructionProduct(
                        code: "TR002",
                        nameFR: "Remblai compacté",
                        nameNL: "Verdichte ophoging",
                        unit: "m³",
                        priceFR: 45.00,
                        priceBE: 48.00,
                        laborHours: 0.4,
                        laborRateHour: 45.00,
                        vatRate: 0.20,
                        description: "Tout-venant 0/31.5"
                    ),
                    ConstructionProduct(
                        code: "TR003",
                        nameFR: "Canalisation PVC 125mm",
                        nameNL: "PVC rioolbuis 125mm",
                        unit: "ml",
                        priceFR: 35.00,
                        priceBE: 38.00,
                        laborHours: 0.5,
                        laborRateHour: 42.00,
                        vatRate: 0.20,
                        description: "Tube + lit de pose"
                    ),
                    ConstructionProduct(
                        code: "TR004",
                        nameFR: "Regard béton 40x40",
                        nameNL: "Betonput 40x40",
                        unit: "u",
                        priceFR: 185.00,
                        priceBE: 195.00,
                        laborHours: 1.5,
                        laborRateHour: 45.00,
                        vatRate: 0.20,
                        description: "Regard avec tampon fonte"
                    ),
                    ConstructionProduct(
                        code: "TR005",
                        nameFR: "Enrobé bitumineux",
                        nameNL: "Asfalt",
                        unit: "m²",
                        priceFR: 58.00,
                        priceBE: 62.00,
                        laborHours: 0.3,
                        laborRateHour: 48.00,
                        vatRate: 0.20,
                        description: "Couche 5cm 0/10"
                    )
                ]
            ),
            
            // MARK: - 12. AMÉNAGEMENT EXTÉRIEUR / BUITENAANLEG
            ConstructionCategory(
                codeNAF: "81.30Z",
                codeNACE: "81.30",
                codeCPV: "45112700",
                nameFR: "Aménagement extérieur",
                nameNL: "Tuinaanleg",
                icon: "🌳",
                products: [
                    ConstructionProduct(
                        code: "AE001",
                        nameFR: "Terrasse bois composite",
                        nameNL: "Composiet terras",
                        unit: "m²",
                        priceFR: 125.00,
                        priceBE: 135.00,
                        laborHours: 1.5,
                        laborRateHour: 42.00,
                        vatRate: 0.10,
                        description: "Lames composite + structure"
                    ),
                    ConstructionProduct(
                        code: "AE002",
                        nameFR: "Pavés béton autobloquants",
                        nameNL: "Betonklinkers",
                        unit: "m²",
                        priceFR: 48.00,
                        priceBE: 52.00,
                        laborHours: 1.0,
                        laborRateHour: 40.00,
                        vatRate: 0.20,
                        description: "Pavés 20x10x6 gris"
                    ),
                    ConstructionProduct(
                        code: "AE003",
                        nameFR: "Clôture panneaux rigides",
                        nameNL: "Draadpanelen omheining",
                        unit: "ml",
                        priceFR: 85.00,
                        priceBE: 90.00,
                        laborHours: 0.8,
                        laborRateHour: 40.00,
                        vatRate: 0.20,
                        description: "Hauteur 1.80m + poteaux"
                    ),
                    ConstructionProduct(
                        code: "AE004",
                        nameFR: "Portail aluminium motorisé",
                        nameNL: "Gemotoriseerde alu poort",
                        unit: "u",
                        priceFR: 3850.00,
                        priceBE: 3950.00,
                        laborHours: 6.0,
                        laborRateHour: 48.00,
                        vatRate: 0.20,
                        description: "Portail coulissant 4m"
                    ),
                    ConstructionProduct(
                        code: "AE005",
                        nameFR: "Gazon en rouleau",
                        nameNL: "Graszoden",
                        unit: "m²",
                        priceFR: 18.00,
                        priceBE: 20.00,
                        laborHours: 0.2,
                        laborRateHour: 35.00,
                        vatRate: 0.10,
                        description: "Pose + première tonte"
                    )
                ]
            )
        ]
    }
    
    // MARK: - Helper Functions
    
    func getPrice(for product: ConstructionProduct) -> Double {
        switch selectedCountry {
        case .france: return product.priceFR
        case .belgium: return product.priceBE
        }
    }
    
    func getTotalPrice(for product: ConstructionProduct, quantity: Double) -> Double {
        let unitPrice = getPrice(for: product)
        let laborCost = product.laborHours * product.laborRateHour * quantity
        let materialCost = unitPrice * quantity
        let subtotal = materialCost + laborCost
        let vat = subtotal * product.vatRate
        return subtotal + vat
    }
    
    func searchProducts(query: String) -> [ConstructionProduct] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        var results: [ConstructionProduct] = []
        
        for category in categories {
            let filteredProducts = category.products.filter {
                $0.nameFR.lowercased().contains(lowercasedQuery) ||
                $0.nameNL.lowercased().contains(lowercasedQuery) ||
                $0.code.lowercased().contains(lowercasedQuery) ||
                $0.description.lowercased().contains(lowercasedQuery)
            }
            results.append(contentsOf: filteredProducts)
        }
        
        return results
    }
    
    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(categories)
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }
    
    func importFromJSON(_ data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            categories = try decoder.decode([ConstructionCategory].self, from: data)
        } catch {
            print("Import error: \(error)")
        }
    }
}

// MARK: - Export Helpers

extension ConstructionDatabase {
    func generateCSV() -> String {
        var csv = "Code,Nom FR,Nom NL,Unité,Prix FR,Prix BE,Heures MO,Taux Horaire,TVA,Description\n"
        
        for category in categories {
            for product in category.products {
                csv += "\(product.code),"
                csv += "\"\(product.nameFR)\"," 
                csv += "\"\(product.nameNL)\"," 
                csv += "\(product.unit),"
                csv += "\(product.priceFR),"
                csv += "\(product.priceBE),"
                csv += "\(product.laborHours),"
                csv += "\(product.laborRateHour),"
                csv += "\(product.vatRate),"
                csv += "\"\(product.description)\"\n"
            }
        }
        
        return csv
    }
    
    func saveToUserDefaults() {
        if let data = exportToJSON() {
            UserDefaults.standard.set(data, forKey: "ConstructionDatabase")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "ConstructionDatabase") {
            importFromJSON(data)
        }
    }
}



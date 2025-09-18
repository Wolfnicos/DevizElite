import Foundation
import SwiftUI

// MARK: - Enums pour types de travaux BTP
enum TypeTravaux: String, CaseIterable, Codable {
    case neuf = "Construction neuve"
    case renovation = "Rénovation"
    case `extension` = "Extension"
    case amenagement = "Aménagement"
    case entretien = "Entretien"
    case reparation = "Réparation"
    
    var localized: String {
        switch self {
        case .neuf: return L10n.t("construction.new")
        case .renovation: return L10n.t("construction.renovation")
        case .`extension`: return L10n.t("construction.extension")
        case .amenagement: return L10n.t("construction.amenagement")
        case .entretien: return L10n.t("construction.maintenance")
        case .reparation: return L10n.t("construction.repair")
        }
    }
    
    var icon: String {
        switch self {
        case .neuf: return "house.fill"
        case .renovation: return "hammer.fill"
        case .`extension`: return "plus.square.fill"
        case .amenagement: return "paintbrush.fill"
        case .entretien: return "wrench.fill"
        case .reparation: return "exclamationmark.triangle.fill"
        }
    }
    
    var defaultTVARate: Double {
        switch self {
        case .neuf, .`extension`: return 0.21 // TVA normale
        case .renovation, .amenagement, .entretien, .reparation: return 0.06 // TVA réduite
        }
    }
}

enum ZoneTravaux: String, CaseIterable, Codable {
    case interieur = "Intérieur"
    case exterieur = "Extérieur"
    case both = "Int. & Ext."
    case infrastructure = "Infrastructure"
    case toiture = "Toiture"
    case facade = "Façade"
    
    var localized: String {
        switch self {
        case .interieur: return L10n.t("zone.interior")
        case .exterieur: return L10n.t("zone.exterior")
        case .both: return L10n.t("zone.both")
        case .infrastructure: return L10n.t("zone.infrastructure")
        case .toiture: return L10n.t("zone.roof")
        case .facade: return L10n.t("zone.facade")
        }
    }
    
    var color: Color {
        switch self {
        case .interieur: return .blue
        case .exterieur: return .green
        case .both: return .purple
        case .infrastructure: return .brown
        case .toiture: return .red
        case .facade: return .orange
        }
    }
}

enum Country: String, CaseIterable, Codable {
    case france = "FR"
    case belgium = "BE"
    case luxembourg = "LU"
    
    var name: String {
        switch self {
        case .france: return "France"
        case .belgium: return "Belgique"
        case .luxembourg: return "Luxembourg"
        }
    }
    
    var flag: String {
        switch self {
        case .france: return "🇫🇷"
        case .belgium: return "🇧🇪"
        case .luxembourg: return "🇱🇺"
        }
    }
    
    var vatRates: [Double] {
        switch self {
        case .france: return [0.0, 0.055, 0.10, 0.20] // 0%, 5.5%, 10%, 20%
        case .belgium: return [0.0, 0.06, 0.12, 0.21] // 0%, 6%, 12%, 21%
        case .luxembourg: return [0.0, 0.08, 0.14, 0.17] // 0%, 8%, 14%, 17%
        }
    }
    
    var standardVatRate: Double {
        switch self {
        case .france: return 0.20
        case .belgium: return 0.21
        case .luxembourg: return 0.17
        }
    }
    
    var reducedVatRate: Double {
        switch self {
        case .france: return 0.10
        case .belgium: return 0.06
        case .luxembourg: return 0.08
        }
    }
    
    var currency: String { "€" }
    
    var invoicePrefix: String {
        switch self {
        case .france: return "FA"
        case .belgium: return "FB"
        case .luxembourg: return "FL"
        }
    }
    
    var quotePrefix: String {
        switch self {
        case .france: return "DE"
        case .belgium: return "OF"
        case .luxembourg: return "DV"
        }
    }
    
    var locale: Locale {
        switch self {
        case .france: return Locale(identifier: "fr_FR")
        case .belgium: return Locale(identifier: "fr_BE")
        case .luxembourg: return Locale(identifier: "fr_LU")
        }
    }
    
    var languages: [AppLanguage] {
        switch self {
        case .france: return [.french, .english]
        case .belgium: return [.french, .dutch, .english]
        case .luxembourg: return [.french, .german, .english]
        }
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case french = "fr"
    case english = "en"
    case dutch = "nl"
    case german = "de"
    
    var name: String {
        switch self {
        case .french: return "Français"
        case .english: return "English"
        case .dutch: return "Nederlands"
        case .german: return "Deutsch"
        }
    }
    
    var flag: String {
        switch self {
        case .french: return "🇫🇷"
        case .english: return "🇬🇧"
        case .dutch: return "🇳🇱"
        case .german: return "🇩🇪"
        }
    }
    
    var localeIdentifier: String {
        switch self {
        case .french: return "fr_FR"
        case .english: return "en_US"
        case .dutch: return "nl_NL"
        case .german: return "de_DE"
        }
    }
}

// MARK: - Structure Lot (Corps d'état)
enum CorpsEtat: String, CaseIterable, Codable {
    // Gros œuvre
    case grosOeuvre = "Gros œuvre"
    case terrassement = "Terrassement"
    case fondations = "Fondations"
    case maconnerie = "Maçonnerie"
    case betonArme = "Béton armé"
    case charpente = "Charpente"
    
    // Second œuvre
    case couverture = "Couverture"
    case etancheite = "Étanchéité"
    case isolation = "Isolation"
    case cloisons = "Cloisons"
    case platerie = "Plâtrerie"
    
    // Menuiseries
    case menuiserieExt = "Menuiserie extérieure"
    case menuiserieInt = "Menuiserie intérieure"
    case fermetures = "Fermetures"
    case verrerie = "Verrerie"
    
    // Techniques
    case plomberie = "Plomberie"
    case electricite = "Électricité"
    case chauffage = "Chauffage"
    case climatisation = "Climatisation"
    case ventilation = "Ventilation"
    case ascenseurs = "Ascenseurs"
    
    // Finitions
    case carrelage = "Carrelage"
    case sols = "Sols souples"
    case peinture = "Peinture"
    case papierPeint = "Papier peint"
    case faience = "Faïence"
    
    // Extérieur
    case facade = "Façade"
    case bardage = "Bardage"
    case vrd = "VRD"
    case espaces_verts = "Espaces verts"
    case clotures = "Clôtures"
    
    // Spécialisés
    case cuisines = "Cuisines"
    case sallesBains = "Salles de bains"
    case domotique = "Domotique"
    case securite = "Sécurité"
    case nettoyage = "Nettoyage"
    
    var localized: String {
        switch self {
        case .grosOeuvre: return L10n.t("corps.gros_oeuvre")
        case .terrassement: return L10n.t("corps.terrassement")
        case .fondations: return L10n.t("corps.fondations")
        case .maconnerie: return L10n.t("corps.maconnerie")
        case .betonArme: return L10n.t("corps.beton_arme")
        case .charpente: return L10n.t("corps.charpente")
        case .couverture: return L10n.t("corps.couverture")
        case .etancheite: return L10n.t("corps.etancheite")
        case .isolation: return L10n.t("corps.isolation")
        case .cloisons: return L10n.t("corps.cloisons")
        case .platerie: return L10n.t("corps.platerie")
        case .menuiserieExt: return L10n.t("corps.menuiserie_ext")
        case .menuiserieInt: return L10n.t("corps.menuiserie_int")
        case .fermetures: return L10n.t("corps.fermetures")
        case .verrerie: return L10n.t("corps.verrerie")
        case .plomberie: return L10n.t("corps.plomberie")
        case .electricite: return L10n.t("corps.electricite")
        case .chauffage: return L10n.t("corps.chauffage")
        case .climatisation: return L10n.t("corps.climatisation")
        case .ventilation: return L10n.t("corps.ventilation")
        case .ascenseurs: return L10n.t("corps.ascenseurs")
        case .carrelage: return L10n.t("corps.carrelage")
        case .sols: return L10n.t("corps.sols")
        case .peinture: return L10n.t("corps.peinture")
        case .papierPeint: return L10n.t("corps.papier_peint")
        case .faience: return L10n.t("corps.faience")
        case .facade: return L10n.t("corps.facade")
        case .bardage: return L10n.t("corps.bardage")
        case .vrd: return L10n.t("corps.vrd")
        case .espaces_verts: return L10n.t("corps.espaces_verts")
        case .clotures: return L10n.t("corps.clotures")
        case .cuisines: return L10n.t("corps.cuisines")
        case .sallesBains: return L10n.t("corps.salles_bains")
        case .domotique: return L10n.t("corps.domotique")
        case .securite: return L10n.t("corps.securite")
        case .nettoyage: return L10n.t("corps.nettoyage")
        }
    }
    
    var category: CorpsEtatCategory {
        switch self {
        case .grosOeuvre, .terrassement, .fondations, .maconnerie, .betonArme, .charpente:
            return .grosOeuvre
        case .couverture, .etancheite, .isolation, .cloisons, .platerie:
            return .secondOeuvre
        case .menuiserieExt, .menuiserieInt, .fermetures, .verrerie:
            return .menuiseries
        case .plomberie, .electricite, .chauffage, .climatisation, .ventilation, .ascenseurs:
            return .techniques
        case .carrelage, .sols, .peinture, .papierPeint, .faience:
            return .finitions
        case .facade, .bardage, .vrd, .espaces_verts, .clotures:
            return .exterieur
        case .cuisines, .sallesBains, .domotique, .securite, .nettoyage:
            return .specialises
        }
    }
    
    var icon: String {
        switch self {
        case .grosOeuvre: return "building.2.fill"
        case .terrassement: return "mountain.2.fill"
        case .fondations: return "square.stack.3d.down.right.fill"
        case .maconnerie: return "square.grid.3x3.fill"
        case .betonArme: return "square.and.pencil"
        case .charpente: return "triangle.fill"
        case .couverture: return "house.fill"
        case .etancheite: return "drop.fill"
        case .isolation: return "thermometer"
        case .cloisons: return "rectangle.split.3x1.fill"
        case .platerie: return "paintbrush.fill"
        case .menuiserieExt: return "door.left.hand.open"
        case .menuiserieInt: return "door.right.hand.open"
        case .fermetures: return "rectangle.and.hand.point.up.left.filled"
        case .verrerie: return "viewfinder"
        case .plomberie: return "drop.triangle.fill"
        case .electricite: return "bolt.fill"
        case .chauffage: return "flame.fill"
        case .climatisation: return "snowflake"
        case .ventilation: return "wind"
        case .ascenseurs: return "arrow.up.arrow.down"
        case .carrelage: return "grid"
        case .sols: return "square.grid.2x2.fill"
        case .peinture: return "paintbrush.pointed.fill"
        case .papierPeint: return "doc.text.fill"
        case .faience: return "rectangle.grid.2x2.fill"
        case .facade: return "building.fill"
        case .bardage: return "rectangle.stack.fill"
        case .vrd: return "road.lanes"
        case .espaces_verts: return "leaf.fill"
        case .clotures: return "fence.fill"
        case .cuisines: return "cooktop.fill"
        case .sallesBains: return "shower.fill"
        case .domotique: return "homekit"
        case .securite: return "lock.shield.fill"
        case .nettoyage: return "sparkles"
        }
    }
    
    var color: Color {
        return category.color
    }
}

enum CorpsEtatCategory: String, CaseIterable {
    case grosOeuvre = "Gros œuvre"
    case secondOeuvre = "Second œuvre"
    case menuiseries = "Menuiseries"
    case techniques = "Techniques"
    case finitions = "Finitions"
    case exterieur = "Extérieur"
    case specialises = "Spécialisés"
    
    var color: Color {
        switch self {
        case .grosOeuvre: return .brown
        case .secondOeuvre: return .blue
        case .menuiseries: return .orange
        case .techniques: return .red
        case .finitions: return .green
        case .exterieur: return .purple
        case .specialises: return .pink
        }
    }
    
    var icon: String {
        switch self {
        case .grosOeuvre: return "building.2.fill"
        case .secondOeuvre: return "square.stack.3d.up.fill"
        case .menuiseries: return "door.left.hand.open"
        case .techniques: return "bolt.fill"
        case .finitions: return "paintbrush.pointed.fill"
        case .exterieur: return "house.fill"
        case .specialises: return "star.fill"
        }
    }
}

// MARK: - Unités de mesure BTP
enum UniteBTP: String, CaseIterable, Codable {
    // Surfaces
    case m2 = "m²"
    case cm2 = "cm²"
    case hectare = "ha"
    
    // Volumes
    case m3 = "m³"
    case litre = "L"
    case dm3 = "dm³"
    
    // Longueurs
    case m = "m"
    case cm = "cm"
    case mm = "mm"
    case km = "km"
    case ml = "ml" // mètre linéaire
    
    // Poids
    case kg = "kg"
    case tonne = "T"
    case gramme = "g"
    
    // Quantités
    case unite = "u"
    case piece = "pce"
    case lot = "lot"
    case ensemble = "ens"
    case forfait = "forfait"
    case global = "global"
    
    // Temps
    case heure = "h"
    case jour = "j"
    case semaine = "sem"
    case mois = "mois"
    
    // Spécifiques BTP
    case point = "pt" // point électrique
    case ouvrant = "ouvr" // ouvrant menuiserie
    case poste = "poste"
    case circuit = "circuit"
    case paire = "paire"
    
    var localized: String {
        switch self {
        case .m2: return L10n.t("unit.m2")
        case .cm2: return L10n.t("unit.cm2")
        case .hectare: return L10n.t("unit.hectare")
        case .m3: return L10n.t("unit.m3")
        case .litre: return L10n.t("unit.litre")
        case .dm3: return L10n.t("unit.dm3")
        case .m: return L10n.t("unit.m")
        case .cm: return L10n.t("unit.cm")
        case .mm: return L10n.t("unit.mm")
        case .km: return L10n.t("unit.km")
        case .ml: return L10n.t("unit.ml")
        case .kg: return L10n.t("unit.kg")
        case .tonne: return L10n.t("unit.tonne")
        case .gramme: return L10n.t("unit.gramme")
        case .unite: return L10n.t("unit.unite")
        case .piece: return L10n.t("unit.piece")
        case .lot: return L10n.t("unit.lot")
        case .ensemble: return L10n.t("unit.ensemble")
        case .forfait: return L10n.t("unit.forfait")
        case .global: return L10n.t("unit.global")
        case .heure: return L10n.t("unit.heure")
        case .jour: return L10n.t("unit.jour")
        case .semaine: return L10n.t("unit.semaine")
        case .mois: return L10n.t("unit.mois")
        case .point: return L10n.t("unit.point")
        case .ouvrant: return L10n.t("unit.ouvrant")
        case .poste: return L10n.t("unit.poste")
        case .circuit: return L10n.t("unit.circuit")
        case .paire: return L10n.t("unit.paire")
        }
    }
    
    var category: UniteCategory {
        switch self {
        case .m2, .cm2, .hectare: return .surface
        case .m3, .litre, .dm3: return .volume
        case .m, .cm, .mm, .km, .ml: return .longueur
        case .kg, .tonne, .gramme: return .poids
        case .unite, .piece, .lot, .ensemble, .forfait, .global: return .quantite
        case .heure, .jour, .semaine, .mois: return .temps
        case .point, .ouvrant, .poste, .circuit, .paire: return .specifique
        }
    }
}

enum UniteCategory: String, CaseIterable {
    case surface = "Surface"
    case volume = "Volume"
    case longueur = "Longueur"
    case poids = "Poids"
    case quantite = "Quantité"
    case temps = "Temps"
    case specifique = "Spécifique BTP"
    
    var icon: String {
        switch self {
        case .surface: return "square.grid.2x2"
        case .volume: return "cube"
        case .longueur: return "ruler"
        case .poids: return "scalemass"
        case .quantite: return "number"
        case .temps: return "clock"
        case .specifique: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Certifications et labels BTP
enum CertificationBTP: String, CaseIterable, Codable {
    // France
    case rge = "RGE"
    case qualibat = "Qualibat"
    case qualit_enr = "Qualit'EnR"
    case pro_ite = "Pro-ITE"
    case eco_artisan = "Eco-Artisan"
    case certibat = "Certibat"
    case cekal = "Cekal"
    
    // Belgique
    case cerga = "CERGA"
    case wtcb = "WTCB"
    case belgium_green_building = "Belgium Green Building Council"
    case atg = "ATG"
    
    // Européennes
    case ce_marking = "Marquage CE"
    case iso_9001 = "ISO 9001"
    case iso_14001 = "ISO 14001"
    case ohsas_18001 = "OHSAS 18001"
    
    var fullName: String {
        switch self {
        case .rge: return "Reconnu Garant de l'Environnement"
        case .qualibat: return "Qualibat - Qualification du bâtiment"
        case .qualit_enr: return "Qualit'EnR - Énergies renouvelables"
        case .pro_ite: return "Pro-ITE - Isolation thermique extérieure"
        case .eco_artisan: return "Éco-Artisan"
        case .certibat: return "Certibat - Certification bâtiment"
        case .cekal: return "Cekal - Étanchéité des fenêtres"
        case .cerga: return "CERGA - Centre d'Études et de Recherches Gazières et Aquatiques"
        case .wtcb: return "WTCB - Centre Scientifique et Technique de la Construction"
        case .belgium_green_building: return "Belgium Green Building Council"
        case .atg: return "ATG - Agrément Technique Général"
        case .ce_marking: return "Marquage CE - Conformité Européenne"
        case .iso_9001: return "ISO 9001 - Management de la qualité"
        case .iso_14001: return "ISO 14001 - Management environnemental"
        case .ohsas_18001: return "OHSAS 18001 - Santé et sécurité au travail"
        }
    }
    
    var country: Country? {
        switch self {
        case .rge, .qualibat, .qualit_enr, .pro_ite, .eco_artisan, .certibat, .cekal:
            return .france
        case .cerga, .wtcb, .belgium_green_building, .atg:
            return .belgium
        case .ce_marking, .iso_9001, .iso_14001, .ohsas_18001:
            return nil // Européennes
        }
    }
    
    var icon: String {
        switch self {
        case .rge: return "leaf.circle.fill"
        case .qualibat: return "checkmark.seal.fill"
        case .qualit_enr: return "sun.max.fill"
        case .pro_ite: return "house.fill"
        case .eco_artisan: return "hammer.circle.fill"
        case .certibat: return "building.2.crop.circle.fill"
        case .cekal: return "window.vertical.closed"
        case .cerga: return "drop.circle.fill"
        case .wtcb: return "building.columns.circle.fill"
        case .belgium_green_building: return "leaf.arrow.circlepath"
        case .atg: return "checkmark.circle.fill"
        case .ce_marking: return "star.circle.fill"
        case .iso_9001: return "star.square.fill"
        case .iso_14001: return "leaf.fill"
        case .ohsas_18001: return "shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .rge, .qualit_enr, .eco_artisan: return .green
        case .qualibat, .certibat, .atg: return .blue
        case .pro_ite, .cekal: return .orange
        case .cerga: return .cyan
        case .wtcb, .belgium_green_building: return .purple
        case .ce_marking: return .yellow
        case .iso_9001, .iso_14001, .ohsas_18001: return .gray
        }
    }
}

// MARK: - Note: Core Data extensions are in BTPCoreDataExtension.swift
// This keeps the enums and data structures separate from the persistence layer
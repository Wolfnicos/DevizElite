import Foundation
import CoreData

// MARK: - Core Data Extension for BTP Support
extension Document {
    
    // Add BTP-specific attributes to Document entity
    var typeTravaux: TypeTravaux? {
        get {
            // Check if the attribute exists in the entity before accessing
            if self.entity.attributesByName["btpTypeTravaux"] != nil {
                if let typeString = self.value(forKey: "btpTypeTravaux") as? String {
                    return TypeTravaux(rawValue: typeString)
                }
            }
            // Fallback: try to detect from notes or project name
            return nil
        }
        set {
            // Check if the attribute exists before setting
            if self.entity.attributesByName["btpTypeTravaux"] != nil {
                self.setValue(newValue?.rawValue, forKey: "btpTypeTravaux")
            } else {
                // Store in notes as fallback
                if let type = newValue {
                    let currentNotes = notes ?? ""
                    notes = currentNotes + "\nTypeTravaux: \(type.rawValue)"
                }
            }
        }
    }
    
    var zoneTravaux: ZoneTravaux? {
        get {
            if self.entity.attributesByName["btpZoneTravaux"] != nil {
                if let zoneString = self.value(forKey: "btpZoneTravaux") as? String {
                    return ZoneTravaux(rawValue: zoneString)
                }
            }
            return nil
        }
        set {
            if self.entity.attributesByName["btpZoneTravaux"] != nil {
                self.setValue(newValue?.rawValue, forKey: "btpZoneTravaux")
            } else {
                // Fallback to notes
                if let zone = newValue {
                    let currentNotes = notes ?? ""
                    notes = currentNotes + "\nZoneTravaux: \(zone.rawValue)"
                }
            }
        }
    }
    
    var btpCountry: Country {
        get {
            if self.entity.attributesByName["btpCountry"] != nil {
                if let countryString = self.value(forKey: "btpCountry") as? String,
                   let country = Country(rawValue: countryString) {
                    return country
                }
            }
            // Fallback to language or currency code to guess country
            if currencyCode == "EUR" && language == "fr" {
                return .france
            } else if currencyCode == "EUR" && language == "nl" {
                return .belgium
            }
            return .france
        }
        set {
            if self.entity.attributesByName["btpCountry"] != nil {
                self.setValue(newValue.rawValue, forKey: "btpCountry")
            } else {
                // Fallback: update language and currency
                switch newValue {
                case .france:
                    language = "fr"
                    currencyCode = "EUR"
                case .belgium:
                    language = "nl"
                    currencyCode = "EUR"
                case .luxembourg:
                    language = "fr"
                    currencyCode = "EUR"
                }
            }
        }
    }
    
    var btpLanguage: AppLanguage {
        get {
            if self.entity.attributesByName["btpLanguage"] != nil {
                if let langString = self.value(forKey: "btpLanguage") as? String,
                   let appLanguage = AppLanguage(rawValue: langString) {
                    return appLanguage
                }
            }
            // Fallback to document language
            if let lang = language {
                return AppLanguage(rawValue: lang) ?? .french
            }
            return .french
        }
        set {
            if self.entity.attributesByName["btpLanguage"] != nil {
                self.setValue(newValue.rawValue, forKey: "btpLanguage")
            } else {
                language = newValue.rawValue
            }
        }
    }
    
    var certifications: [CertificationBTP] {
        get {
            if self.entity.attributesByName["btpCertifications"] != nil {
                if let certsString = self.value(forKey: "btpCertifications") as? String {
                    return certsString.split(separator: ",").compactMap { 
                        CertificationBTP(rawValue: String($0).trimmingCharacters(in: .whitespacesAndNewlines)) 
                    }
                }
            }
            return []
        }
        set {
            let certsString = newValue.map { $0.rawValue }.joined(separator: ",")
            if self.entity.attributesByName["btpCertifications"] != nil {
                self.setValue(certsString, forKey: "btpCertifications")
            } else {
                // Store in notes as fallback
                if !newValue.isEmpty {
                    let currentNotes = notes ?? ""
                    notes = currentNotes + "\nCertifications: \(certsString)"
                }
            }
        }
    }
    
    // Project specific information - use existing project fields where possible
    var projectStartDate: Date? {
        get { 
            if self.entity.attributesByName["btpProjectStartDate"] != nil {
                if let date = self.value(forKey: "btpProjectStartDate") as? Date {
                    return date
                }
            }
            // Fallback to issue date if no specific start date
            return issueDate
        }
        set { 
            if self.entity.attributesByName["btpProjectStartDate"] != nil {
                self.setValue(newValue, forKey: "btpProjectStartDate")
            } else {
                // Can't store separately, use issue date as fallback
                if newValue != nil {
                    issueDate = newValue
                }
            }
        }
    }
    
    var projectEndDate: Date? {
        get { 
            if self.entity.attributesByName["btpProjectEndDate"] != nil {
                if let date = self.value(forKey: "btpProjectEndDate") as? Date {
                    return date
                }
            }
            // Fallback to due date if available
            return dueDate
        }
        set { 
            if self.entity.attributesByName["btpProjectEndDate"] != nil {
                self.setValue(newValue, forKey: "btpProjectEndDate")
            } else {
                // Use due date as fallback
                if newValue != nil {
                    dueDate = newValue
                }
            }
        }
    }
    
    var projectPhase: String? {
        get { 
            if self.entity.attributesByName["btpProjectPhase"] != nil {
                if let phase = self.value(forKey: "btpProjectPhase") as? String {
                    return phase
                }
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpProjectPhase"] != nil {
                self.setValue(newValue, forKey: "btpProjectPhase")
            } else {
                // Store in notes as fallback
                if let phase = newValue {
                    let currentNotes = notes ?? ""
                    notes = currentNotes + "\nPhase: \(phase)"
                }
            }
        }
    }
    
    var projectCoordinator: String? {
        get { 
            if self.entity.attributesByName["btpProjectCoordinator"] != nil {
                if let coordinator = self.value(forKey: "btpProjectCoordinator") as? String {
                    return coordinator
                }
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpProjectCoordinator"] != nil {
                self.setValue(newValue, forKey: "btpProjectCoordinator")
            } else {
                // Store in notes as fallback
                if let coordinator = newValue {
                    let currentNotes = notes ?? ""
                    notes = currentNotes + "\nCoordinator: \(coordinator)"
                }
            }
        }
    }
    
    var permitNumber: String? {
        get { 
            if self.entity.attributesByName["btpPermitNumber"] != nil {
                if let permit = self.value(forKey: "btpPermitNumber") as? String {
                    return permit
                }
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpPermitNumber"] != nil {
                self.setValue(newValue, forKey: "btpPermitNumber")
            } else {
                // Store in notes as fallback
                if let permit = newValue {
                    let currentNotes = notes ?? ""
                    notes = currentNotes + "\nPermit: \(permit)"
                }
            }
        }
    }
    
    // Financial BTP information
    var advance: NSDecimalNumber? {
        get { 
            if self.entity.attributesByName["btpAdvance"] != nil {
                if let advance = self.value(forKey: "btpAdvance") as? NSDecimalNumber {
                    return advance
                }
            }
            return NSDecimalNumber.zero
        }
        set { 
            if self.entity.attributesByName["btpAdvance"] != nil {
                self.setValue(newValue, forKey: "btpAdvance")
            } else {
                // Can't store advance separately - this is a limitation
                print("Warning: Cannot store advance amount - Core Data field missing")
            }
        }
    }
    
    // retentionPercent already exists in Core Data model
    
    var insuranceNumber: String? {
        get { 
            if self.entity.attributesByName["btpInsuranceNumber"] != nil {
                if let insurance = self.value(forKey: "btpInsuranceNumber") as? String {
                    return insurance
                }
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpInsuranceNumber"] != nil {
                self.setValue(newValue, forKey: "btpInsuranceNumber")
            } else {
                // Store in notes as fallback
                if let insurance = newValue {
                    let currentNotes = notes ?? ""
                    notes = currentNotes + "\nInsurance: \(insurance)"
                }
            }
        }
    }
    
    var latePaymentInterest: Double {
        get { 
            if self.entity.attributesByName["btpLatePaymentInterest"] != nil {
                if let interest = self.value(forKey: "btpLatePaymentInterest") as? Double {
                    return interest
                }
            }
            return 0.0
        }
        set { 
            if self.entity.attributesByName["btpLatePaymentInterest"] != nil {
                self.setValue(newValue, forKey: "btpLatePaymentInterest")
            } else {
                // Store in notes as fallback if needed
                if newValue > 0 {
                    let currentNotes = notes ?? ""
                    notes = currentNotes + "\nLateInterest: \(newValue)%"
                }
            }
        }
    }
    
    // Auto-generated document numbers based on country
    func generateDocumentNumber(isQuote: Bool = false) -> String {
        let country = self.btpCountry
        let prefix = isQuote ? country.quotePrefix : country.invoicePrefix
        let year = Calendar.current.component(.year, from: issueDate ?? Date())
        
        // Get the next sequential number for this year and type
        let context = self.managedObjectContext!
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        
        let yearPredicate = NSPredicate(format: "number BEGINSWITH %@", "\(prefix)\(year)")
        request.predicate = yearPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "number", ascending: false)]
        
        do {
            let documents = try context.fetch(request)
            let lastNumber = documents.first?.number ?? "\(prefix)\(year)0000"
            
            // Extract the sequential number part
            let numberPart = String(lastNumber.dropFirst("\(prefix)\(year)".count))
            let nextNumber = (Int(numberPart) ?? 0) + 1
            
            return String(format: "%@%d%04d", prefix, year, nextNumber)
        } catch {
            // Fallback to basic numbering
            return String(format: "%@%d0001", prefix, year)
        }
    }
    
    // Helper to get appropriate VAT rate based on work type and country
    func suggestedVATRate() -> Double {
        let country = self.btpCountry
        let workType = self.typeTravaux
        
        switch (country, workType) {
        case (.france, .renovation), (.france, .amenagement), (.france, .entretien), (.france, .reparation):
            return 0.10 // TVA réduite 10% pour rénovation
        case (.france, .neuf), (.france, .`extension`):
            return 0.20 // TVA normale 20% pour neuf
        case (.belgium, .renovation), (.belgium, .amenagement), (.belgium, .entretien), (.belgium, .reparation):
            return 0.06 // TVA réduite 6% pour rénovation
        case (.belgium, .neuf), (.belgium, .`extension`):
            return 0.21 // TVA normale 21% pour neuf
        default:
            return country.standardVatRate
        }
    }
}

extension LineItem {
    
    var corpsEtat: CorpsEtat? {
        get {
            if self.entity.attributesByName["btpCorpsEtat"] != nil {
                if let corpsString = self.value(forKey: "btpCorpsEtat") as? String {
                    return CorpsEtat(rawValue: corpsString)
                }
            }
            // Fallback: try to parse from item description or notes
            return nil
        }
        set {
            if self.entity.attributesByName["btpCorpsEtat"] != nil {
                self.setValue(newValue?.rawValue, forKey: "btpCorpsEtat")
            } else {
                // Store in description or notes as fallback
                if let corps = newValue {
                    let currentDescription = itemDescription ?? ""
                    itemDescription = currentDescription + " [\(corps.rawValue)]"
                }
            }
        }
    }
    
    var lotNumber: String? {
        get { 
            if self.entity.attributesByName["btpLotNumber"] != nil {
                return self.value(forKey: "btpLotNumber") as? String
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpLotNumber"] != nil {
                self.setValue(newValue, forKey: "btpLotNumber")
            } else {
                // Store in description as fallback
                if let lot = newValue {
                    let currentDescription = itemDescription ?? ""
                    itemDescription = currentDescription + " [LOT: \(lot)]"
                }
            }
        }
    }
    
    var uniteBTP: UniteBTP? {
        get {
            if self.entity.attributesByName["btpUnit"] != nil {
                if let uniteString = self.value(forKey: "btpUnit") as? String {
                    return UniteBTP(rawValue: uniteString)
                }
            }
            // Fallback to existing unit field
            if let existingUnit = unit {
                return UniteBTP(rawValue: existingUnit)
            }
            return nil
        }
        set {
            if self.entity.attributesByName["btpUnit"] != nil {
                self.setValue(newValue?.rawValue, forKey: "btpUnit")
            } else {
                // Use existing unit field as fallback
                unit = newValue?.rawValue
            }
        }
    }
    
    var marge: Double {
        get { 
            if self.entity.attributesByName["btpMarge"] != nil {
                return self.value(forKey: "btpMarge") as? Double ?? 0.0
            }
            return 0.0
        }
        set { 
            if self.entity.attributesByName["btpMarge"] != nil {
                self.setValue(newValue, forKey: "btpMarge")
            } else {
                // Can't store margin separately - this is a limitation
                print("Warning: Cannot store margin - Core Data field missing")
            }
        }
    }
    
    var coutAchat: NSDecimalNumber? {
        get { 
            if self.entity.attributesByName["btpCoutAchat"] != nil {
                return self.value(forKey: "btpCoutAchat") as? NSDecimalNumber
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpCoutAchat"] != nil {
                self.setValue(newValue, forKey: "btpCoutAchat")
            } else {
                // Can't store cost separately - this is a limitation
                print("Warning: Cannot store cost price - Core Data field missing")
            }
        }
    }
    
    var workStartDate: Date? {
        get { 
            if self.entity.attributesByName["btpWorkStartDate"] != nil {
                return self.value(forKey: "btpWorkStartDate") as? Date
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpWorkStartDate"] != nil {
                self.setValue(newValue, forKey: "btpWorkStartDate")
            } else {
                // Can't store work dates separately - this is a limitation
                print("Warning: Cannot store work start date - Core Data field missing")
            }
        }
    }
    
    var workEndDate: Date? {
        get { 
            if self.entity.attributesByName["btpWorkEndDate"] != nil {
                return self.value(forKey: "btpWorkEndDate") as? Date
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpWorkEndDate"] != nil {
                self.setValue(newValue, forKey: "btpWorkEndDate")
            } else {
                // Can't store work dates separately - this is a limitation
                print("Warning: Cannot store work end date - Core Data field missing")
            }
        }
    }
    
    var isCompleted: Bool {
        get { 
            if self.entity.attributesByName["btpIsCompleted"] != nil {
                return self.value(forKey: "btpIsCompleted") as? Bool ?? false
            }
            return false
        }
        set { 
            if self.entity.attributesByName["btpIsCompleted"] != nil {
                self.setValue(newValue, forKey: "btpIsCompleted")
            } else {
                // Can't store completion status separately - this is a limitation
                print("Warning: Cannot store completion status - Core Data field missing")
            }
        }
    }
    
    var specifications: String? {
        get { 
            if self.entity.attributesByName["btpSpecifications"] != nil {
                return self.value(forKey: "btpSpecifications") as? String
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpSpecifications"] != nil {
                self.setValue(newValue, forKey: "btpSpecifications")
            } else {
                // Store in description as fallback
                if let specs = newValue {
                    let currentDescription = itemDescription ?? ""
                    itemDescription = currentDescription + "\n[Specs: \(specs)]"
                }
            }
        }
    }
    
    var materials: String? {
        get { 
            if self.entity.attributesByName["btpMaterials"] != nil {
                return self.value(forKey: "btpMaterials") as? String
            }
            return nil
        }
        set { 
            if self.entity.attributesByName["btpMaterials"] != nil {
                self.setValue(newValue, forKey: "btpMaterials")
            } else {
                // Store in description as fallback
                if let materials = newValue {
                    let currentDescription = itemDescription ?? ""
                    itemDescription = currentDescription + "\n[Materials: \(materials)]"
                }
            }
        }
    }
    
    // Calculated properties
    var profitMargin: NSDecimalNumber {
        guard let cost = coutAchat, cost.doubleValue > 0 else { return NSDecimalNumber.zero }
        let selling = unitPrice ?? NSDecimalNumber.zero
        let margin = selling.subtracting(cost)
        return margin
    }
    
    var profitMarginPercentage: Double {
        guard let cost = coutAchat, cost.doubleValue > 0 else { return 0.0 }
        let margin = profitMargin.doubleValue
        return (margin / cost.doubleValue) * 100
    }
    
    var isRentable: Bool {
        return profitMarginPercentage >= marge
    }
    
    // Helper to get the localized unit name
    var localizedUnit: String {
        return uniteBTP?.localized ?? unit ?? ""
    }
    
    // Helper to get the category color for the corps d'état
    var categoryColor: String {
        return corpsEtat?.color.description ?? "#000000"
    }
}

extension Client {
    
    // Add postal code support
    var postalCode: String? {
        get { 
            if self.entity.attributesByName["btpPostalCode"] != nil {
                return self.value(forKey: "btpPostalCode") as? String
            }
            // Try to extract from existing address
            return extractPostalCodeFromAddress()
        }
        set { 
            if self.entity.attributesByName["btpPostalCode"] != nil {
                self.setValue(newValue, forKey: "btpPostalCode")
            } else {
                // Store in address as fallback
                if let postal = newValue {
                    let currentAddress = address ?? ""
                    address = "\(postal) \(currentAddress)".trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
    }
    
    var companyRegistration: String? {
        get { 
            if self.entity.attributesByName["btpCompanyRegistration"] != nil {
                return self.value(forKey: "btpCompanyRegistration") as? String
            }
            // Try to extract from taxId or notes
            return taxId
        }
        set { 
            if self.entity.attributesByName["btpCompanyRegistration"] != nil {
                self.setValue(newValue, forKey: "btpCompanyRegistration")
            } else {
                // Store in taxId as fallback
                if taxId == nil {
                    taxId = newValue
                } else if let registration = newValue {
                    let currentNotes = notes ?? ""
                    notes = currentNotes + "\nRegistration: \(registration)"
                }
            }
        }
    }
    
    var clientType: ClientType {
        get {
            if self.entity.attributesByName["btpClientType"] != nil {
                if let typeString = self.value(forKey: "btpClientType") as? String,
                   let type = ClientType(rawValue: typeString) {
                    return type
                }
            }
            // Fallback: guess from existing data
            if taxId != nil || (name?.contains("SARL") == true) || (name?.contains("SAS") == true) {
                return .company
            }
            return .individual
        }
        set {
            if self.entity.attributesByName["btpClientType"] != nil {
                self.setValue(newValue.rawValue, forKey: "btpClientType")
            } else {
                // Store in notes as fallback
                let currentNotes = notes ?? ""
                notes = currentNotes + "\nType: \(newValue.rawValue)"
            }
        }
    }
    
    private func extractPostalCodeFromAddress() -> String? {
        guard let address = address else { return nil }
        
        // Simple pattern matching for 5-digit postal codes
        let components = address.components(separatedBy: .whitespacesAndNewlines)
        for component in components {
            if component.count == 5, component.allSatisfy({ $0.isNumber }) {
                return component
            }
        }
        
        return nil
    }
    
    // Helper to format the full address
    var fullAddress: String {
        var components: [String] = []
        
        if let address = address, !address.isEmpty {
            components.append(address)
        }
        
        var cityLine: [String] = []
        if let postal = postalCode, !postal.isEmpty {
            cityLine.append(postal)
        }
        if let city = city, !city.isEmpty {
            cityLine.append(city)
        }
        if !cityLine.isEmpty {
            components.append(cityLine.joined(separator: " "))
        }
        
        if let country = country, !country.isEmpty {
            components.append(country)
        }
        
        return components.joined(separator: "\n")
    }
    
    // Helper to get display name with company type
    var displayName: String {
        switch clientType {
        case .individual:
            return name ?? ""
        case .company:
            return (name ?? "") + (companyRegistration != nil ? " (\(companyRegistration!))" : "")
        }
    }
}

// MARK: - Additional Enums for BTP
enum ClientType: String, CaseIterable, Codable {
    case individual = "Particulier"
    case company = "Entreprise"
    
    var localized: String {
        switch self {
        case .individual: return L10n.t("client.individual")
        case .company: return L10n.t("client.company")
        }
    }
}

// MARK: - Core Data Migration Helper
class BTPCoreDataMigration {
    
    // Method to add BTP attributes to existing Core Data model
    static func addBTPAttributesToModel(_ model: NSManagedObjectModel) {
        
        // Document entity BTP attributes
        if let documentEntity = model.entitiesByName["Document"] {
            let btpAttributes: [(String, NSAttributeType, Any?)] = [
                ("btpTypeTravaux", .stringAttributeType, nil),
                ("btpZoneTravaux", .stringAttributeType, nil),
                ("btpCountry", .stringAttributeType, "FR"),
                ("btpLanguage", .stringAttributeType, "fr"),
                ("btpCertifications", .stringAttributeType, nil),
                ("btpProjectStartDate", .dateAttributeType, nil),
                ("btpProjectEndDate", .dateAttributeType, nil),
                ("btpProjectPhase", .stringAttributeType, nil),
                ("btpProjectCoordinator", .stringAttributeType, nil),
                ("btpPermitNumber", .stringAttributeType, nil),
                ("btpAdvance", .decimalAttributeType, NSDecimalNumber.zero),
                ("btpRetentionPercent", .doubleAttributeType, 0.0),
                ("btpInsuranceNumber", .stringAttributeType, nil),
                ("btpLatePaymentInterest", .doubleAttributeType, 0.0)
            ]
            
            for (name, type, defaultValue) in btpAttributes {
                if documentEntity.attributesByName[name] == nil {
                    let attribute = NSAttributeDescription()
                    attribute.name = name
                    attribute.attributeType = type
                    attribute.isOptional = defaultValue == nil
                    attribute.defaultValue = defaultValue
                    documentEntity.properties.append(attribute)
                }
            }
        }
        
        // LineItem entity BTP attributes
        if let lineItemEntity = model.entitiesByName["LineItem"] {
            let btpAttributes: [(String, NSAttributeType, Any?)] = [
                ("btpCorpsEtat", .stringAttributeType, nil),
                ("btpLotNumber", .stringAttributeType, nil),
                ("btpUnit", .stringAttributeType, nil),
                ("btpMarge", .doubleAttributeType, 0.0),
                ("btpCoutAchat", .decimalAttributeType, nil),
                ("btpWorkStartDate", .dateAttributeType, nil),
                ("btpWorkEndDate", .dateAttributeType, nil),
                ("btpIsCompleted", .booleanAttributeType, false),
                ("btpSpecifications", .stringAttributeType, nil),
                ("btpMaterials", .stringAttributeType, nil)
            ]
            
            for (name, type, defaultValue) in btpAttributes {
                if lineItemEntity.attributesByName[name] == nil {
                    let attribute = NSAttributeDescription()
                    attribute.name = name
                    attribute.attributeType = type
                    attribute.isOptional = defaultValue == nil
                    attribute.defaultValue = defaultValue
                    lineItemEntity.properties.append(attribute)
                }
            }
        }
        
        // Client entity BTP attributes
        if let clientEntity = model.entitiesByName["Client"] {
            let btpAttributes: [(String, NSAttributeType, Any?)] = [
                ("btpPostalCode", .stringAttributeType, nil),
                ("btpCompanyRegistration", .stringAttributeType, nil),
                ("btpClientType", .stringAttributeType, "Particulier")
            ]
            
            for (name, type, defaultValue) in btpAttributes {
                if clientEntity.attributesByName[name] == nil {
                    let attribute = NSAttributeDescription()
                    attribute.name = name
                    attribute.attributeType = type
                    attribute.isOptional = defaultValue == nil
                    attribute.defaultValue = defaultValue
                    clientEntity.properties.append(attribute)
                }
            }
        }
    }
}
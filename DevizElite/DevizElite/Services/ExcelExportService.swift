import Foundation
import CoreData
import UniformTypeIdentifiers

// MARK: - Excel Export Service for Accounting Software Compatibility
class ExcelExportService: ObservableObject {
    static let shared = ExcelExportService()
    
    private init() {}
    
    // MARK: - Export Types
    enum ExportFormat: String, CaseIterable {
        case sage = "Sage"
        case ciel = "Ciel"
        case ebp = "EBP"
        case quadratus = "Quadratus"
        case generic = "Generic CSV"
        
        var fileExtension: String {
            switch self {
            case .sage: return "txt"
            case .ciel: return "csv"
            case .ebp: return "csv"
            case .quadratus: return "qif"
            case .generic: return "csv"
            }
        }
        
        var separator: String {
            switch self {
            case .sage: return "\t"
            case .ciel, .ebp, .generic: return ";"
            case .quadratus: return ","
            }
        }
    }
    
    enum ExportScope: String, CaseIterable {
        case documents = "Documents"
        case clients = "Clients"
        case items = "Items"
        case accounting = "Accounting Entries"
        
        var localized: String {
            switch self {
            case .documents: return L10n.t("export.documents")
            case .clients: return L10n.t("export.clients")
            case .items: return L10n.t("export.items")
            case .accounting: return L10n.t("export.accounting")
            }
        }
    }
    
    struct ExportOptions {
        let format: ExportFormat
        let scope: ExportScope
        let dateRange: DateInterval?
        let includeVAT: Bool
        let includeDrafts: Bool
        let groupByClient: Bool
        let currency: String
        
        static let `default` = ExportOptions(
            format: .generic,
            scope: .documents,
            dateRange: nil,
            includeVAT: true,
            includeDrafts: false,
            groupByClient: false,
            currency: "EUR"
        )
    }
    
    // MARK: - Main Export Function
    func exportData(options: ExportOptions, context: NSManagedObjectContext) throws -> URL {
        switch options.scope {
        case .documents:
            return try exportDocuments(options: options, context: context)
        case .clients:
            return try exportClients(options: options, context: context)
        case .items:
            return try exportItems(options: options, context: context)
        case .accounting:
            return try exportAccountingEntries(options: options, context: context)
        }
    }
    
    // MARK: - Document Export
    private func exportDocuments(options: ExportOptions, context: NSManagedObjectContext) throws -> URL {
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        
        // Apply filters
        var predicates: [NSPredicate] = []
        
        if !options.includeDrafts {
            predicates.append(NSPredicate(format: "status != %@", "Draft"))
        }
        
        if let dateRange = options.dateRange {
            predicates.append(NSPredicate(format: "issueDate >= %@ AND issueDate <= %@", 
                                       dateRange.start as NSDate, dateRange.end as NSDate))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "issueDate", ascending: true)]
        
        let documents = try context.fetch(request)
        
        switch options.format {
        case .sage:
            return try exportDocumentsToSage(documents: documents, options: options)
        case .ciel:
            return try exportDocumentsToCiel(documents: documents, options: options)
        case .ebp:
            return try exportDocumentsToEBP(documents: documents, options: options)
        case .quadratus:
            return try exportDocumentsToQuadratus(documents: documents, options: options)
        case .generic:
            return try exportDocumentsToGeneric(documents: documents, options: options)
        }
    }
    
    // MARK: - Sage Export Format
    private func exportDocumentsToSage(documents: [Document], options: ExportOptions) throws -> URL {
        var content = ""
        
        // Sage header
        content += "JournalCode\tDate\tAccountCode\tDescription\tDebitAmount\tCreditAmount\tReference\n"
        
        for document in documents {
            let journalCode = document.type == "Invoice" ? "VT" : "DV" // VT = Ventes, DV = Devis
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "ddMMyyyy"
            let date = dateFormatter.string(from: document.issueDate ?? Date())
            
            let clientAccount = "411\(document.client?.id?.uuidString.prefix(3) ?? "000")"
            let salesAccount = "701000"
            let vatAccount = "445710"
            
            let reference = document.number ?? ""
            let description = "Facture \(reference) - \(document.client?.name ?? "")"
            
            // Client debit line
            let totalAmount = document.total?.doubleValue ?? 0.0
            content += "\(journalCode)\t\(date)\t\(clientAccount)\t\(description)\t\(String(format: "%.2f", totalAmount))\t0.00\t\(reference)\n"
            
            // Sales credit line
            let subtotalAmount = document.subtotal?.doubleValue ?? 0.0
            content += "\(journalCode)\t\(date)\t\(salesAccount)\t\(description)\t0.00\t\(String(format: "%.2f", subtotalAmount))\t\(reference)\n"
            
            // VAT credit line
            if options.includeVAT {
                let vatAmount = document.taxTotal?.doubleValue ?? 0.0
                if vatAmount > 0 {
                    content += "\(journalCode)\t\(date)\t\(vatAccount)\tTVA \(description)\t0.00\t\(String(format: "%.2f", vatAmount))\t\(reference)\n"
                }
            }
        }
        
        return try saveToFile(content: content, filename: "sage_export", extension: "txt")
    }
    
    // MARK: - Ciel Export Format
    private func exportDocumentsToCiel(documents: [Document], options: ExportOptions) throws -> URL {
        var content = ""
        
        // Ciel header
        content += "Date;Journal;Compte;Libelle;Debit;Credit;Reference;Piece\n"
        
        for document in documents {
            let journal = document.type == "Invoice" ? "VT" : "DV"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            let date = dateFormatter.string(from: document.issueDate ?? Date())
            
            let clientAccount = "411\(String(document.client?.id?.uuidString.prefix(6) ?? "000000"))"
            let salesAccount = "706000"
            let vatAccount = "44571"
            
            let reference = document.number ?? ""
            let piece = reference
            let description = "Fact. \(reference)"
            
            // Client line
            let totalAmount = document.total?.doubleValue ?? 0.0
            content += "\(date);\(journal);\(clientAccount);\(description);\(String(format: "%.2f", totalAmount));0,00;\(reference);\(piece)\n"
            
            // Sales line
            let subtotalAmount = document.subtotal?.doubleValue ?? 0.0
            content += "\(date);\(journal);\(salesAccount);\(description);0,00;\(String(format: "%.2f", subtotalAmount));\(reference);\(piece)\n"
            
            // VAT line
            if options.includeVAT {
                let vatAmount = document.taxTotal?.doubleValue ?? 0.0
                if vatAmount > 0 {
                    content += "\(date);\(journal);\(vatAccount);TVA \(description);0,00;\(String(format: "%.2f", vatAmount));\(reference);\(piece)\n"
                }
            }
        }
        
        return try saveToFile(content: content, filename: "ciel_export", extension: "csv")
    }
    
    // MARK: - EBP Export Format
    private func exportDocumentsToEBP(documents: [Document], options: ExportOptions) throws -> URL {
        var content = ""
        
        // EBP header
        content += "Date;Code Journal;Numero Compte;Libelle;Montant;Sens;Reference;Numero Piece\n"
        
        for document in documents {
            let journal = document.type == "Invoice" ? "VEN" : "DIV"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            let date = dateFormatter.string(from: document.issueDate ?? Date())
            
            let clientAccount = "411\(String(document.client?.id?.uuidString.prefix(6) ?? "000000"))"
            let salesAccount = "707000"
            let vatAccount = "44571000"
            
            let reference = document.number ?? ""
            let piece = reference
            let description = "Facture \(reference) - \(document.client?.name ?? "")"
            
            // Client line (Debit)
            let totalAmount = document.total?.doubleValue ?? 0.0
            content += "\(date);\(journal);\(clientAccount);\(description);\(String(format: "%.2f", totalAmount));D;\(reference);\(piece)\n"
            
            // Sales line (Credit)
            let subtotalAmount = document.subtotal?.doubleValue ?? 0.0
            content += "\(date);\(journal);\(salesAccount);\(description);\(String(format: "%.2f", subtotalAmount));C;\(reference);\(piece)\n"
            
            // VAT line (Credit)
            if options.includeVAT {
                let vatAmount = document.taxTotal?.doubleValue ?? 0.0
                if vatAmount > 0 {
                    content += "\(date);\(journal);\(vatAccount);TVA \(description);\(String(format: "%.2f", vatAmount));C;\(reference);\(piece)\n"
                }
            }
        }
        
        return try saveToFile(content: content, filename: "ebp_export", extension: "csv")
    }
    
    // MARK: - Quadratus Export Format (QIF)
    private func exportDocumentsToQuadratus(documents: [Document], options: ExportOptions) throws -> URL {
        var content = ""
        
        for document in documents {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            let date = dateFormatter.string(from: document.issueDate ?? Date())
            
            let totalAmount = document.total?.doubleValue ?? 0.0
            let description = "Facture \(document.number ?? "") - \(document.client?.name ?? "")"
            
            content += "!Type:Cash\n"
            content += "D\(date)\n"
            content += "T\(String(format: "%.2f", totalAmount))\n"
            content += "P\(description)\n"
            content += "L[Ventes]\n"
            content += "^\n"
        }
        
        return try saveToFile(content: content, filename: "quadratus_export", extension: "qif")
    }
    
    // MARK: - Generic CSV Export
    private func exportDocumentsToGeneric(documents: [Document], options: ExportOptions) throws -> URL {
        var content = ""
        
        // Generic header
        content += "Date;Type;Number;Client;Project;Subtotal;VAT;Total;Currency;Status;Due Date;Payment Terms\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        for document in documents {
            let date = dateFormatter.string(from: document.issueDate ?? Date())
            let dueDate = document.dueDate != nil ? dateFormatter.string(from: document.dueDate!) : ""
            let type = document.type ?? ""
            let number = document.number ?? ""
            let client = document.client?.name ?? ""
            let project = document.projectName ?? ""
            let subtotal = String(format: "%.2f", document.subtotal?.doubleValue ?? 0.0)
            let vat = String(format: "%.2f", document.taxTotal?.doubleValue ?? 0.0)
            let total = String(format: "%.2f", document.total?.doubleValue ?? 0.0)
            let currency = document.currencyCode ?? options.currency
            let status = document.status ?? ""
            let paymentTerms = document.paymentTerms ?? ""
            
            content += "\(date);\(type);\(number);\(client);\(project);\(subtotal);\(vat);\(total);\(currency);\(status);\(dueDate);\(paymentTerms)\n"
        }
        
        return try saveToFile(content: content, filename: "documents_export", extension: "csv")
    }
    
    // MARK: - Client Export
    private func exportClients(options: ExportOptions, context: NSManagedObjectContext) throws -> URL {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let clients = try context.fetch(request)
        var content = ""
        
        // Header
        content += "Name;Email;Phone;Address;City;Postal Code;Country;Tax ID;Company Registration;Client Type\n"
        
        for client in clients {
            let name = client.name ?? ""
            let email = client.contactEmail ?? ""
            let phone = client.phone ?? ""
            let address = client.address ?? ""
            let city = client.city ?? ""
            let postalCode = client.postalCode ?? ""
            let country = client.country ?? ""
            let taxId = client.taxId ?? ""
            let companyReg = client.companyRegistration ?? ""
            let clientType = client.clientType.localized
            
            content += "\(name);\(email);\(phone);\(address);\(city);\(postalCode);\(country);\(taxId);\(companyReg);\(clientType)\n"
        }
        
        return try saveToFile(content: content, filename: "clients_export", extension: "csv")
    }
    
    // MARK: - Items Export
    private func exportItems(options: ExportOptions, context: NSManagedObjectContext) throws -> URL {
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let items = try context.fetch(request)
        var content = ""
        
        // Header
        content += "Name;SKU;Unit;Unit Price;Tax Rate;Notes\n"
        
        for item in items {
            let name = item.name ?? ""
            let sku = item.sku ?? ""
            let unit = item.unit ?? ""
            let unitPrice = String(format: "%.2f", item.unitPrice?.doubleValue ?? 0.0)
            let taxRate = String(format: "%.1f", item.taxRate)
            let notes = item.notes ?? ""
            
            content += "\(name);\(sku);\(unit);\(unitPrice);\(taxRate);\(notes)\n"
        }
        
        return try saveToFile(content: content, filename: "items_export", extension: "csv")
    }
    
    // MARK: - Accounting Entries Export
    private func exportAccountingEntries(options: ExportOptions, context: NSManagedObjectContext) throws -> URL {
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        
        var predicates: [NSPredicate] = []
        if !options.includeDrafts {
            predicates.append(NSPredicate(format: "status != %@", "Draft"))
        }
        
        if let dateRange = options.dateRange {
            predicates.append(NSPredicate(format: "issueDate >= %@ AND issueDate <= %@", 
                                       dateRange.start as NSDate, dateRange.end as NSDate))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [NSSortDescriptor(key: "issueDate", ascending: true)]
        
        let documents = try context.fetch(request)
        var content = ""
        
        // Header for detailed accounting entries
        content += "Date;Document Type;Document Number;Client;Account Code;Account Name;Description;Debit;Credit;Corps Etat;Project;VAT Rate\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        for document in documents {
            let date = dateFormatter.string(from: document.issueDate ?? Date())
            let docType = document.type ?? ""
            let docNumber = document.number ?? ""
            let clientName = document.client?.name ?? ""
            let projectName = document.projectName ?? ""
            
            // Client account entry
            let clientAccount = "411000"
            let totalAmount = document.total?.doubleValue ?? 0.0
            content += "\(date);\(docType);\(docNumber);\(clientName);\(clientAccount);Clients;\(clientName);\(String(format: "%.2f", totalAmount));0.00;;\(projectName);0.0\n"
            
            // Line items with corps d'état detail
            for lineItem in document.lineItems?.allObjects as? [LineItem] ?? [] {
                let itemDescription = lineItem.itemDescription ?? ""
                let salesAccount = getSalesAccountForCorpsEtat(lineItem.corpsEtat)
                let accountName = lineItem.corpsEtat?.localized ?? "Ventes"
                let subtotal = (lineItem.unitPrice?.doubleValue ?? 0.0) * (lineItem.quantity?.doubleValue ?? 0.0)
                let discount = subtotal * (lineItem.discount / 100.0)
                let netAmount = subtotal - discount
                let vatRate = lineItem.taxRate
                
                content += "\(date);\(docType);\(docNumber);\(clientName);\(salesAccount);\(accountName);\(itemDescription);0.00;\(String(format: "%.2f", netAmount));\(lineItem.corpsEtat?.rawValue ?? "");\(projectName);\(String(format: "%.1f", vatRate))\n"
                
                // VAT entry for each line item
                if options.includeVAT && vatRate > 0 {
                    let vatAmount = netAmount * (vatRate / 100.0)
                    let vatAccount = "44571000"
                    content += "\(date);\(docType);\(docNumber);\(clientName);\(vatAccount);TVA Collectée;TVA \(itemDescription);0.00;\(String(format: "%.2f", vatAmount));\(lineItem.corpsEtat?.rawValue ?? "");\(projectName);\(String(format: "%.1f", vatRate))\n"
                }
            }
        }
        
        return try saveToFile(content: content, filename: "accounting_entries", extension: "csv")
    }
    
    // MARK: - Helper Functions
    private func getSalesAccountForCorpsEtat(_ corpsEtat: CorpsEtat?) -> String {
        guard let corps = corpsEtat else { return "706000" }
        
        switch corps.category {
        case .grosOeuvre: return "706100"
        case .secondOeuvre: return "706200"
        case .menuiseries: return "706300"
        case .techniques: return "706400"
        case .finitions: return "706500"
        case .exterieur: return "706600"
        case .specialises: return "706700"
        }
    }
    
    private func saveToFile(content: String, filename: String, extension: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent("\(filename).\(`extension`)")
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    // MARK: - Utility Functions
    func getExportFormats() -> [ExportFormat] {
        return ExportFormat.allCases
    }
    
    func getExportScopes() -> [ExportScope] {
        return ExportScope.allCases
    }
    
    func validateExportOptions(_ options: ExportOptions) -> [String] {
        var errors: [String] = []
        
        if options.dateRange != nil && options.dateRange!.start > options.dateRange!.end {
            errors.append(L10n.t("export.error.invalid_date_range"))
        }
        
        if options.currency.isEmpty {
            errors.append(L10n.t("export.error.currency_required"))
        }
        
        return errors
    }
}
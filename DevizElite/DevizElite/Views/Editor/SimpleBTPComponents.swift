import SwiftUI
import CoreData
import AppKit
import PDFKit

// MARK: - Tab Simplu cu Toate Informațiile
struct SimpleBTPInfoTab: View {
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    // Client selector state
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default
    ) private var allClients: FetchedResults<Client>
    
    @State private var selectedClientId: UUID?
    @State private var showingNewClientForm = false
    
    // Company info from settings
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("companyAddress") private var companyAddress = ""
    @AppStorage("companyPhone") private var companyPhone = ""
    @AppStorage("companyEmail") private var companyEmail = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // SECTION: Informations Entreprise (Auto depuis Réglages)
                GroupBox("🏢 Mon Entreprise") {
                    VStack(alignment: .leading, spacing: 8) {
                        if companyName.isEmpty {
                            Text("⚠️ Complétez les données de l'entreprise dans Réglages!")
                                .foregroundColor(.orange)
                                .font(.callout)
                        } else {
                            Text(companyName).font(.headline)
                            if !companyAddress.isEmpty { Text(companyAddress).font(.caption) }
                            HStack {
                                if !companyPhone.isEmpty { Text("📞 \(companyPhone)").font(.caption) }
                                if !companyEmail.isEmpty { Text("✉️ \(companyEmail)").font(.caption) }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // SECTION: Selector Client Simplu
                GroupBox("👤 Client") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Picker("Sélectionner le client", selection: $selectedClientId) {
                                Text("Choisir un client...").tag(nil as UUID?)
                                ForEach(allClients, id: \.id) { client in
                                    Text(client.displayName).tag(client.id)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)
                            .onChange(of: selectedClientId) { oldValue, newValue in
                                if let clientId = newValue {
                                    document.client = allClients.first { $0.id == clientId }
                                    try? viewContext.save()
                                }
                            }
                            
                            Button("➕ Nouveau Client") {
                                showingNewClientForm = true
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Afișează datele clientului selectat
                        if let client = document.client {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(client.displayName).font(.headline)
                                if let address = client.address { Text(address).font(.caption) }
                                HStack {
                                    if let email = client.contactEmail { Text("✉️ \(email)").font(.caption) }
                                    if let phone = client.phone { Text("📞 \(phone)").font(.caption) }
                                }
                                if let taxId = client.taxId { Text("🆔 TVA: \(taxId)").font(.caption) }
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                
                // SECTION: Informations Document
                GroupBox("📋 Détails \(document.type == "invoice" ? "Facture" : "Devis")") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Numéro:")
                                .frame(width: 80, alignment: .leading)
                            TextField("Ex: FA-2024-001", text: Binding(
                                get: { document.number ?? "" },
                                set: { document.number = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        
                        HStack {
                            Text("Date:")
                                .frame(width: 80, alignment: .leading)
                            DatePicker("", selection: Binding(
                                get: { document.issueDate ?? Date() },
                                set: { document.issueDate = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                        }
                        
                        if document.type != "invoice" {
                            HStack {
                                Text("Validité:")
                                    .frame(width: 80, alignment: .leading)
                                DatePicker("", selection: Binding(
                                    get: { document.dueDate ?? Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date() },
                                    set: { document.dueDate = $0 }
                                ), displayedComponents: .date)
                                .labelsHidden()
                            }
                        }
                    }
                }
                
                // SECTION: Chantier et Travaux
                GroupBox("🏗️ Chantier et Travaux") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Adresse chantier:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Ex: 15 rue des Aviateurs, Paris", text: Binding(
                                get: { document.siteAddress ?? "" },
                                set: { document.siteAddress = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        
                        HStack {
                            Text("Pays:")
                                .frame(width: 120, alignment: .leading)
                            Picker("Pays", selection: Binding(
                                get: { document.btpCountry },
                                set: { document.btpCountry = $0 }
                            )) {
                                ForEach(Country.allCases, id: \.self) { country in
                                    Text("\(country.flag) \(country.name)").tag(country)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 200)
                        }
                        
                        HStack {
                            Text("Zone de travaux:")
                                .frame(width: 120, alignment: .leading)
                            Picker("Zone de travaux", selection: Binding(
                                get: { document.zoneTravaux },
                                set: { document.zoneTravaux = $0 }
                            )) {
                                Text("Choisir la zone...").tag(nil as ZoneTravaux?)
                                ForEach(ZoneTravaux.allCases, id: \.self) { zone in
                                    Text(zone.localized).tag(zone as ZoneTravaux?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 200)
                        }
                        
                        HStack {
                            Text("Type de travaux:")
                                .frame(width: 120, alignment: .leading)
                            Picker("Type de travaux", selection: Binding(
                                get: { document.typeTravaux },
                                set: { document.typeTravaux = $0 }
                            )) {
                                Text("Choisir le type...").tag(nil as TypeTravaux?)
                                ForEach(TypeTravaux.allCases, id: \.self) { type in
                                    Text(type.localized).tag(type as TypeTravaux?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 200)
                        }
                        
                        // TVA info
                        if document.typeTravaux != nil {
                            HStack {
                                Text("TVA suggérée:")
                                    .frame(width: 120, alignment: .leading)
                                Text("\(String(format: "%.0f", document.suggestedVATRate() * 100))%")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                                
                                Button("Appliquer à tous") {
                                    applyVATToAllLines()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // Set selected client if document already has one
            selectedClientId = document.client?.id
        }
        .sheet(isPresented: $showingNewClientForm) {
            SimpleClientForm { newClient in
                document.client = newClient
                selectedClientId = newClient.id
                try? viewContext.save()
            }
        }
    }
    
    private func applyVATToAllLines() {
        let suggestedRate = document.suggestedVATRate() * 100
        
        if let lineItems = document.lineItems?.allObjects as? [LineItem] {
            for lineItem in lineItems {
                lineItem.taxRate = suggestedRate
            }
        }
        try? viewContext.save()
    }
}

// MARK: - Tab Simplu pentru Ouvrages/Lucrări
struct SimpleBTPLinesTab: View {
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingCatalog = false
    @State private var showingAIAssistant = false
    
    var sortedLineItems: [LineItem] {
        guard let lineItems = document.lineItems?.allObjects as? [LineItem] else {
            return []
        }
        return lineItems.sorted { $0.position < $1.position }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar simple
            HStack {
                Button("➕ Ajouter ouvrage") {
                    addNewLine()
                }
                .buttonStyle(.borderedProminent)
                
                Button("🏗️ Catalogue BTP") {
                    showingCatalog = true
                }
                .buttonStyle(.bordered)
                
                Button("🤖 Assistant IA") {
                    showingAIAssistant = true
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Text("Total: \(formatCurrency(document.total?.doubleValue ?? 0.0))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding()
            
            Divider()
            
            // Liste simple des ouvrages
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(sortedLineItems, id: \.id) { lineItem in
                        SimpleLineItemRow(lineItem: lineItem, document: document)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingCatalog) {
            NavigationView {
                CatalogSelectionView(document: document)
            }
            .frame(minWidth: 900, minHeight: 700)
        }
        .sheet(isPresented: $showingAIAssistant) {
            BTPAIAssistantView(document: document)
        }
    }
    
    private func addNewLine() {
        let lineItem = LineItem(context: viewContext)
        lineItem.id = UUID()
        lineItem.itemDescription = "Nouvel ouvrage"
        lineItem.quantity = NSDecimalNumber(value: 1)
        lineItem.unitPrice = NSDecimalNumber(value: 0)
        lineItem.taxRate = document.suggestedVATRate() * 100
        lineItem.position = Int16(sortedLineItems.count + 1)
        
        document.addToLineItems(lineItem)
        try? viewContext.save()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

// MARK: - Rând Simplu pentru Lucrare
struct SimpleLineItemRow: View {
    @ObservedObject var lineItem: LineItem
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ligne 1: Description et Corps d'État
            HStack {
                TextField("Description de l'ouvrage", text: Binding(
                    get: { lineItem.itemDescription ?? "" },
                    set: { 
                        lineItem.itemDescription = $0
                        try? viewContext.save()
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
                
                // Corps d'état picker
                Picker("Categorie", selection: Binding(
                    get: { lineItem.corpsEtat },
                    set: { 
                        lineItem.corpsEtat = $0
                        try? viewContext.save()
                    }
                )) {
                    Text("Catégorie").tag(nil as CorpsEtat?)
                    ForEach(CorpsEtat.allCases, id: \.self) { corps in
                        HStack {
                            Circle()
                                .fill(corps.color)
                                .frame(width: 8, height: 8)
                            Text(corps.localized)
                        }.tag(corps as CorpsEtat?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
                
                Button("🗑") {
                    deleteLineItem()
                }
                .foregroundColor(.red)
            }
            
            // Ligne 2: Quantité, Unité, Prix, Total
            HStack(spacing: 12) {
                // Quantité
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quantité").font(.caption).foregroundColor(.secondary)
                    TextField("1", value: Binding(
                        get: { lineItem.quantity?.doubleValue ?? 1.0 },
                        set: { 
                            lineItem.quantity = NSDecimalNumber(value: $0)
                            try? viewContext.save()
                        }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                }
                
                // Unité
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unité").font(.caption).foregroundColor(.secondary)
                    Picker("Unité", selection: Binding(
                        get: { lineItem.uniteBTP },
                        set: { 
                            lineItem.uniteBTP = $0
                            try? viewContext.save()
                        }
                    )) {
                        Text("unité").tag(UniteBTP.unite)
                        Text("m²").tag(UniteBTP.m2)
                        Text("m³").tag(UniteBTP.m3)
                        Text("ml").tag(UniteBTP.ml)
                        Text("forfait").tag(UniteBTP.forfait)
                        Text("poste").tag(UniteBTP.poste)
                        Text("circuit").tag(UniteBTP.circuit)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 80)
                }
                
                // Prix unitaire
                VStack(alignment: .leading, spacing: 2) {
                    Text("Prix unitaire").font(.caption).foregroundColor(.secondary)
                    TextField("0", value: Binding(
                        get: { lineItem.unitPrice?.doubleValue ?? 0.0 },
                        set: { 
                            lineItem.unitPrice = NSDecimalNumber(value: $0)
                            try? viewContext.save()
                        }
                    ), format: .currency(code: document.currencyCode ?? "EUR"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                }
                
                // TVA
                VStack(alignment: .leading, spacing: 2) {
                    Text("TVA %").font(.caption).foregroundColor(.secondary)
                    TextField("20", value: Binding(
                        get: { lineItem.taxRate },
                        set: { 
                            lineItem.taxRate = $0
                            try? viewContext.save()
                        }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                }
                
                Spacer()
                
                // Total
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total").font(.caption).foregroundColor(.secondary)
                    Text(formatLineTotal())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
    }
    
    private func deleteLineItem() {
        viewContext.delete(lineItem)
        try? viewContext.save()
    }
    
    private func formatLineTotal() -> String {
        let quantity = lineItem.quantity?.doubleValue ?? 0
        let unitPrice = lineItem.unitPrice?.doubleValue ?? 0
        let total = quantity * unitPrice
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: total)) ?? "0 €"
    }
}

// MARK: - Footer Simplu cu Export Direct
struct SimpleDocumentFooterView: View {
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isExporting = false
    
    private func closeWindow() {
        NotificationCenter.default.post(name: Notification.Name("CloseWindow"), object: nil)
    }
    
    var body: some View {
        HStack {
            Button("🔄 Numéro Auto") {
                let isQuote = document.type != "invoice"
                document.number = document.generateDocumentNumber(isQuote: isQuote)
                try? viewContext.save()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // Export direct PDF et JPEG
            HStack(spacing: 8) {
                Button("📄 Export PDF") {
                    exportToPDF()
                }
                .buttonStyle(.borderedProminent)
                
                Button("🖼 Export JPEG") {
                    exportToJPEG()
                }
                .buttonStyle(.borderedProminent)
                
                Button("💾 Sauvegarder") {
                    try? viewContext.save()
                }
                .buttonStyle(.bordered)
                
                Button("❌ Fermer") {
                    try? viewContext.save()
                    closeWindow()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }
    
    private func exportToPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(document.number ?? "document").pdf"
        
        if panel.runModal() == .OK, let url = panel.url {
            // Ensure we're on main thread for Core Data access
            if Thread.isMainThread {
                generateAndSavePDF(to: url)
            } else {
                DispatchQueue.main.async {
                    generateAndSavePDF(to: url)
                }
            }
        }
    }
    
    private func generateAndSavePDF(to url: URL) {
        do {
            // Verify document is still valid
            guard !document.isDeleted, 
                  document.managedObjectContext != nil else {
                print("Document is invalid for PDF generation")
                return
            }
            
            // Use the final PDF generator with DEVIS/FACTURE differentiation
            let pdfData = FinalPDFGenerator.generatePDF(for: document)
            
            guard !pdfData.isEmpty else {
                print("Failed to generate PDF data")
                return
            }
            
            try pdfData.write(to: url)
            print("PDF sauvegardé avec succès: \(url.lastPathComponent)")
            
        } catch {
            print("Erreur lors de la génération/sauvegarde PDF: \(error)")
        }
    }
    
    private func exportToJPEG() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.jpeg]
        panel.nameFieldStringValue = "\(document.number ?? "document").jpg"
        
        if panel.runModal() == .OK, let url = panel.url {
            // Generate image from SwiftUI view
            generateAndSaveImage(to: url, format: .jpeg)
        }
    }
    
    private func generateAndSaveImage(to url: URL, format: ImageFormat) {
        do {
            // Verify document is still valid
            guard !document.isDeleted, 
                  document.managedObjectContext != nil else {
                print("Document is invalid for image generation")
                return
            }
            
            // Generate PDF first, then convert to image
            let pdfData = FinalPDFGenerator.generatePDF(for: document)
            
            guard !pdfData.isEmpty else {
                print("Failed to generate PDF for image conversion")
                return
            }
            
            // Convert PDF to image
            if let image = createImageFromPDF(pdfData) {
                let imageData: Data?
                
                switch format {
                case .jpeg:
                    imageData = image.jpegData()
                case .png:
                    imageData = image.pngData()
                }
                
                guard let data = imageData else {
                    print("Failed to create image data")
                    return
                }
                
                try data.write(to: url)
                print("\(format.rawValue.uppercased()) sauvegardé avec succès: \(url.lastPathComponent)")
            }
            
        } catch {
            print("Erreur lors de la génération/sauvegarde image: \(error)")
        }
    }
    
    private func createImageFromPDF(_ pdfData: Data) -> NSImage? {
        guard let provider = CGDataProvider(data: pdfData as CFData),
              let pdfDoc = CGPDFDocument(provider),
              let page = pdfDoc.page(at: 1) else {
            return nil
        }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let image = NSImage(size: pageRect.size)
        
        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.setFillColor(CGColor.white)
            context.fill(pageRect)
            context.drawPDFPage(page)
        }
        image.unlockFocus()
        
        return image
    }
    
    enum ImageFormat {
        case jpeg, png
        
        var rawValue: String {
            switch self {
            case .jpeg: return "jpeg"
            case .png: return "png"
            }
        }
    }
}

// MARK: - Formular Simplu Client Nou
struct SimpleClientForm: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var address = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var taxId = ""
    
    let onClientCreated: (Client) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nouveau Client")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                TextField("Nom du client *", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Adresse", text: $address)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Téléphone", text: $phone)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                
                TextField("SIRET/TVA", text: $taxId)
                    .textFieldStyle(.roundedBorder)
            }
            
            Spacer()
            
            HStack {
                Button("Annuler") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Sauvegarder Client") {
                    saveClient()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
    
    private func saveClient() {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = name
        client.address = address.isEmpty ? nil : address
        client.phone = phone.isEmpty ? nil : phone
        client.contactEmail = email.isEmpty ? nil : email
        client.taxId = taxId.isEmpty ? nil : taxId
        
        try? viewContext.save()
        onClientCreated(client)
        dismiss()
    }
}

// MARK: - Export View Simplu
struct SimpleExportView: View {
    @ObservedObject var document: Document
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Document")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Button("📄 Salvează ca PDF") {
                    exportToPDF()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                
                Button("🖼 Salvează ca JPEG") {
                    exportToJPEG()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                
                Button("🖼 Salvează ca PNG") {
                    exportToPNG()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
            }
            
            Button("Închide") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300, height: 250)
    }
    
    private func exportToPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(document.number ?? "document").pdf"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let pdfData = try PDFService.shared.generatePDF(for: document)
                try pdfData.write(to: url)
                print("PDF salvat: \(url.lastPathComponent)")
            } catch {
                print("Eroare la generarea PDF: \(error)")
            }
        }
        dismiss()
    }
    
    private func exportToJPEG() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.jpeg]
        panel.nameFieldStringValue = "\(document.number ?? "document").jpg"
        
        if panel.runModal() == .OK, let url = panel.url {
            let styleRaw = UserDefaults.standard.string(forKey: "templateStyle") ?? "ModernBTPInvoice"
            let style = TemplateStyle(rawValue: styleRaw) ?? .ModernBTPInvoice
            
            let jpegData = PDFService.shared.generateJPEG(for: document, using: style)
            if let imageData = jpegData.first {
                try? imageData.write(to: url)
                print("JPEG salvat: \(url.lastPathComponent)")
            }
        }
        dismiss()
    }
    
    private func exportToPNG() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(document.number ?? "document").png"
        
        if panel.runModal() == .OK, let url = panel.url {
            let styleRaw = UserDefaults.standard.string(forKey: "templateStyle") ?? "ModernBTPInvoice"
            let style = TemplateStyle(rawValue: styleRaw) ?? .ModernBTPInvoice
            
            let pngData = PDFService.shared.generatePNG(for: document, using: style)
            if let imageData = pngData.first {
                try? imageData.write(to: url)
                print("PNG salvat: \(url.lastPathComponent)")
            }
        }
        dismiss()
    }
}
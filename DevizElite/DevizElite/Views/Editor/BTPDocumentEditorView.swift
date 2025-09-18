import SwiftUI
import CoreData

struct BTPDocumentEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var document: Document
    
    @State private var selectedTab = 0
    @State private var showingExportOptions = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header avec info document et pays
            DocumentHeaderView(document: document)
            
            // Tabs simplifiées - seulement 2 tabs
            TabView(selection: $selectedTab) {
                // Tab 1: Toutes les informations + Client
                SimpleBTPInfoTab(document: document)
                    .tabItem {
                        Image(systemName: "doc.text")
                        Text("Informations")
                    }
                    .tag(0)
                
                // Tab 2: Ouvrages
                SimpleBTPLinesTab(document: document)
                    .tabItem {
                        Image(systemName: "hammer")
                        Text("Ouvrages")
                    }
                    .tag(1)
            }
            .frame(minHeight: 500)
            
            // Footer simple avec export direct
            SimpleDocumentFooterView(document: document)
        }
        .sheet(isPresented: $showingExportOptions) {
            SimpleExportView(document: document)
        }
    }
}

// MARK: - Document Header
struct DocumentHeaderView: View {
    @ObservedObject var document: Document
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(document.type == "Invoice" ? "🧾 Facture" : "📋 Devis")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(document.number ?? "N/A")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    // Badge pour le statut
                    if let status = document.status {
                        StatusBadge(status: InvoiceStatus(rawValue: status.lowercased()) ?? .draft)
                    }
                }
                
                HStack {
                    CountrySelector(document: document)
                    
                    Divider()
                        .frame(height: 20)
                    
                    TypeTravauxSelector(document: document)
                    
                    Divider()
                        .frame(height: 20)
                    
                    ZoneTravauxSelector(document: document)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Total: \(formatCurrency(document.total?.doubleValue ?? 0.0))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let client = document.client {
                    Text(client.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = document.currencyCode ?? "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "0 €"
    }
}

// MARK: - Selectors
struct CountrySelector: View {
    @ObservedObject var document: Document
    
    var body: some View {
        HStack(spacing: 4) {
            Text(document.btpCountry.flag)
            Picker("Pays", selection: Binding(
                get: { document.btpCountry },
                set: { document.btpCountry = $0 }
            )) {
                ForEach(Country.allCases, id: \.self) { country in
                    Text("\(country.flag) \(country.name)").tag(country)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 120)
        }
    }
}

struct TypeTravauxSelector: View {
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: document.typeTravaux?.icon ?? "house.fill")
                .foregroundColor(.blue)
            
            Picker("Type de travaux", selection: Binding(
                get: { document.typeTravaux },
                set: { newValue in
                    document.typeTravaux = newValue
                    try? viewContext.save()
                }
            )) {
                Text("Non défini").tag(nil as TypeTravaux?)
                ForEach(TypeTravaux.allCases, id: \.self) { type in
                    Text(type.localized).tag(type as TypeTravaux?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
        }
    }
}

struct ZoneTravauxSelector: View {
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(document.zoneTravaux?.color ?? .gray)
                .frame(width: 12, height: 12)
            
            Picker("Zone de travaux", selection: Binding(
                get: { document.zoneTravaux },
                set: { newValue in
                    document.zoneTravaux = newValue
                    try? viewContext.save()
                }
            )) {
                Text("Non définie").tag(nil as ZoneTravaux?)
                ForEach(ZoneTravaux.allCases, id: \.self) { zone in
                    Text(zone.localized).tag(zone as ZoneTravaux?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
        }
    }
}

// MARK: - General Info Tab
struct GeneralInfoTab: View {
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Informations projet
                GroupBox("🏗️ Informations Projet") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Nom du projet:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Nom du projet", text: Binding(
                                get: { document.projectName ?? "" },
                                set: { document.projectName = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        
                        HStack {
                            Text("Adresse chantier:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Adresse du chantier", text: Binding(
                                get: { document.siteAddress ?? "" },
                                set: { document.siteAddress = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        
                        HStack {
                            Text("N° de permis:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Numéro de permis", text: Binding(
                                get: { document.permitNumber ?? "" },
                                set: { document.permitNumber = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        
                        HStack {
                            Text("Coordinateur:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Nom du coordinateur", text: Binding(
                                get: { document.projectCoordinator ?? "" },
                                set: { document.projectCoordinator = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                }
                
                // Dates importantes
                GroupBox("📅 Planning Général") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Début prévu:")
                                .frame(width: 120, alignment: .leading)
                            DatePicker("", selection: Binding(
                                get: { document.projectStartDate ?? Date() },
                                set: { document.projectStartDate = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                        }
                        
                        HStack {
                            Text("Fin prévue:")
                                .frame(width: 120, alignment: .leading)
                            DatePicker("", selection: Binding(
                                get: { document.projectEndDate ?? Date() },
                                set: { document.projectEndDate = $0 }
                            ), displayedComponents: .date)
                            .labelsHidden()
                        }
                        
                        HStack {
                            Text("Phase actuelle:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Phase du projet", text: Binding(
                                get: { document.projectPhase ?? "" },
                                set: { document.projectPhase = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                }
                
                // Conditions financières
                GroupBox("💰 Conditions Financières") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Acompte:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Montant acompte", value: Binding(
                                get: { document.advance?.doubleValue ?? 0.0 },
                                set: { document.advance = NSDecimalNumber(value: $0) }
                            ), format: .currency(code: document.currencyCode ?? "EUR"))
                        }
                        
                        HStack {
                            Text("Retenue %):")
                                .frame(width: 120, alignment: .leading)
                            TextField("Pourcentage retenue", value: Binding(
                                get: { document.retentionPercent },
                                set: { document.retentionPercent = $0 }
                            ), format: .percent)
                        }
                        
                        HStack {
                            Text("Intérêts retard:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Taux intérêts", value: Binding(
                                get: { document.latePaymentInterest },
                                set: { document.latePaymentInterest = $0 }
                            ), format: .percent)
                        }
                        
                        HStack {
                            Text("N° Assurance:")
                                .frame(width: 120, alignment: .leading)
                            TextField("Numéro d'assurance", text: Binding(
                                get: { document.insuranceNumber ?? "" },
                                set: { document.insuranceNumber = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                }
                
                // Certifications
                CertificationsSection(document: document)
            }
            .padding()
        }
        .onChange(of: document.typeTravaux) { oldValue, newValue in
            updateVATRatesBasedOnWorkType()
        }
    }
    
    private func updateVATRatesBasedOnWorkType() {
        let suggestedRate = document.suggestedVATRate()
        
        // Mise à jour des taux TVA des lignes existantes
        if let lineItems = document.lineItems?.allObjects as? [LineItem] {
            for lineItem in lineItems {
                if lineItem.taxRate == 0.0 { // Seulement si pas encore défini
                    lineItem.taxRate = suggestedRate * 100 // Convert to percentage
                }
            }
        }
        
        try? viewContext.save()
    }
}

// MARK: - Certifications Section
struct CertificationsSection: View {
    @ObservedObject var document: Document
    @State private var selectedCertifications: Set<CertificationBTP> = []
    
    var body: some View {
        GroupBox("🏆 Certifications Professionnelles") {
            VStack(alignment: .leading, spacing: 8) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(availableCertifications, id: \.self) { certification in
                        CertificationToggle(
                            certification: certification,
                            isSelected: selectedCertifications.contains(certification)
                        ) { isSelected in
                            if isSelected {
                                selectedCertifications.insert(certification)
                            } else {
                                selectedCertifications.remove(certification)
                            }
                            document.certifications = Array(selectedCertifications)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .onAppear {
            selectedCertifications = Set(document.certifications)
        }
    }
    
    private var availableCertifications: [CertificationBTP] {
        let country = document.btpCountry
        return CertificationBTP.allCases.filter { certification in
            certification.country == country || certification.country == nil
        }
    }
}

struct CertificationToggle: View {
    let certification: CertificationBTP
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            HStack(spacing: 6) {
                Image(systemName: certification.icon)
                    .foregroundColor(certification.color)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(certification.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if certification.country != nil {
                        Text(certification.country!.flag)
                            .font(.caption2)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? certification.color.opacity(0.1) : Color(.controlBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Document Footer
struct DocumentFooterView: View {
    @ObservedObject var document: Document
    @Binding var showingExport: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    private func closeWindow() {
        NotificationCenter.default.post(name: Notification.Name("CloseWindow"), object: nil)
    }
    
    var body: some View {
        HStack {
            // Génération automatique numéro
            Button("🔄 Générer N°") {
                generateDocumentNumber()
            }
            .disabled(!(document.number?.isEmpty ?? true))
            
            Spacer()
            
            // Suggestions TVA
            if document.typeTravaux != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("TVA suggérée: \(String(format: "%.0f", document.suggestedVATRate() * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Appliquer à toutes les lignes") {
                        applyVATToAllLines()
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
            
            // Actions principales
            HStack(spacing: 12) {
                Button("📊 Export") {
                    showingExport = true
                }
                .buttonStyle(.bordered)
                
                Button("💾 Sauvegarder") {
                    saveDocument()
                }
                .buttonStyle(.borderedProminent)
                
                Button("❌ Fermer") {
                    saveDocument()
                    closeWindow()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }
    
    private func generateDocumentNumber() {
        let isQuote = document.type != "Invoice"
        document.number = document.generateDocumentNumber(isQuote: isQuote)
        saveDocument()
    }
    
    private func applyVATToAllLines() {
        let suggestedRate = document.suggestedVATRate() * 100
        
        if let lineItems = document.lineItems?.allObjects as? [LineItem] {
            for lineItem in lineItems {
                lineItem.taxRate = suggestedRate
            }
        }
        saveDocument()
    }
    
    private func saveDocument() {
        do {
            try viewContext.save()
        } catch {
            print("Erreur sauvegarde: \(error)")
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let document = Document(context: context)
    document.number = "FA2024001"
    document.type = "Invoice"
    document.issueDate = Date()
    document.total = NSDecimalNumber(value: 15420.50)
    document.currencyCode = "EUR"
    
    return BTPDocumentEditorView(document: document)
        .environment(\.managedObjectContext, context)
        .frame(width: 900, height: 700)
}
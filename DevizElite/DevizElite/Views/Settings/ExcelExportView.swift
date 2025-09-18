import SwiftUI
import CoreData

struct ExcelExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var exportService = ExcelExportService.shared
    
    @State private var selectedFormat: ExcelExportService.ExportFormat = .generic
    @State private var selectedScope: ExcelExportService.ExportScope = .documents
    @State private var includeVAT = true
    @State private var includeDrafts = false
    @State private var groupByClient = false
    @State private var selectedCurrency = "EUR"
    
    @State private var useCustomDateRange = false
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var exportError: String?
    @State private var showingExportResult = false
    
    let currencies = ["EUR", "USD", "GBP", "CHF", "CAD"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Header
            HStack {
                Image(systemName: "square.and.arrow.up.on.square")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export Excel/CSV")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Export data for accounting software compatibility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.bottom, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Export Format Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Export Format", systemImage: "doc.text")
                                .font(.headline)
                            
                            Picker("Format", selection: $selectedFormat) {
                                ForEach(ExcelExportService.ExportFormat.allCases, id: \.self) { format in
                                    HStack {
                                        Text(format.rawValue)
                                        Spacer()
                                        Text(".\(format.fileExtension)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .tag(format)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            // Format description
                            Text(getFormatDescription(selectedFormat))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                        }
                    }
                    
                    // Export Scope Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Export Scope", systemImage: "list.bullet")
                                .font(.headline)
                            
                            Picker("Scope", selection: $selectedScope) {
                                ForEach(ExcelExportService.ExportScope.allCases, id: \.self) { scope in
                                    Text(scope.localized).tag(scope)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    
                    // Date Range Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Date Range", systemImage: "calendar")
                                .font(.headline)
                            
                            Toggle("Use custom date range", isOn: $useCustomDateRange)
                            
                            if useCustomDateRange {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("From")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                            .labelsHidden()
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("To")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                            .labelsHidden()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Options Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Export Options", systemImage: "gear")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Include VAT/Tax", isOn: $includeVAT)
                                Toggle("Include draft documents", isOn: $includeDrafts)
                                
                                if selectedScope == .documents {
                                    Toggle("Group by client", isOn: $groupByClient)
                                }
                                
                                HStack {
                                    Text("Currency:")
                                    Picker("Currency", selection: $selectedCurrency) {
                                        ForEach(currencies, id: \.self) { currency in
                                            Text(currency).tag(currency)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .frame(width: 80)
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Export Statistics
                    if selectedScope == .documents {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Export Preview", systemImage: "chart.bar.doc.horizontal")
                                    .font(.headline)
                                
                                ExportStatsView(
                                    scope: selectedScope,
                                    includeDrafts: includeDrafts,
                                    dateRange: useCustomDateRange ? DateInterval(start: startDate, end: endDate) : nil
                                )
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Export Button
            HStack {
                Spacer()
                
                Button(action: performExport) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isExporting ? "Exporting..." : "Export Data")
                    }
                    .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
                
                Spacer()
            }
        }
        .padding()
        .alert("Export Result", isPresented: $showingExportResult) {
            if exportedFileURL != nil {
                Button("Show in Finder") {
                    if let url = exportedFileURL {
                        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                    }
                }
                Button("OK") { }
            } else {
                Button("OK") { }
            }
        } message: {
            if let error = exportError {
                Text("Export failed: \(error)")
            } else if let url = exportedFileURL {
                Text("Export successful!\n\(url.lastPathComponent)")
            }
        }
    }
    
    private func getFormatDescription(_ format: ExcelExportService.ExportFormat) -> String {
        switch format {
        case .sage:
            return "Tab-separated format compatible with Sage accounting software"
        case .ciel:
            return "CSV format compatible with Ciel Compta and similar software"
        case .ebp:
            return "CSV format compatible with EBP Compta"
        case .quadratus:
            return "QIF format compatible with Quadratus accounting software"
        case .generic:
            return "Standard CSV format compatible with Excel and most software"
        }
    }
    
    private func performExport() {
        isExporting = true
        exportError = nil
        exportedFileURL = nil
        
        let options = ExcelExportService.ExportOptions(
            format: selectedFormat,
            scope: selectedScope,
            dateRange: useCustomDateRange ? DateInterval(start: startDate, end: endDate) : nil,
            includeVAT: includeVAT,
            includeDrafts: includeDrafts,
            groupByClient: groupByClient,
            currency: selectedCurrency
        )
        
        // Validate options
        let validationErrors = exportService.validateExportOptions(options)
        if !validationErrors.isEmpty {
            exportError = validationErrors.joined(separator: ", ")
            isExporting = false
            showingExportResult = true
            return
        }
        
        Task {
            do {
                let fileURL = try exportService.exportData(options: options, context: viewContext)
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    isExporting = false
                    showingExportResult = true
                }
            } catch {
                await MainActor.run {
                    exportError = error.localizedDescription
                    isExporting = false
                    showingExportResult = true
                }
            }
        }
    }
}

// MARK: - Export Statistics View
struct ExportStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let scope: ExcelExportService.ExportScope
    let includeDrafts: Bool
    let dateRange: DateInterval?
    
    @State private var documentCount = 0
    @State private var totalAmount = 0.0
    @State private var currency = "EUR"
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Documents to export:")
                Spacer()
                Text("\(documentCount)")
                    .fontWeight(.semibold)
            }
            
            if scope == .documents && totalAmount > 0 {
                HStack {
                    Text("Total amount:")
                    Spacer()
                    Text("\(String(format: "%.2f", totalAmount)) \(currency)")
                        .fontWeight(.semibold)
                }
            }
            
            if let dateRange = dateRange {
                HStack {
                    Text("Period:")
                    Spacer()
                    Text("\(dateRange.start, formatter: dateFormatter) - \(dateRange.end, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            updateStats()
        }
        .onChange(of: includeDrafts) { _, _ in updateStats() }
        .onChange(of: dateRange) { _, _ in updateStats() }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    private func updateStats() {
        let request: NSFetchRequest<Document> = Document.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        if !includeDrafts {
            predicates.append(NSPredicate(format: "status != %@", "Draft"))
        }
        
        if let dateRange = dateRange {
            predicates.append(NSPredicate(format: "issueDate >= %@ AND issueDate <= %@", 
                                       dateRange.start as NSDate, dateRange.end as NSDate))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        do {
            let documents = try viewContext.fetch(request)
            documentCount = documents.count
            totalAmount = documents.reduce(0) { $0 + ($1.total?.doubleValue ?? 0.0) }
            currency = documents.first?.currencyCode ?? "EUR"
        } catch {
            documentCount = 0
            totalAmount = 0.0
        }
    }
}

#Preview {
    ExcelExportView()
        .frame(width: 600, height: 700)
}
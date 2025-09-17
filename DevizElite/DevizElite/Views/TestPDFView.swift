import SwiftUI

// MARK: - Test view to verify PDF generation
struct TestPDFView: View {
    let document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("TEST PDF GENERATION")
                .font(.title)
                .bold()
            
            Text("Company: \(document.safeOwnerField("companyName").isEmpty ? "Metta Concept" : document.safeOwnerField("companyName"))")
            Text("Document Number: \(document.number ?? "2024-001")")
            Text("Document Type: \(document.type?.lowercased() == "invoice" ? "FACTURE" : "DEVIS")")
            
            if let client = document.safeClient {
                VStack(alignment: .leading) {
                    Text("CLIENT:")
                        .font(.headline)
                    Text("Name: \(client.name ?? "N/A")")
                    Text("Address: \(client.address ?? "N/A")")
                    Text("City: \(client.city ?? "N/A")")
                }
            }
            
            if let lineItems = document.lineItems?.allObjects as? [LineItem] {
                VStack(alignment: .leading) {
                    Text("LINE ITEMS (\(lineItems.count)):")
                        .font(.headline)
                    
                    ForEach(Array(lineItems.enumerated()), id: \.element.id) { index, item in
                        if !item.isDeleted {
                            HStack {
                                Text("\(index + 1).")
                                Text(item.itemDescription ?? "No description")
                                Spacer()
                                Text("Qty: \(item.quantity?.doubleValue ?? 0, specifier: "%.1f")")
                                Text("Price: \(item.unitPrice?.doubleValue ?? 0, specifier: "%.2f")€")
                                Text("VAT: \(item.taxRate, specifier: "%.0f")%")
                            }
                        }
                    }
                }
            }
            
            Button("Generate Test PDF") {
                testPDFGeneration()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func testPDFGeneration() {
        print("=== TESTING PDF GENERATION ===")
        
        // Test data extraction
        print("Company Name: \(document.safeOwnerField("companyName"))")
        print("Document Number: \(document.number ?? "N/A")")
        print("Document Type: \(document.type ?? "N/A")")
        
        if let client = document.safeClient {
            print("Client Name: \(client.name ?? "N/A")")
            print("Client Address: \(client.address ?? "N/A")")
        } else {
            print("No client found")
        }
        
        if let lineItems = document.lineItems?.allObjects as? [LineItem] {
            print("Line Items Count: \(lineItems.count)")
            
            var totalHT: Double = 0
            var vatByRate: [Double: Double] = [:]
            
            for (index, item) in lineItems.enumerated() {
                if !item.isDeleted {
                    let quantity = item.quantity?.doubleValue ?? 0
                    let unitPrice = item.unitPrice?.doubleValue ?? 0
                    let vatRate = item.taxRate / 100.0
                    let lineTotal = quantity * unitPrice
                    
                    totalHT += lineTotal
                    vatByRate[vatRate, default: 0] += lineTotal * vatRate
                    
                    print("Item \(index + 1): \(item.itemDescription ?? "N/A") - Qty: \(quantity) - Price: \(unitPrice)€ - VAT: \(item.taxRate)% - Total: \(lineTotal)€")
                }
            }
            
            print("=== CALCULATIONS ===")
            print("Total HT: \(totalHT)€")
            
            for (rate, amount) in vatByRate.sorted(by: { $0.key < $1.key }) {
                print("VAT \(Int(rate * 100))%: \(amount)€")
            }
            
            let totalVAT = vatByRate.values.reduce(0, +)
            let totalTTC = totalHT + totalVAT
            print("Total VAT: \(totalVAT)€")
            print("Total TTC: \(totalTTC)€")
        } else {
            print("No line items found")
        }
        
        // Generate PDF
        let pdfData = FinalPDFGenerator.generatePDF(for: document)
        print("PDF Data Size: \(pdfData.count) bytes")
        
        if pdfData.count > 1000 {
            print("✅ PDF generated successfully - contains data")
        } else {
            print("❌ PDF generation failed - too small")
        }
        
        print("=== END TEST ===")
    }
}

// Preview for testing
struct TestPDFView_Previews: PreviewProvider {
    static var previews: some View {
        TestPDFView(document: Document())
    }
}
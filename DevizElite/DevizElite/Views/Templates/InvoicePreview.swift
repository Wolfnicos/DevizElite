//
//  InvoicePreview.swift
//  DevizElite
//
//  Created by App Gemini on 15/09/2025.
//

import SwiftUI
import CoreData

struct InvoicePreview: View {
    let template: String
    @ObservedObject var document: Document
    
    // Live data from editor
    let clientName: String
    let lineItems: [ConstructionLineItem]
    let subtotal: Double
    let totalTax: Double
    let totalAmount: Double
    
    var body: some View {
        Group {
            switch template {
            case "modern":
                ModernTemplate(
                    document: document,
                    clientName: clientName,
                    lineItems: lineItems,
                    subtotal: subtotal,
                    totalTax: totalTax,
                    totalAmount: totalAmount
                )
            case "classic":
                ClassicTemplate(
                    document: document,
                    clientName: clientName,
                    lineItems: lineItems,
                    subtotal: subtotal,
                    totalTax: totalTax,
                    totalAmount: totalAmount
                )
            default:
                Text("Template not found")
            }
        }
    }
}

// MARK: - Templates
private struct ModernTemplate: View {
    @ObservedObject var document: Document
    let clientName: String
    let lineItems: [ConstructionLineItem]
    let subtotal: Double
    let totalTax: Double
    let totalAmount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Modern Template Preview")
                .font(.largeTitle)
                .foregroundColor(DesignSystem.Colors.accent)
            
            HeaderSection(document: document, clientName: clientName)
            ItemsTable(lineItems: lineItems)
            TotalsFooter(subtotal: subtotal, totalTax: totalTax, totalAmount: totalAmount)
            
            Spacer()
        }
        .padding(40)
        .background(Color.white)
    }
}

private struct ClassicTemplate: View {
    @ObservedObject var document: Document
    let clientName: String
    let lineItems: [ConstructionLineItem]
    let subtotal: Double
    let totalTax: Double
    let totalAmount: Double

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("INVOICE")
                .font(.system(size: 40, weight: .bold, design: .serif))

            HeaderSection(document: document, clientName: clientName)
            ItemsTable(lineItems: lineItems)
            TotalsFooter(subtotal: subtotal, totalTax: totalTax, totalAmount: totalAmount)

            Spacer()
        }
        .padding(40)
        .background(Color.white)
    }
}


// MARK: - Template Components
private struct HeaderSection: View {
    @ObservedObject var document: Document
    let clientName: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Your Company LLC").font(.headline)
                Text("123 Main St, Anytown, USA")
            }
            Spacer()
            VStack(alignment: .leading) {
                Text("Bill To:").font(.caption).foregroundColor(.gray)
                Text(clientName).font(.headline)
            }
        }
    }
}

private struct ItemsTable: View {
    let lineItems: [ConstructionLineItem]

    var body: some View {
        VStack {
            HStack {
                Text("Description").bold()
                Spacer()
                Text("Quantity").bold()
                Text("Price").bold()
                Text("Total").bold()
            }
            Divider()
            ForEach(lineItems) { item in
                HStack {
                    Text(item.description)
                    Spacer()
                    Text("\(item.quantity, specifier: "%.2f")")
                    Text(formatCurrency(item.unitPrice))
                    Text(formatCurrency(item.total))
                }
            }
        }
    }
}

private struct TotalsFooter: View {
    let subtotal: Double
    let totalTax: Double
    let totalAmount: Double

    var body: some View {
        VStack(alignment: .trailing) {
            HStack { Text("Subtotal:"); Spacer(); Text(formatCurrency(subtotal)) }
            HStack { Text("VAT (19%):"); Spacer(); Text(formatCurrency(totalTax)) }
            HStack { Text("Total:").bold(); Spacer(); Text(formatCurrency(totalAmount)).bold() }
        }
    }
}

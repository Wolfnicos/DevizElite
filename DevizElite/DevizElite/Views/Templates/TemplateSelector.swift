import SwiftUI

// MARK: - Template Selector for Invoices/Estimates
struct TemplateSelector: View {
    @StateObject private var manager = TemplateManager.shared
    @Binding var isPresented: Bool
    let documentType: DocumentType
    let onTemplateSelected: (TemplateStyle) -> Void
    
    enum DocumentType {
        case invoice, estimate
        
        var displayName: String {
            switch self {
            case .invoice: return "Facture"
            case .estimate: return "Devis"
            }
        }
    }
    
    var filteredTemplates: [InvoiceTemplateModel] {
        manager.templates.filter { template in
            switch documentType {
            case .invoice:
                return template.kind == .invoice
            case .estimate:
                return template.kind == .quote
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Choisir un template \(documentType.displayName)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Annuler") {
                    isPresented = false
                }
                .buttonStyle(.borderless)
            }
            
            // Template Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(filteredTemplates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: manager.selectedTemplateId == template.id
                        ) {
                            // Select template and apply immediately
                            withAnimation(.easeInOut(duration: 0.3)) {
                                manager.selectedTemplateId = template.id
                                manager.applySelectedTemplateFor(documentType: documentType == .invoice ? "invoice" : "estimate")
                                
                                // Get the selected style and apply it
                                let selectedStyle = getTemplateStyle(for: template)
                                UserDefaults.standard.set(selectedStyle.rawValue, forKey: "templateStyle")
                                
                                // Call the completion handler
                                onTemplateSelected(selectedStyle)
                                
                                // Close the sheet
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isPresented = false
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func getTemplateStyle(for template: InvoiceTemplateModel) -> TemplateStyle {
        // Map template to style based on name patterns
        switch (template.kind, template.name) {
        case (.invoice, let name) where name.contains("BTP Modern") && name.contains("Facture FR"):
            return .ModernBTPInvoice
        case (.quote, let name) where name.contains("BTP Modern") && name.contains("Devis FR"):
            return .ModernBTPQuote
        case (.invoice, let name) where name.contains("BTP Modern") && name.contains("Factuur BE"):
            return .BEModernBTPInvoice
        case (.quote, let name) where name.contains("BTP Modern") && name.contains("Offerte BE"):
            return .BEModernBTPQuote
        case (.invoice, let name) where name.contains("Legacy"):
            return .FRModernInvoice
        case (.quote, let name) where name.contains("Legacy"):
            return .FRModernQuote
        default:
            return .Classic
        }
    }
}

// MARK: - Template Card
private struct TemplateCard: View {
    let template: InvoiceTemplateModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Preview Card
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(radius: isSelected ? 8 : 4)
                
                VStack(spacing: 4) {
                    // Header
                    Rectangle()
                        .fill(template.colorScheme.primary.opacity(0.8))
                        .frame(height: 25)
                    
                    // Content lines
                    VStack(spacing: 3) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    
                    // Footer
                    Rectangle()
                        .fill(template.colorScheme.secondary.opacity(0.3))
                        .frame(height: 15)
                }
            }
            .frame(width: 120, height: 160)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            
            // Template Name
            VStack(spacing: 4) {
                Text(template.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // BTP Badge for modern templates
                if template.name.contains("BTP Modern") {
                    HStack(spacing: 2) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 8))
                        Text("BTP")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(template.colorScheme.primary)
                    .cornerRadius(8)
                }
            }
        }
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Modern Template Selection Button
struct ModernTemplateButton: View {
    @State private var showTemplateSelector = false
    let documentType: TemplateSelector.DocumentType
    let onTemplateSelected: (TemplateStyle) -> Void
    
    var body: some View {
        Button {
            showTemplateSelector = true
        } label: {
            HStack {
                Image(systemName: "doc.badge.gearshape")
                Text("Choisir Template")
            }
        }
        .buttonStyle(.borderedProminent)
        .sheet(isPresented: $showTemplateSelector) {
            TemplateSelector(
                isPresented: $showTemplateSelector,
                documentType: documentType,
                onTemplateSelected: onTemplateSelected
            )
        }
    }
}
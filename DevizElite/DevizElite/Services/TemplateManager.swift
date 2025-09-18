import Foundation
import SwiftUI

enum TemplateKind: String { case invoice, quote }
enum TemplateLayout: String { case standard, modern, minimal }

struct TemplateColorScheme: Equatable { let primary: Color; let secondary: Color; let accent: Color }

struct InvoiceTemplateModel: Identifiable, Equatable {
    let id: UUID
    let name: String
    let kind: TemplateKind
    let layout: TemplateLayout
    let colorScheme: TemplateColorScheme
}

final class TemplateManager: ObservableObject {
    static let shared = TemplateManager()

    @Published var templates: [InvoiceTemplateModel] = []
    @Published var selectedTemplateId: UUID? {
        didSet { if let id = selectedTemplateId { UserDefaults.standard.set(id.uuidString, forKey: "selectedTemplateId") } }
    }

    private init() {
        loadDefaultTemplates()
        if let raw = UserDefaults.standard.string(forKey: "selectedTemplateId"), let id = UUID(uuidString: raw), templates.contains(where: { $0.id == id }) {
            selectedTemplateId = id
        } else {
            selectedTemplateId = templates.first?.id
        }
    }

    func loadDefaultTemplates() {
        templates = [
            // Modern BTP templates (NEW - Primary)
            InvoiceTemplateModel(id: UUID(), name: "🇫🇷 BTP Modern • Facture FR", kind: .invoice, layout: .modern, colorScheme: .init(primary: Color(red: 0.051, green: 0.278, blue: 0.631), secondary: .gray, accent: Color(red: 1.0, green: 0.341, blue: 0.133))),
            InvoiceTemplateModel(id: UUID(), name: "🇫🇷 BTP Modern • Devis FR", kind: .quote, layout: .modern, colorScheme: .init(primary: Color(red: 1.0, green: 0.396, blue: 0.0), secondary: Color(red: 0.051, green: 0.278, blue: 0.631), accent: .green)),
            InvoiceTemplateModel(id: UUID(), name: "🇧🇪 BTP Modern • Factuur BE", kind: .invoice, layout: .modern, colorScheme: .init(primary: Color(red: 0.8, green: 0.0, blue: 0.0), secondary: Color(red: 1.0, green: 0.84, blue: 0.0), accent: Color(red: 0.0, green: 0.6, blue: 0.0))),
            InvoiceTemplateModel(id: UUID(), name: "🇧🇪 BTP Modern • Offerte BE", kind: .quote, layout: .modern, colorScheme: .init(primary: Color(red: 0.0, green: 0.36, blue: 0.69), secondary: Color(red: 0.96, green: 0.73, blue: 0.15), accent: Color(red: 0.0, green: 0.6, blue: 0.0))),
            
            // Classic templates
            InvoiceTemplateModel(id: UUID(), name: "Facture Classique", kind: .invoice, layout: .standard, colorScheme: .init(primary: .blue, secondary: .gray, accent: .green)),
            InvoiceTemplateModel(id: UUID(), name: "Facture Minimale", kind: .invoice, layout: .minimal, colorScheme: .init(primary: .black, secondary: .gray, accent: .blue)),
            
            // Legacy templates (kept for compatibility)
            InvoiceTemplateModel(id: UUID(), name: "Construction (FR) - Legacy", kind: .invoice, layout: .modern, colorScheme: .init(primary: .indigo, secondary: .gray, accent: .pink)),
            InvoiceTemplateModel(id: UUID(), name: "Construction (BE) - Legacy", kind: .invoice, layout: .standard, colorScheme: .init(primary: .black, secondary: .gray, accent: .orange)),
            InvoiceTemplateModel(id: UUID(), name: "BTP 2025 - Legacy", kind: .invoice, layout: .modern, colorScheme: .init(primary: .blue, secondary: .gray, accent: .orange))
        ]
    }

    func applySelectedTemplateFor(documentType: String) {
        guard let t = templates.first(where: { $0.id == selectedTemplateId }) else { return }
        let style: TemplateStyle
        
        switch (t.kind, t.layout, t.name) {
        // New Modern BTP templates (PRIMARY)
        case (.invoice, .modern, let name) where name.contains("BTP Modern") && name.contains("Facture FR"):
            style = .ModernBTPInvoice
        case (.quote, .modern, let name) where name.contains("BTP Modern") && name.contains("Devis FR"):
            style = .ModernBTPQuote
        case (.invoice, .modern, let name) where name.contains("BTP Modern") && name.contains("Factuur BE"):
            style = .BEModernBTPInvoice
        case (.quote, .modern, let name) where name.contains("BTP Modern") && name.contains("Offerte BE"):
            style = .BEModernBTPQuote
            
        // Legacy template support
        case (.invoice, .modern, let name) where name.contains("Legacy"):
            style = .FRModernInvoice
        case (.invoice, .standard, let name) where name.contains("Legacy"):
            style = .BEProfessionalInvoice
            
        // BTP 2025 templates (legacy)
        case (.invoice, .modern, let name) where name.contains("BTP 2025"):
            style = .BTP2025Invoice
        case (.quote, .modern, let name) where name.contains("BTP 2025"):
            style = .BTP2025Quote
            
        // Fallback to basic templates
        default:
            switch t.layout {
            case .standard: style = .Classic
            case .modern: style = .Modern
            case .minimal: style = .Minimal
            }
        }
        UserDefaults.standard.set(style.rawValue, forKey: "templateStyle")
    }
}

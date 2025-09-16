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
            InvoiceTemplateModel(id: UUID(), name: "Facture Classique", kind: .invoice, layout: .standard, colorScheme: .init(primary: .blue, secondary: .gray, accent: .green)),
            InvoiceTemplateModel(id: UUID(), name: "Facture Moderne (FR)", kind: .invoice, layout: .modern, colorScheme: .init(primary: .indigo, secondary: .gray, accent: .pink)),
            InvoiceTemplateModel(id: UUID(), name: "Facture Professionnelle (BE)", kind: .invoice, layout: .standard, colorScheme: .init(primary: .black, secondary: .gray, accent: .orange)),
            InvoiceTemplateModel(id: UUID(), name: "Devis Moderne (FR)", kind: .quote, layout: .modern, colorScheme: .init(primary: .purple, secondary: .indigo, accent: .orange)),
            InvoiceTemplateModel(id: UUID(), name: "Devis Professionnel (BE)", kind: .quote, layout: .standard, colorScheme: .init(primary: .blue, secondary: .gray, accent: .green)),
            InvoiceTemplateModel(id: UUID(), name: "Facture Minimale", kind: .invoice, layout: .minimal, colorScheme: .init(primary: .black, secondary: .gray, accent: .blue)),
            // New BTP 2025 templates
            InvoiceTemplateModel(id: UUID(), name: "BTP 2025 • Facture FR", kind: .invoice, layout: .modern, colorScheme: .init(primary: .blue, secondary: .gray, accent: .orange)),
            InvoiceTemplateModel(id: UUID(), name: "BTP 2025 • Devis FR", kind: .quote, layout: .modern, colorScheme: .init(primary: .orange, secondary: .blue, accent: .green))
        ]
    }

    func applySelectedTemplateFor(documentType: String) {
        guard let t = templates.first(where: { $0.id == selectedTemplateId }) else { return }
        let style: TemplateStyle
        switch (t.kind, t.layout, t.name) {
        case (.invoice, .standard, let name) where name.contains("Professionnelle (BE)"): style = .BEProfessionalInvoice
        case (.invoice, .modern, let name) where name.contains("Moderne (FR)"): style = .FRModernInvoice
        case (.quote, .modern, let name) where name.contains("Moderne (FR)"): style = .FRModernQuote
        case (.quote, .standard, let name) where name.contains("Professionnel (BE)"): style = .BEProfessionalQuote
        case (.invoice, .modern, let name) where name.contains("BTP 2025") && name.contains("Facture"): style = .BTP2025Invoice
        case (.quote, .modern, let name) where name.contains("BTP 2025") && name.contains("Devis"): style = .BTP2025Quote
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

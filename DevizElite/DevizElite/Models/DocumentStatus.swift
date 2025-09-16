import Foundation

enum DocumentStatus: String, CaseIterable, Identifiable {
    case draft
    case sent
    case paid

    var id: String { rawValue }
}



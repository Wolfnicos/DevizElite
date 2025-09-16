import Foundation

struct Product: Identifiable, Codable, Equatable {
    let id: String
    let nameFR: String
    let nameEN: String
    let category: String
    let country: String // "FR" or "BE"
    let price: Double
    let unit: String
}

final class ProductCatalogService {
    static let shared = ProductCatalogService()

    func loadProducts() -> [Product] {
        guard let url = Bundle.main.url(forResource: "products_fr_be", withExtension: "json") else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Product].self, from: data)
        } catch {
            print("Products load error: \(error)")
            return []
        }
    }
}



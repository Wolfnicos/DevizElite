import Foundation

final class ExchangeRatesService {
    static let shared = ExchangeRatesService()
    private init() {}

    struct RatesResponse: Decodable { let rates: [String: Double] }

    func fetchRates(base: String = "USD") async throws -> [String: Double] {
        guard let appId = UserDefaults.standard.string(forKey: "OpenExchangeRatesAPIKey"), !appId.isEmpty else {
            return [:]
        }
        var components = URLComponents(string: "https://openexchangerates.org/api/latest.json")!
        components.queryItems = [URLQueryItem(name: "app_id", value: appId), URLQueryItem(name: "base", value: base)]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [:] }
        let decoded = try JSONDecoder().decode(RatesResponse.self, from: data)
        return decoded.rates
    }
}



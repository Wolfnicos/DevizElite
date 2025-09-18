import Foundation

enum L10n {
    static func t(_ key: String) -> String {
        LocalizationService.shared.localizedString(key)
    }
}

import SwiftUI

final class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @Published var languageCode: String
    @Published var reloadToken: UUID = UUID()

    private var tableName: String = "en"
    private var strings: [String: String] = [:]
    private var languageBundle: Bundle?

    private init() {
        let code: String
        if let arr = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String], let first = arr.first {
            code = first
        } else {
            code = Locale.current.language.languageCode?.identifier ?? "en"
        }
        languageCode = code
        tableName = mapLanguageToTable(code)
        updateLanguageBundle()
        loadTable()
    }

    func setLanguage(_ code: String) {
        guard code != languageCode else { return }
        languageCode = code
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        tableName = mapLanguageToTable(code)
        updateLanguageBundle()
        loadTable()
        reloadToken = UUID() // force UI refresh via .id()
    }

    func localizedString(_ key: String) -> String {
        if let bundle = languageBundle {
            let v = bundle.localizedString(forKey: key, value: nil, table: nil)
            if v != key { return v }
        }
        if let v = strings[key] { return v }
        // fallback to English table if missing
        if tableName != "en" {
            if let enBundlePath = Bundle.main.path(forResource: "en", ofType: "lproj"), let enBundle = Bundle(path: enBundlePath) {
                let ev = enBundle.localizedString(forKey: key, value: nil, table: nil)
                if ev != key { return ev }
            }
            if let en = loadTable(name: "en"), let v = en[key] { return v }
        }
        return key
    }

    private func loadTable() {
        if let dict = loadTable(name: tableName) { strings = dict } else { strings = [:] }
    }

    private func loadTable(name: String) -> [String: String]? {
        if let url = Bundle.main.url(forResource: name, withExtension: "strings"),
           let dict = NSDictionary(contentsOf: url) as? [String: String] {
            return dict
        }
        return nil
    }

    private func mapLanguageToTable(_ code: String) -> String {
        if code.hasPrefix("ro") { return "ro" }
        if code.hasPrefix("fr") { return "fr" }
        if code.hasPrefix("es") { return "es" }
        if code.hasPrefix("de") { return "de" }
        if code.hasPrefix("nl") { return "nl" }
        return "en"
    }

    private func updateLanguageBundle() {
        let lang = mapLanguageToTable(languageCode)
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"), let b = Bundle(path: path) {
            languageBundle = b
        } else {
            languageBundle = nil
        }
    }
}


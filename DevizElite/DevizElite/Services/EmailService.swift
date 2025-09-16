import Foundation
import AppKit

final class EmailService {
    static let shared = EmailService()

    func composeEmail(to recipient: String, subject: String, body: String, attachmentName: String?, attachmentData: Data?) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        let items: [URLQueryItem] = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        components.queryItems = items
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
        // For attachment, fall back to saving temp file and instructing user
        if let data = attachmentData, let name = attachmentName {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try? data.write(to: tempURL)
        }
    }
}



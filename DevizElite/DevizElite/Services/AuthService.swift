import Foundation
import Combine
import Security
import CoreData

protocol AuthServicing {
    func signIn(email: String, password: String) -> AnyPublisher<User, Error>
    func register(email: String, password: String, displayName: String?) -> AnyPublisher<User, Error>
    func signOut()
    func currentUser(in context: NSManagedObjectContext) -> User?
}

protocol KeychainServicing {
    func savePassword(_ password: String, account: String) throws
    func readPassword(account: String) throws -> String
}

final class AuthService: AuthServicing {
    static let shared = AuthService()
    private let keychain: KeychainServicing
    private let context: NSManagedObjectContext

    init(keychainService: KeychainServicing = KeychainService(service: "InvoiceMasterPro"), context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.keychain = keychainService
        self.context = context
    }

    func signIn(email: String, password: String) -> AnyPublisher<User, Error> {
        Future { promise in
            do {
                let stored = try self.keychain.readPassword(account: email)
                guard stored == password else { throw AuthError.invalidCredentials }
            } catch {
                return promise(.failure(error))
            }
            self.context.perform {
                do {
                    let request = NSFetchRequest<User>(entityName: "User")
                    request.predicate = NSPredicate(format: "email == %@", email)
                    let users = try self.context.fetch(request)
                    if let user = users.first {
                        promise(.success(user))
                    } else {
                        let user = User(context: self.context)
                        user.id = UUID()
                        user.email = email
                        user.displayName = nil
                        try self.context.save()
                        promise(.success(user))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }

    func register(email: String, password: String, displayName: String?) -> AnyPublisher<User, Error> {
        Future { promise in
            do { try self.keychain.savePassword(password, account: email) } catch { return promise(.failure(error)) }
            self.context.perform {
                do {
                    let user = User(context: self.context)
                    user.id = UUID()
                    user.email = email
                    user.displayName = displayName
                    try self.context.save()
                    promise(.success(user))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }

    func signOut() {
        // No-op for local keychain auth
    }

    func currentUser(in context: NSManagedObjectContext) -> User? {
        let request = NSFetchRequest<User>(entityName: "User")
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

enum AuthError: Error {
    case invalidCredentials
}

final class KeychainService: KeychainServicing {
    private let service: String

    init(service: String) {
        self.service = service
    }

    func savePassword(_ password: String, account: String) throws {
        let data = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    func readPassword(account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let password = String(data: data, encoding: .utf8) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        return password
    }
}


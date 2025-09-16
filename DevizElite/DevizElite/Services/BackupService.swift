import Foundation
import CoreData

final class BackupService {
    static let shared = BackupService()

    func exportBackup(to url: URL, context: NSManagedObjectContext) throws {
        let coordinator = context.persistentStoreCoordinator
        guard let store = coordinator?.persistentStores.first,
              let storeURL = coordinator?.url(for: store) else { throw NSError(domain: "Backup", code: -1) }
        try FileManager.default.copyItem(at: storeURL, to: url)
    }

    func importBackup(from url: URL, into context: NSManagedObjectContext) throws {
        let coordinator = context.persistentStoreCoordinator
        guard let store = coordinator?.persistentStores.first,
              let storeURL = coordinator?.url(for: store) else { throw NSError(domain: "Backup", code: -1) }
        try coordinator?.remove(store)
        try FileManager.default.removeItem(at: storeURL)
        try FileManager.default.copyItem(at: url, to: storeURL)
        try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
    }
}



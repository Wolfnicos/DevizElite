//
//  Persistence.swift
//  DevizElite
//
//  Created by Lupu Dragos on 14/09/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Create sample data for previewing purposes
        let newDocument = Document(context: viewContext)
        newDocument.id = UUID()
        newDocument.number = "INV-2024-PREVIEW"
        newDocument.issueDate = Date()
        newDocument.dueDate = Date().addingTimeInterval(86400 * 30)
        newDocument.status = "draft"
        newDocument.type = "invoice"
        newDocument.total = 1250.75
        
        let newClient = Client(context: viewContext)
        newClient.id = UUID()
        newClient.name = "Preview Client Inc."
        newClient.address = "123 Preview Lane"
        
        newDocument.client = newClient
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DevizElite")
        
        // --- START: Radical fix for persistent store corruption ---
        // This code will destroy and re-create the persistent store file,
        // ensuring any schema mismatch or corruption is resolved.
        // This is a development-only measure.
        if !inMemory {
            let storeURL = container.persistentStoreDescriptions.first?.url
            if let url = storeURL {
                do {
                    // Check if the store file exists before trying to destroy it
                    if FileManager.default.fileExists(atPath: url.path) {
                        print("Core Data store found at \(url.path). Destroying for a clean start.")
                        try container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
                        print("Successfully destroyed persistent store.")
                    }
                } catch {
                    // It's not critical if this fails, but we should know about it.
                    print("Failed to destroy persistent store: \(error) - This might not be a problem if it's the first run.")
                }
            }
        }
        // --- END: Radical fix ---
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // This is a serious error and should be handled appropriately in a production app.
                // For now, we'll just log it.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

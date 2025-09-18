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
        
        // PERSISTENT DATA STORAGE - DATA WILL BE PRESERVED
        // Removed the automatic store destruction that was clearing data on every restart
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // This is a serious error and should be handled appropriately in a production app.
                // For now, we'll just log it.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("✅ Core Data store loaded successfully at: \(storeDescription.url?.path ?? "unknown")")
        })
        
        // CONFIGURE CORE DATA FOR PERSISTENT STORAGE
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        // ENABLE AUTOSAVE EVERY 10 SECONDS
        let viewContext = container.viewContext
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            if viewContext.hasChanges {
                do {
                    try viewContext.save()
                    print("🔄 Auto-saved Core Data changes")
                } catch {
                    print("❌ Auto-save failed: \(error)")
                }
            }
        }
    }
}

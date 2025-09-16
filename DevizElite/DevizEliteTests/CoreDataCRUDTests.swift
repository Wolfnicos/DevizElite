import XCTest
import CoreData
@testable import DevizElite

final class CoreDataCRUDTests: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUp() async throws {
        context = PersistenceController(inMemory: true).container.viewContext
    }

    func testCreateClientAndDocument() throws {
        let client = Client(context: context)
        client.id = UUID()
        client.name = "Acme"

        let doc = Document(context: context)
        doc.id = UUID()
        doc.type = "invoice"
        doc.number = "INV-1"
        doc.issueDate = Date()
        doc.client = client

        try context.save()

        let fetch = NSFetchRequest<Document>(entityName: "Document")
        fetch.fetchLimit = 1
        let results = try context.fetch(fetch)
        let fetched = results.first
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.client?.name, "Acme")
    }
}


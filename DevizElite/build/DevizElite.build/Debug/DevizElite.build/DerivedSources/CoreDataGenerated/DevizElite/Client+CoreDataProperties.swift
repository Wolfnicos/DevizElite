//
//  Client+CoreDataProperties.swift
//  
//
//  Created by Lupu Dragos on 17/09/2025.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Client {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Client> {
        return NSFetchRequest<Client>(entityName: "Client")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var contactEmail: String?
    @NSManaged public var phone: String?
    @NSManaged public var address: String?
    @NSManaged public var city: String?
    @NSManaged public var country: String?
    @NSManaged public var taxId: String?
    @NSManaged public var notes: String?
    @NSManaged public var documents: NSSet?

}

// MARK: Generated accessors for documents
extension Client {

    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: Document)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: Document)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)

}

extension Client : Identifiable {

}

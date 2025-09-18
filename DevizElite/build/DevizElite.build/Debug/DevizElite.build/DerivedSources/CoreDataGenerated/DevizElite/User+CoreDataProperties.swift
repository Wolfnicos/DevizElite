//
//  User+CoreDataProperties.swift
//  
//
//  Created by Lupu Dragos on 17/09/2025.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var email: String?
    @NSManaged public var displayName: String?
    @NSManaged public var locale: String?
    @NSManaged public var currencyCode: String?
    @NSManaged public var companyName: String?
    @NSManaged public var companyAddress: String?
    @NSManaged public var taxId: String?
    @NSManaged public var iban: String?
    @NSManaged public var bankName: String?
    @NSManaged public var logoData: Data?
    @NSManaged public var documents: NSSet?

}

// MARK: Generated accessors for documents
extension User {

    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: Document)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: Document)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)

}

extension User : Identifiable {

}

//
//  Document+CoreDataProperties.swift
//  
//
//  Created by Lupu Dragos on 17/09/2025.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Document {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Document> {
        return NSFetchRequest<Document>(entityName: "Document")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var number: String?
    @NSManaged public var issueDate: Date?
    @NSManaged public var dueDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var type: String?
    @NSManaged public var currencyCode: String?
    @NSManaged public var discount: NSDecimalNumber?
    @NSManaged public var subtotal: NSDecimalNumber?
    @NSManaged public var taxTotal: NSDecimalNumber?
    @NSManaged public var total: NSDecimalNumber?
    @NSManaged public var language: String?
    @NSManaged public var notes: String?
    @NSManaged public var projectName: String?
    @NSManaged public var siteAddress: String?
    @NSManaged public var paymentTerms: String?
    @NSManaged public var validityDays: Int16
    @NSManaged public var retentionPercent: Double
    @NSManaged public var client: Client?
    @NSManaged public var owner: User?
    @NSManaged public var lineItems: NSSet?

}

// MARK: Generated accessors for lineItems
extension Document {

    @objc(addLineItemsObject:)
    @NSManaged public func addToLineItems(_ value: LineItem)

    @objc(removeLineItemsObject:)
    @NSManaged public func removeFromLineItems(_ value: LineItem)

    @objc(addLineItems:)
    @NSManaged public func addToLineItems(_ values: NSSet)

    @objc(removeLineItems:)
    @NSManaged public func removeFromLineItems(_ values: NSSet)

}

extension Document : Identifiable {

}

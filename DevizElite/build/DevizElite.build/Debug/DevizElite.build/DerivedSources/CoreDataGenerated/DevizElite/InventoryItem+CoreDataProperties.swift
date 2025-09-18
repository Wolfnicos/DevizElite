//
//  InventoryItem+CoreDataProperties.swift
//  
//
//  Created by Lupu Dragos on 17/09/2025.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension InventoryItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InventoryItem> {
        return NSFetchRequest<InventoryItem>(entityName: "InventoryItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var sku: String?
    @NSManaged public var unit: String?
    @NSManaged public var unitPrice: NSDecimalNumber?
    @NSManaged public var taxRate: Double
    @NSManaged public var notes: String?
    @NSManaged public var lineItems: NSSet?

}

// MARK: Generated accessors for lineItems
extension InventoryItem {

    @objc(addLineItemsObject:)
    @NSManaged public func addToLineItems(_ value: LineItem)

    @objc(removeLineItemsObject:)
    @NSManaged public func removeFromLineItems(_ value: LineItem)

    @objc(addLineItems:)
    @NSManaged public func addToLineItems(_ values: NSSet)

    @objc(removeLineItems:)
    @NSManaged public func removeFromLineItems(_ values: NSSet)

}

extension InventoryItem : Identifiable {

}

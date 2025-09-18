//
//  LineItem+CoreDataProperties.swift
//  
//
//  Created by Lupu Dragos on 17/09/2025.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension LineItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LineItem> {
        return NSFetchRequest<LineItem>(entityName: "LineItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var itemDescription: String?
    @NSManaged public var quantity: NSDecimalNumber?
    @NSManaged public var unit: String?
    @NSManaged public var unitPrice: NSDecimalNumber?
    @NSManaged public var taxRate: Double
    @NSManaged public var discount: Double
    @NSManaged public var position: Int16
    @NSManaged public var document: Document?
    @NSManaged public var inventoryItem: InventoryItem?

}

extension LineItem : Identifiable {

}

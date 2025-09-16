//
//  ConstructionLineItem.swift
//  DevizElite
//
//  Created by App Gemini on 15/09/2025.
//

import Foundation

struct ConstructionLineItem: Identifiable, Equatable {
    var id = UUID()
    var description: String = ""
    var quantity: Double = 1
    var unit: String = "buc"
    var unitPrice: Double = 0
    var taxRate: Double = 20.0 // Default VAT (FR baseline)
    var discount: Double = 0
    
    var total: Double {
        (quantity * unitPrice) * (1 - discount / 100.0)
    }
    var taxAmount: Double {
        total * (taxRate / 100.0)
    }
}

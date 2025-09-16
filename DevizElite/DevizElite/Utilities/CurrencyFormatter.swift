//
//  CurrencyFormatter.swift
//  DevizElite
//
//  Created by App Gemini on 15/09/2025.
//

import Foundation

func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "EUR"
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: amount)) ?? "€0.00"
}

import Foundation
import CoreData
import Combine

final class DocumentEditorViewModel: ObservableObject {
    @Published var document: Document
    @Published private(set) var lineItems: [LineItem] = []
    @Published private(set) var subtotal: NSDecimalNumber = 0
    @Published private(set) var taxTotal: NSDecimalNumber = 0
    @Published private(set) var total: NSDecimalNumber = 0
    @Published private(set) var validationErrors: [String] = []

    private let context: NSManagedObjectContext
    private var cancellables: Set<AnyCancellable> = []
    private var isRecalculating: Bool = false

    init(document: Document, context: NSManagedObjectContext) {
        self.document = document
        self.context = context
        reloadLineItems()
        recalculateTotals()

        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.reloadLineItems()
                // Recompute UI totals only; avoid mutating the managed object here to prevent loops
                self.recalculateTotals(save: false)
            }
            .store(in: &cancellables)
    }

    func reloadLineItems() {
        let items = (document.lineItems as? Set<LineItem>) ?? []
        lineItems = items.sorted { ($0.position) < ($1.position) }
    }

    func addLineItem(from inventoryItem: InventoryItem? = nil) {
        let item = LineItem(context: context)
        item.id = UUID()
        item.position = Int16(lineItems.count)
        item.itemDescription = inventoryItem?.name ?? "New line"
        item.quantity = 1
        item.unitPrice = inventoryItem?.unitPrice ?? 0
        item.taxRate = inventoryItem?.taxRate ?? 0
        // Attach line item to document to ensure persistence
        item.document = document
        lineItems.append(item)
        recalculateTotals(save: true)
    }

    func addLineItem(description: String, quantity: Double, unitPrice: Double, taxRatePercent: Double) {
        let item = LineItem(context: context)
        item.id = UUID()
        item.position = Int16(lineItems.count)
        item.itemDescription = description
        item.quantity = NSDecimalNumber(value: quantity)
        item.unitPrice = NSDecimalNumber(value: unitPrice)
        item.taxRate = taxRatePercent
        // Attach line item to document to ensure persistence
        item.document = document
        lineItems.append(item)
        recalculateTotals(save: true)
    }

    func addLineItemPersistent(description: String, quantity: Double, unitPrice: Double, taxRatePercent: Double) {
        context.perform {
            let item = LineItem(context: self.context)
            item.id = UUID()
            let currentCount = ((self.document.lineItems as? Set<LineItem>)?.count ?? 0)
            item.position = Int16(currentCount)
            item.itemDescription = description
            item.quantity = NSDecimalNumber(value: quantity)
            item.unitPrice = NSDecimalNumber(value: unitPrice)
            item.taxRate = taxRatePercent
            item.document = self.document
            self.save { [weak self] in
                guard let self = self else { return }
                self.reloadLineItems()
                self.recalculateTotals(save: true)
            }
        }
    }

    func removeLineItems(at offsets: IndexSet) {
        for idx in offsets { context.delete(lineItems[idx]) }
        reindexPositions()
        save()
        reloadLineItems()
        recalculateTotals(save: true)
    }

    func moveLineItems(from source: IndexSet, to destination: Int) {
        var items = lineItems
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.position = Int16(index)
        }
        // Also reflect the new order in the managed relationship to ensure persistence
        document.removeFromLineItems(document.lineItems ?? NSSet())
        for it in items { document.addToLineItems(it) }
        save()
        reloadLineItems()
        recalculateTotals(save: true)
    }

    func duplicateLineItem(at index: Int) {
        guard lineItems.indices.contains(index) else { return }
        let original = lineItems[index]
        let copy = LineItem(context: context)
        copy.id = UUID()
        copy.position = Int16(index + 1)
        copy.itemDescription = original.itemDescription
        copy.quantity = original.quantity
        copy.unitPrice = original.unitPrice
        copy.taxRate = original.taxRate
        copy.inventoryItem = original.inventoryItem
        copy.document = document
        // shift positions for subsequent items
        for i in (index + 1)..<lineItems.count { lineItems[i].position = Int16(i + 1) }
        save()
        reloadLineItems()
        recalculateTotals(save: true)
    }

    func moveLineItemUp(at index: Int) {
        guard index > 0 && lineItems.indices.contains(index) else { return }
        moveLineItems(from: IndexSet(integer: index), to: index - 1)
    }

    func moveLineItemDown(at index: Int) {
        guard index < lineItems.count - 1 && lineItems.indices.contains(index) else { return }
        moveLineItems(from: IndexSet(integer: index), to: index + 2)
    }

    func recalculateTotals(save: Bool = false) {
        if isRecalculating { return }
        isRecalculating = true

        let discount = document.discount ?? 0
        var subtotalHT: NSDecimalNumber = 0
        
        // First calculate subtotal HT
        lineItems.forEach { li in
            let qty = (li.quantity as NSDecimalNumber?) ?? 0
            let unit = li.unitPrice ?? 0
            let line = qty.multiplying(by: unit)
            subtotalHT = subtotalHT.adding(line)
        }
        
        // Apply discount to subtotal
        let subAfterDiscount = max(0, subtotalHT.subtracting(discount).decimalValue).nsDecimalNumber
        subtotal = subAfterDiscount
        
        // Calculate VAT on the discounted amount
        var totalTax: NSDecimalNumber = 0
        let discountRatio = subtotal.doubleValue > 0 ? subtotal.dividing(by: subtotalHT) : NSDecimalNumber.one
        
        lineItems.forEach { li in
            let qty = (li.quantity as NSDecimalNumber?) ?? 0
            let unit = li.unitPrice ?? 0
            let lineHT = qty.multiplying(by: unit)
            // Apply same discount ratio to this line
            let lineHTDiscounted = lineHT.multiplying(by: discountRatio)
            let rate = NSDecimalNumber(value: li.taxRate)
            let lineTax = lineHTDiscounted.multiplying(by: rate).dividing(by: 100)
            totalTax = totalTax.adding(lineTax)
        }
        
        taxTotal = totalTax
        total = subtotal.adding(taxTotal)
        validationErrors = computeValidationErrors()

        if save {
            document.subtotal = subtotal
            document.taxTotal = taxTotal
            document.total = total
            self.save()
        }

        isRecalculating = false
    }

    func save(completion: (() -> Void)? = nil) {
        context.perform {
            do {
                if self.context.hasChanges {
                    try self.context.save()
                }
            } catch {
                NSLog("Save error: \(error)")
            }
            if let completion = completion {
                DispatchQueue.main.async { completion() }
            }
        }
    }

    func saveAction() {
        save()
    }

    func bindAutosave() {
        // naive autosave for drafts
        if document.status == "draft" {
            recalculateTotals(save: true)
        }
    }

    private func reindexPositions() {
        for (index, item) in lineItems.enumerated() { item.position = Int16(index) }
    }

    private func computeValidationErrors() -> [String] {
        var errs: [String] = []
        if (document.number ?? "").trimmingCharacters(in: .whitespaces).isEmpty { errs.append("Number is required") }
        if (document.currencyCode ?? "").trimmingCharacters(in: .whitespaces).isEmpty { errs.append("Currency is required") }
        for li in lineItems {
            if (li.itemDescription ?? "").trimmingCharacters(in: .whitespaces).isEmpty { errs.append("Description is required") ; break }
        }
        return errs
    }
}

extension Decimal {
    var nsDecimalNumber: NSDecimalNumber { NSDecimalNumber(decimal: self) }
}

extension NSDecimalNumber {
    static func +(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber { lhs.adding(rhs) }
    static func -(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber { lhs.subtracting(rhs) }
    static func *(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber { lhs.multiplying(by: rhs) }
}



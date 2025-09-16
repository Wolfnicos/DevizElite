import Foundation
import CoreData

extension Document {
    /**
     Provides a type-safe accessor for the `client` relationship.
     
     This computed property acts as a safeguard against a persistent Core Data issue
     where the `client` to-one relationship is occasionally returned as an `_NSFaultingMutableSet`,
     causing a crash when properties like `.name` are accessed.
     
     This guard checks if the underlying object is actually a `Client` before returning it,
     ensuring the app's stability even if the Core Data context is in an inconsistent state.
     */
    var safeClient: Client? {
        // Defensively check if the client relationship holds a valid Client object.
        if let actualClient = self.client, actualClient.isKind(of: Client.self), !actualClient.isFault {
            return actualClient
        }
        
        // If it's a set or something else, return nil to prevent a crash.
        return nil
    }
}

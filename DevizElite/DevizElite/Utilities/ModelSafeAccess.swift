import Foundation
import CoreData

extension Document {
    var safeClientObject: Client? {
        let primitive = self.primitiveValue(forKey: "client")
        if let obj = primitive as? Client { return obj }
        if let set = primitive as? NSSet { return set.anyObject() as? Client }
        return nil
    }

    var safeClientName: String {
        let primitive = self.primitiveValue(forKey: "client")
        if let obj = primitive as? NSManagedObject {
            return obj.value(forKey: "name") as? String ?? ""
        }
        if let set = primitive as? NSSet, let any = set.anyObject() as? NSManagedObject {
            return any.value(forKey: "name") as? String ?? ""
        }
        return ""
    }

    var safeOwnerObject: User? {
        let primitive = self.primitiveValue(forKey: "owner")
        if let obj = primitive as? User { return obj }
        if let set = primitive as? NSSet { return set.anyObject() as? User }
        return nil
    }

    func safeOwnerField(_ key: String) -> String {
        let primitive = self.primitiveValue(forKey: "owner")
        if let obj = primitive as? NSManagedObject {
            return obj.value(forKey: key) as? String ?? ""
        }
        if let set = primitive as? NSSet, let any = set.anyObject() as? NSManagedObject {
            return any.value(forKey: key) as? String ?? ""
        }
        return ""
    }
}

// add copyright
import Foundation
import RealmSwift

class DemoObject: Object {
    @objc dynamic var uuid = UUID().uuidString
    @objc dynamic var date = NSDate()
    @objc dynamic var title = ""
}

/*
 For a more detailed example of SwiftUI List updating, see the ListSwiftUI example target.
 */
final class DemoObjects: Object {
    @objc var id = 0
    let list = RealmSwift.List<DemoObject>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

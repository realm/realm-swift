// add copyright
import Foundation
import RealmSwift

class DemoObject: Object {
    @objc dynamic var uuid = UUID().uuidString
    @objc dynamic var date = NSDate()
    @objc dynamic var title = ""
}

final class DemoObjects: Object {
    @objc var id = 0
    let list = RealmSwift.List<DemoObject>()
    
    override class func primaryKey() -> String? {
        "id"
    }
}

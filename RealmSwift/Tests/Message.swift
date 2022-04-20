import Foundation

extension Message {

    static var count: Int {
        try! Realm.defaultRealm.objects(Message.self).count
    }

    static func saveToRealm(messages: [Message]) {
        let realm = try! Realm.defaultRealm
        try? realm.write {
            realm.add(messages, update: .modified)
        }
    }

    static func saveToRealm(message: Message) {
        let realm = try! Realm.defaultRealm
        try? realm.write {
            realm.add(message, update: .modified)
        }
    }

    static func anyMessage(realm: Realm = try! Realm.defaultRealm) throws -> Message {
        let messages = try realm.objects(Message.self)
        let index = Int.random(in: 0..<Message.count)
        return messages[index]
    }

}

class Message: Object, Identifiable {

    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Message {
            return other.uid == uid
        }
        return false
    }

    var id: String { uid }
    @Persisted(primaryKey: true) var uid: String

    @Persisted var contentTxt: String
    @Persisted var color: String? = nil
    @Persisted var createdAt: Date
//    @Persisted(originProperty: "parentMessage") var parentOf: LinkingObjects<MessageModel>


    @Persisted var childMessages: List<Message>
    @Persisted(originProperty: "childMessages") var childOf: LinkingObjects<Message>

    var replyCount: Int {
        childMessages.count
    }


//    var descendantCount: Int {
//        if parentOf.count == 0 {
//            return 0
//        } else {
//            var inc = 0
//            parentOf.forEach { inc = inc + $0.descendantCount }
//            return inc
//        }
//    }

    override init() {
        super.init()
    }


    init(uid: String, contentTxt: String, color: String, createdAt: Date, parentMessageID: String?) {

        super.init()

        self.uid = uid
        self.contentTxt = contentTxt
        self.color = color
        self.createdAt = createdAt

    }


}


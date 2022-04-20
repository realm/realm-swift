import Foundation
import Realm

class BusyTown {

    var busyCount = 0;

    static var chance: Int {
        Int.random(in: 1..<100)
    }

    func getBusyAsync() async throws {
        busyCount += 1
        await delay(seconds: Double.random(in: 0.0..<1.0))
        let message = try await loadMessagesAsync().take()
        if message.realm == nil {
            Message.saveToRealm(message: message)
        }
//        let toUpdate = try await loadSeveral().take()
        if let realm = message.realm {
            try realm.inTransactionDo {
                message.contentTxt = "updated: \(Date().timeIntervalSince1970)"
                let newChild = try! unsavedChildMessage(parentId: message.uid)
                message.childMessages.append(newChild)
                realm.add(message, update: .modified)
            }
        }
        let ownableResults = try await loadSeveral()
        let results = try ownableResults.take()
        print("Got results: \(results)")
        results.forEach {
            print("Message: \($0)")
        }
    }


    func delay(seconds: TimeInterval) async {
        Thread.sleep(forTimeInterval: seconds)
    }

    func loadMessagesAsync() async throws -> Ownable<Message> {
        print("$$$ IN THREAD")
        Thread.sleep(forTimeInterval: 0.348)
        let createNew = Message.count == 0 || BusyTown.chance <= 50
        print("Create new? \(createNew)")
        if createNew {
            let parent = try unsavedChildMessage(parentId: nil)
            let newChild = try unsavedChildMessage(parentId: parent.uid)
            parent.childMessages.append(newChild)
            return Ownable(item: parent)
        } else {
            let parent = try Message.anyMessage()
            return Ownable(item: parent)
        }
    }

    func loadSeveral() async throws -> OwnableResults<Message> {
        let messages = try Realm.defaultRealm.objects(Message.self)
            .filter("color = %@", "Orange")
        return OwnableResults(messages)
    }

    func unsavedChildMessage(parentId: String?) throws -> Message {
        let uuid = UUID().uuidString
        let contentTxt = "message: \(Date().timeIntervalSinceNow)"
        let color = randomColor()
        return Message(uid: uuid, contentTxt: contentTxt, color: color, createdAt: Date(),
            parentMessageID: parentId)
    }

    func randomColor() -> String {
        switch Int.random(in: 0...2) {
        case 0: return "Orange"
        case 1: return "Green"
        default: return "Blue"
        }
    }

}


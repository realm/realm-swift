import Foundation
import RealmSwift

@available(macOS 9999, *)
extension Results {
    func write(_ block: (Element) async throws -> Void) async throws -> Self {
        try await AsyncRealm().write {
            for obj in self {
                try await block(obj)
            }
        }
        return self
    }
}



@available(macOS 9999, *)
@objcMembers class Vegetable: Object {
    dynamic var _id = ObjectId.generate()
    dynamic var chopped = false

    override class func primaryKey() -> String? {
        "_id"
    }

    class func chop(@RealmSendable vegetable: Vegetable) async throws {
        print("Task \(Task.current!.hashValue): Vegetable \(vegetable._id) starts chop")
        vegetable.chopped = true
        Thread.sleep(forTimeInterval: 2)
        print("Vegetable \(vegetable._id) ends chop")
        return
    }
}

@available(macOS 9999, *)
@objcMembers class Meat: Object {
    dynamic var _id = ObjectId.generate()
    dynamic var marinated = false

    class func marinateMeat(@RealmSendable meat: Meat) async throws {
        print("Task \(Task.current!.hashValue): Marinate meat \(meat._id) starts")
        meat.marinated = true
        Thread.sleep(forTimeInterval: 2)
        print("Task \(Task.current!.hashValue): Marinate meat \(meat._id) ends")
    }
}

@available(macOS 9999, *)
@objcMembers class Dish: Object {
    dynamic var meat: Meat?
    dynamic var veggies = List<Vegetable>()
    dynamic var cooked = false

    convenience init(meat: Meat, veggies: [Vegetable]) {
        self.init()
        self.meat = meat
        self.veggies.append(objectsIn: veggies)
    }
}

@available(macOS 9999, *)
@objcMembers class Oven: Object {
    dynamic var _id = ObjectId.generate()
    dynamic var preheated = false
    dynamic var isCooking = false

    override class func primaryKey() -> String? {
        "_id"
    }

    class func preheat(@RealmSendable oven: Oven) async throws {
        print("Task \(Task.current!.hashValue): Oven \(oven._id) preheat starts")
        oven.preheated = true
        Thread.sleep(forTimeInterval: 2)
        print("Oven \(oven._id) preheat ends")
    }

    func cook(@RealmSendable dish: Dish) async throws {
        isCooking = true
        print("Task \(Task.current!.hashValue): Oven \(_id) cook starts")
        dish.cooked = true
        Thread.sleep(forTimeInterval: 2)
        print("Task \(Task.current!.hashValue): Oven \(_id) cook ends")
        isCooking = false
    }
}

if #available(macOS 9999, *) {

@Sendable func gatherRawVeggies() async throws -> [Vegetable] {
    let realm = AsyncRealm()
    let onion = Vegetable()
    let shallot = Vegetable()
    try await realm.write {
        realm.add(onion)
        realm.add(shallot)
    }
    return [onion, shallot]
}

@Sendable func chopVegetables(_ vegetables: [Vegetable]) async throws {
    for veggie in try await gatherRawVeggies() {
        try await Vegetable.chop(vegetable: veggie)
    }
}

@Sendable func makeDinner() async throws -> Dish {
    let realm = try Realm()

    let oven = Oven()
    let meat = Meat()

    // async write and await
    try await realm.asyncWrite {
        realm.add(meat)
        realm.add(oven)
    }

    let veggies = try await gatherRawVeggies()

    try await Meat.marinateMeat(meat: meat)
    try await Oven.preheat(oven: oven)

    try await chopVegetables(veggies)

    let dish = Dish(meat: meat, veggies: veggies)

    try realm.write {
        realm.add(dish)
    }

    try await oven.cook(dish: dish)
    // async write and forget
    detachWrite(to: oven) { oven in
        oven.preheated = false
    }
    return dish
}

@Sendable
func main() async throws {
    let dishes = try await withThrowingTaskGroup(of: Dish.self) { group -> [Dish] in
        var dishes: [Dish] = []

        // cook two dinners in parallel
        group.spawn {
            try await makeDinner()
        }
        group.spawn {
            try await makeDinner()
        }
        // collect the dinners when complete
        for try await dish in group { // (2)
            dishes.append(dish)
        }

        return dishes
    }

    print("Bon Appetit!: \(dishes)")
}

    let group = DispatchGroup()

    //if #available(macOS 9999, *) {
    group.enter()
    detach {
        print("enter async")
        try! await main()
        group.leave()
        print("exit async")
    }


    group.wait()
} else {

}

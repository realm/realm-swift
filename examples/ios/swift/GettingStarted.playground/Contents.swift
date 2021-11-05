//: To get this Playground running do the following:
//:
//: 1) In the scheme selector choose RealmSwift > iPhone 6s
//: 2) Press Cmd + B
//: 3) If the Playground didn't already run press the ▶︎ button at the bottom

import Foundation
import RealmSwift

//: I. Define the data entities

class Person: Object {
    @Persisted var name: String
    @Persisted var age: Int
    @Persisted var spouse: Person?
    @Persisted var cars: List<Car>

    override var description: String { return "Person {\(name), \(age), \(spouse?.name ?? "nil")}" }
}

class Car: Object {
    @Persisted var brand: String
    @Persisted var name: String?
    @Persisted var year: Int

    override var description: String { return "Car {\(brand), \(name), \(year)}" }
}

//: II. Init the realm file

let realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TemporaryRealm"))

//: III. Create the objects

let car1 = Car(value: ["brand": "BMW", "year": 1980])

let car2 = Car()
car2.brand = "DeLorean"
car2.name = "Outatime"
car2.year = 1981

// people
let wife = Person()
wife.name = "Jennifer"
wife.cars.append(objectsIn: [car1, car2])
wife.age = 47

let husband = Person(value: [
    "name": "Marty",
    "age": 47,
    "spouse": wife
])

wife.spouse = husband

//: IV. Write objects to the realm

try! realm.write {
    realm.add(husband)
}

//: V. Read objects back from the realm

let favorites = ["Jennifer"]

let favoritePeopleWithSpousesAndCars = realm.objects(Person.self)
    .filter("cars.@count > 1 && spouse != nil && name IN %@", favorites)
    .sorted(byKeyPath: "age")

for person in favoritePeopleWithSpousesAndCars {
    person.name
    person.age

    guard let car = person.cars.first else {
        continue
    }
    car.name
    car.brand

//: VI. Update objects

    try! realm.write {
        car.year += 1
    }
    car.year
}

//: VII. Delete objects

try! realm.write {
    realm.deleteAll()
}

realm.objects(Person.self).count
//: Thanks! To learn more about Realm go to https://realm.io

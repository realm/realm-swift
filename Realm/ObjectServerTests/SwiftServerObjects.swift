////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import RealmSwift

public class SwiftPerson: Object {
    @Persisted(primaryKey: true) public var _id: ObjectId
    @Persisted public var firstName: String = ""
    @Persisted public var lastName: String = ""
    @Persisted public var age: Int = 30

    public convenience init(firstName: String, lastName: String, age: Int = 30) {
        self.init()
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
    }
}

public class LinkToSwiftPerson: Object {
    @Persisted(primaryKey: true) public var _id: ObjectId
    @Persisted public var person: SwiftPerson?
    @Persisted public var people: List<SwiftPerson>
    @Persisted public var peopleByName: Map<String, SwiftPerson?>
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension SwiftPerson: ObjectKeyIdentifiable {}

public class SwiftTypesSyncObject: Object {
    @Persisted(primaryKey: true) public var _id: ObjectId
    @Persisted public var boolCol: Bool = true
    @Persisted public var intCol: Int = 1
    @Persisted public var doubleCol: Double = 1.1
    @Persisted public var stringCol: String = "string"
    @Persisted public var binaryCol: Data = "string".data(using: String.Encoding.utf8)!
    @Persisted public var dateCol: Date = Date(timeIntervalSince1970: -1)
    @Persisted public var longCol: Int64 = 1
    @Persisted public var decimalCol: Decimal128 = Decimal128(1)
    @Persisted public var uuidCol: UUID = UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!
    @Persisted public var objectIdCol: ObjectId
    @Persisted public var objectCol: SwiftPerson?
    @Persisted public var anyCol: AnyRealmValue = .int(1)

    public convenience init(person: SwiftPerson) {
        self.init()
        self.objectCol = person
    }
}

public class SwiftCollectionSyncObject: Object {
    @Persisted(primaryKey: true) public var _id: ObjectId
    @Persisted public var intList: List<Int>
    @Persisted public var boolList: List<Bool>
    @Persisted public var stringList: List<String>
    @Persisted public var dataList: List<Data>
    @Persisted public var dateList: List<Date>
    @Persisted public var doubleList: List<Double>
    @Persisted public var objectIdList: List<ObjectId>
    @Persisted public var decimalList: List<Decimal128>
    @Persisted public var uuidList: List<UUID>
    @Persisted public var anyList: List<AnyRealmValue>
    @Persisted public var objectList: List<SwiftPerson>

    @Persisted public var intSet: MutableSet<Int>
    @Persisted public var stringSet: MutableSet<String>
    @Persisted public var dataSet: MutableSet<Data>
    @Persisted public var dateSet: MutableSet<Date>
    @Persisted public var doubleSet: MutableSet<Double>
    @Persisted public var objectIdSet: MutableSet<ObjectId>
    @Persisted public var decimalSet: MutableSet<Decimal128>
    @Persisted public var uuidSet: MutableSet<UUID>
    @Persisted public var anySet: MutableSet<AnyRealmValue>
    @Persisted public var objectSet: MutableSet<SwiftPerson>

    @Persisted public var otherIntSet: MutableSet<Int>
    @Persisted public var otherStringSet: MutableSet<String>
    @Persisted public var otherDataSet: MutableSet<Data>
    @Persisted public var otherDateSet: MutableSet<Date>
    @Persisted public var otherDoubleSet: MutableSet<Double>
    @Persisted public var otherObjectIdSet: MutableSet<ObjectId>
    @Persisted public var otherDecimalSet: MutableSet<Decimal128>
    @Persisted public var otherUuidSet: MutableSet<UUID>
    @Persisted public var otherAnySet: MutableSet<AnyRealmValue>
    @Persisted public var otherObjectSet: MutableSet<SwiftPerson>

    @Persisted public var intMap: Map<String, Int>
    @Persisted public var stringMap: Map<String, String>
    @Persisted public var dataMap: Map<String, Data>
    @Persisted public var dateMap: Map<String, Date>
    @Persisted public var doubleMap: Map<String, Double>
    @Persisted public var objectIdMap: Map<String, ObjectId>
    @Persisted public var decimalMap: Map<String, Decimal128>
    @Persisted public var uuidMap: Map<String, UUID>
    @Persisted public var anyMap: Map<String, AnyRealmValue>
    @Persisted public var objectMap: Map<String, SwiftPerson?>
}

public class SwiftAnyRealmValueObject: Object {
    @Persisted(primaryKey: true) public var _id: ObjectId
    @Persisted public var anyCol: AnyRealmValue
    @Persisted public var otherAnyCol: AnyRealmValue
}

public class SwiftMissingObject: Object {
    @Persisted(primaryKey: true) public var _id: ObjectId
    @Persisted public var objectCol: SwiftPerson?
    @Persisted public var anyCol: AnyRealmValue
}

public class SwiftUUIDPrimaryKeyObject: Object {
    @Persisted(primaryKey: true) public var _id: UUID? = UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!
    @Persisted public var strCol: String = ""
    @Persisted public var intCol: Int = 0

    public convenience init(id: UUID?, strCol: String, intCol: Int) {
        self.init()
        self._id = id
        self.strCol = strCol
        self.intCol = intCol
    }
}

public class SwiftStringPrimaryKeyObject: Object {
    @Persisted(primaryKey: true) public var _id: String? = "1234567890ab1234567890ab"
    @Persisted public var strCol: String = ""
    @Persisted public var intCol: Int = 0

    public convenience init(id: String, strCol: String, intCol: Int) {
        self.init()
        self._id = id
        self.strCol = strCol
        self.intCol = intCol
    }
}

public class SwiftIntPrimaryKeyObject: Object {
    @Persisted(primaryKey: true) public var _id: Int = 1234567890
    @Persisted public var strCol: String = ""
    @Persisted public var intCol: Int = 0

    public convenience init(id: Int, strCol: String, intCol: Int) {
        self.init()
        self._id = id
        self.strCol = strCol
        self.intCol = intCol
    }
}

public class SwiftHugeSyncObject: Object {
    @Persisted(primaryKey: true) public var _id: ObjectId
    @Persisted public var data: Data?

    public class func create() -> SwiftHugeSyncObject {
        let fakeDataSize = 1000000
        return SwiftHugeSyncObject(value: ["data": Data(repeating: 16, count: fakeDataSize)])
    }
}

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

import Foundation
import RealmSwift

protocol TrivialCustomPersistable: CustomPersistable {
    var value: PersistedType { get set }
    init(value: PersistedType)
}

extension TrivialCustomPersistable {
    init(persistedValue: PersistedType) {
        self.init(value: persistedValue)
    }
    var persistableValue: PersistedType { value }
}

struct BoolWrapper: TrivialCustomPersistable {
    typealias PersistedType = Bool
    var value: Bool
}
struct IntWrapper: TrivialCustomPersistable {
    typealias PersistedType = Int
    var value: Int
}
struct Int8Wrapper: TrivialCustomPersistable {
    typealias PersistedType = Int8
    var value: Int8
}
struct Int16Wrapper: TrivialCustomPersistable {
    typealias PersistedType = Int16
    var value: Int16
}
struct Int32Wrapper: TrivialCustomPersistable {
    typealias PersistedType = Int32
    var value: Int32
}
struct Int64Wrapper: TrivialCustomPersistable {
    typealias PersistedType = Int64
    var value: Int64
}
struct FloatWrapper: TrivialCustomPersistable {
    typealias PersistedType = Float
    var value: Float
}
struct DoubleWrapper: TrivialCustomPersistable {
    typealias PersistedType = Double
    var value: Double
}
struct StringWrapper: TrivialCustomPersistable {
    typealias PersistedType = String
    var value: String
}
struct DataWrapper: TrivialCustomPersistable {
    typealias PersistedType = Data
    var value: Data
}
struct DateWrapper: TrivialCustomPersistable {
    typealias PersistedType = Date
    var value: Date
}
struct Decimal128Wrapper: TrivialCustomPersistable {
    typealias PersistedType = Decimal128
    var value: Decimal128
}
struct ObjectIdWrapper: TrivialCustomPersistable {
    typealias PersistedType = ObjectId
    var value: ObjectId
}
struct UUIDWrapper: TrivialCustomPersistable {
    typealias PersistedType = UUID
    var value: UUID
}

struct IntFailableWrapper: FailableCustomPersistable {
    typealias PersistedType = Int
    init?(persistedValue: Int) {
        if persistedValue == 1 {
            return nil
        }
        self.persistableValue = persistedValue
    }
    let persistableValue: Int
}

// MARK: EmbeddedObject custom persistable wrappers

struct EmbeddedObjectWrapper: CustomPersistable {
    typealias PersistedType = ModernEmbeddedObject
    init(persistedValue: PersistedType) {
        self.value = persistedValue.value
    }
    var persistableValue: ModernEmbeddedObject {
        return ModernEmbeddedObject(value: [value])
    }
    init(value: Int = 1) {
        self.value = value
    }

    var value: Int
}

class TypeWithObjectLink: EmbeddedObject {
    @Persisted var value: ModernEmbeddedObject?
}

struct WrapperForTypeWithObjectLink: CustomPersistable {
    typealias PersistedType = TypeWithObjectLink
    var persistableValue: TypeWithObjectLink { return TypeWithObjectLink() }
    init(persistedValue: TypeWithObjectLink) {}
    init() {}
}

class LinkToWrapperForTypeWithObjectLink: Object {
    @Persisted var link: WrapperForTypeWithObjectLink?
}

class TypeWithCollection: EmbeddedObject {
    @Persisted var list: List<Int>
}

struct WrapperForTypeWithCollection: CustomPersistable {
    typealias PersistedType = TypeWithCollection
    var persistableValue: TypeWithCollection { return TypeWithCollection() }
    init(persistedValue: TypeWithCollection) {}
    init() {}
}

class LinkToWrapperForTypeWithCollection: Object {
    @Persisted var link: WrapperForTypeWithCollection?
}

struct AddressSwiftWrapper: CustomPersistable {
    typealias PersistedType = AddressSwift
    var city = ""
    var country = ""
    init(persistedValue: AddressSwift) {
        city = persistedValue.city
        country = persistedValue.country
    }
    var persistableValue: AddressSwift {
        AddressSwift(value: [city, country])
    }
}

class LinkToAddressSwiftWrapper: Object {
    @Persisted var object: AddressSwiftWrapper
    @Persisted var optObject: AddressSwiftWrapper
    @Persisted var list: List<AddressSwiftWrapper>
    @Persisted var map: Map<String, AddressSwiftWrapper>
    @Persisted var optMap: Map<String, AddressSwiftWrapper?>
}

// MARK: Objects

class AllCustomPersistableTypes: Object {
    @Persisted var bool: BoolWrapper
    @Persisted var int: IntWrapper
    @Persisted var int8: Int8Wrapper
    @Persisted var int16: Int16Wrapper
    @Persisted var int32: Int32Wrapper
    @Persisted var int64: Int64Wrapper
    @Persisted var float: FloatWrapper
    @Persisted var double: DoubleWrapper
    @Persisted var string: StringWrapper
    @Persisted var binary: DataWrapper
    @Persisted var date: DateWrapper
    @Persisted var decimal: Decimal128Wrapper
    @Persisted var objectId: ObjectIdWrapper
    @Persisted var uuid: UUIDWrapper
    @Persisted var object: EmbeddedObjectWrapper

    @Persisted var optBool: BoolWrapper?
    @Persisted var optInt: IntWrapper?
    @Persisted var optInt8: Int8Wrapper?
    @Persisted var optInt16: Int16Wrapper?
    @Persisted var optInt32: Int32Wrapper?
    @Persisted var optInt64: Int64Wrapper?
    @Persisted var optFloat: FloatWrapper?
    @Persisted var optDouble: DoubleWrapper?
    @Persisted var optString: StringWrapper?
    @Persisted var optBinary: DataWrapper?
    @Persisted var optDate: DateWrapper?
    @Persisted var optDecimal: Decimal128Wrapper?
    @Persisted var optObjectId: ObjectIdWrapper?
    @Persisted var optUuid: UUIDWrapper?
    @Persisted var optObject: EmbeddedObjectWrapper?
}

class CustomPersistableCollections: Object {
    @Persisted var listBool: List<BoolWrapper>
    @Persisted var listInt: List<IntWrapper>
    @Persisted var listInt8: List<Int8Wrapper>
    @Persisted var listInt16: List<Int16Wrapper>
    @Persisted var listInt32: List<Int32Wrapper>
    @Persisted var listInt64: List<Int64Wrapper>
    @Persisted var listFloat: List<FloatWrapper>
    @Persisted var listDouble: List<DoubleWrapper>
    @Persisted var listString: List<StringWrapper>
    @Persisted var listBinary: List<DataWrapper>
    @Persisted var listDate: List<DateWrapper>
    @Persisted var listDecimal: List<Decimal128Wrapper>
    @Persisted var listUuid: List<UUIDWrapper>
    @Persisted var listObjectId: List<ObjectIdWrapper>
    @Persisted var listObject: List<EmbeddedObjectWrapper>

    @Persisted var listOptBool: List<BoolWrapper?>
    @Persisted var listOptInt: List<IntWrapper?>
    @Persisted var listOptInt8: List<Int8Wrapper?>
    @Persisted var listOptInt16: List<Int16Wrapper?>
    @Persisted var listOptInt32: List<Int32Wrapper?>
    @Persisted var listOptInt64: List<Int64Wrapper?>
    @Persisted var listOptFloat: List<FloatWrapper?>
    @Persisted var listOptDouble: List<DoubleWrapper?>
    @Persisted var listOptString: List<StringWrapper?>
    @Persisted var listOptBinary: List<DataWrapper?>
    @Persisted var listOptDate: List<DateWrapper?>
    @Persisted var listOptDecimal: List<Decimal128Wrapper?>
    @Persisted var listOptUuid: List<UUIDWrapper?>
    @Persisted var listOptObjectId: List<ObjectIdWrapper?>

    @Persisted var setBool: MutableSet<BoolWrapper>
    @Persisted var setInt: MutableSet<IntWrapper>
    @Persisted var setInt8: MutableSet<Int8Wrapper>
    @Persisted var setInt16: MutableSet<Int16Wrapper>
    @Persisted var setInt32: MutableSet<Int32Wrapper>
    @Persisted var setInt64: MutableSet<Int64Wrapper>
    @Persisted var setFloat: MutableSet<FloatWrapper>
    @Persisted var setDouble: MutableSet<DoubleWrapper>
    @Persisted var setString: MutableSet<StringWrapper>
    @Persisted var setBinary: MutableSet<DataWrapper>
    @Persisted var setDate: MutableSet<DateWrapper>
    @Persisted var setDecimal: MutableSet<Decimal128Wrapper>
    @Persisted var setUuid: MutableSet<UUIDWrapper>
    @Persisted var setObjectId: MutableSet<ObjectIdWrapper>

    @Persisted var setOptBool: MutableSet<BoolWrapper?>
    @Persisted var setOptInt: MutableSet<IntWrapper?>
    @Persisted var setOptInt8: MutableSet<Int8Wrapper?>
    @Persisted var setOptInt16: MutableSet<Int16Wrapper?>
    @Persisted var setOptInt32: MutableSet<Int32Wrapper?>
    @Persisted var setOptInt64: MutableSet<Int64Wrapper?>
    @Persisted var setOptFloat: MutableSet<FloatWrapper?>
    @Persisted var setOptDouble: MutableSet<DoubleWrapper?>
    @Persisted var setOptString: MutableSet<StringWrapper?>
    @Persisted var setOptBinary: MutableSet<DataWrapper?>
    @Persisted var setOptDate: MutableSet<DateWrapper?>
    @Persisted var setOptDecimal: MutableSet<Decimal128Wrapper?>
    @Persisted var setOptUuid: MutableSet<UUIDWrapper?>
    @Persisted var setOptObjectId: MutableSet<ObjectIdWrapper?>

    @Persisted var mapBool: Map<String, BoolWrapper>
    @Persisted var mapInt: Map<String, IntWrapper>
    @Persisted var mapInt8: Map<String, Int8Wrapper>
    @Persisted var mapInt16: Map<String, Int16Wrapper>
    @Persisted var mapInt32: Map<String, Int32Wrapper>
    @Persisted var mapInt64: Map<String, Int64Wrapper>
    @Persisted var mapFloat: Map<String, FloatWrapper>
    @Persisted var mapDouble: Map<String, DoubleWrapper>
    @Persisted var mapString: Map<String, StringWrapper>
    @Persisted var mapBinary: Map<String, DataWrapper>
    @Persisted var mapDate: Map<String, DateWrapper>
    @Persisted var mapDecimal: Map<String, Decimal128Wrapper>
    @Persisted var mapUuid: Map<String, UUIDWrapper>
    @Persisted var mapObjectId: Map<String, ObjectIdWrapper>
    @Persisted var mapObject: Map<String, EmbeddedObjectWrapper>

    @Persisted var mapOptBool: Map<String, BoolWrapper?>
    @Persisted var mapOptInt: Map<String, IntWrapper?>
    @Persisted var mapOptInt8: Map<String, Int8Wrapper?>
    @Persisted var mapOptInt16: Map<String, Int16Wrapper?>
    @Persisted var mapOptInt32: Map<String, Int32Wrapper?>
    @Persisted var mapOptInt64: Map<String, Int64Wrapper?>
    @Persisted var mapOptFloat: Map<String, FloatWrapper?>
    @Persisted var mapOptDouble: Map<String, DoubleWrapper?>
    @Persisted var mapOptString: Map<String, StringWrapper?>
    @Persisted var mapOptBinary: Map<String, DataWrapper?>
    @Persisted var mapOptDate: Map<String, DateWrapper?>
    @Persisted var mapOptDecimal: Map<String, Decimal128Wrapper?>
    @Persisted var mapOptUuid: Map<String, UUIDWrapper?>
    @Persisted var mapOptObjectId: Map<String, ObjectIdWrapper?>
    @Persisted var mapOptObject: Map<String, EmbeddedObjectWrapper?>
}

class LinkToAllCustomPersistableTypes: Object {
    @Persisted var object: AllCustomPersistableTypes?
    @Persisted var list: List<AllCustomPersistableTypes>
    @Persisted var set: MutableSet<AllCustomPersistableTypes>
    @Persisted var map: Map<String, AllCustomPersistableTypes?>
}

class LinkToCustomPersistableCollections: Object {
    @Persisted var object: CustomPersistableCollections?
    @Persisted var list: List<CustomPersistableCollections>
    @Persisted var set: MutableSet<CustomPersistableCollections>
    @Persisted var map: Map<String, CustomPersistableCollections?>
}

class CustomAllIndexableTypesObject: Object {
    @Persisted(indexed: true) var boolCol: BoolWrapper
    @Persisted(indexed: true) var intCol: IntWrapper
    @Persisted(indexed: true) var int8Col: Int8Wrapper
    @Persisted(indexed: true) var int16Col: Int16Wrapper
    @Persisted(indexed: true) var int32Col: Int32Wrapper
    @Persisted(indexed: true) var int64Col: Int64Wrapper
    @Persisted(indexed: true) var stringCol: StringWrapper
    @Persisted(indexed: true) var dateCol: DateWrapper
    @Persisted(indexed: true) var uuidCol: UUIDWrapper
    @Persisted(indexed: true) var objectIdCol: ObjectIdWrapper

    @Persisted(indexed: true) var optIntCol: IntWrapper?
    @Persisted(indexed: true) var optInt8Col: Int8Wrapper?
    @Persisted(indexed: true) var optInt16Col: Int16Wrapper?
    @Persisted(indexed: true) var optInt32Col: Int32Wrapper?
    @Persisted(indexed: true) var optInt64Col: Int64Wrapper?
    @Persisted(indexed: true) var optBoolCol: BoolWrapper?
    @Persisted(indexed: true) var optStringCol: StringWrapper?
    @Persisted(indexed: true) var optDateCol: DateWrapper?
    @Persisted(indexed: true) var optUuidCol: UUIDWrapper?
    @Persisted(indexed: true) var optObjectIdCol: ObjectIdWrapper?
}

class CustomAllIndexableButNotIndexedObject: Object {
    @Persisted(indexed: false) var boolCol: BoolWrapper
    @Persisted(indexed: false) var intCol: IntWrapper
    @Persisted(indexed: false) var int8Col: Int8Wrapper
    @Persisted(indexed: false) var int16Col: Int16Wrapper
    @Persisted(indexed: false) var int32Col: Int32Wrapper
    @Persisted(indexed: false) var int64Col: Int64Wrapper
    @Persisted(indexed: false) var stringCol: StringWrapper
    @Persisted(indexed: false) var dateCol: DateWrapper
    @Persisted(indexed: false) var uuidCol: UUIDWrapper
    @Persisted(indexed: false) var objectIdCol: ObjectIdWrapper

    @Persisted(indexed: false) var optIntCol: IntWrapper?
    @Persisted(indexed: false) var optInt8Col: Int8Wrapper?
    @Persisted(indexed: false) var optInt16Col: Int16Wrapper?
    @Persisted(indexed: false) var optInt32Col: Int32Wrapper?
    @Persisted(indexed: false) var optInt64Col: Int64Wrapper?
    @Persisted(indexed: false) var optBoolCol: BoolWrapper?
    @Persisted(indexed: false) var optStringCol: StringWrapper?
    @Persisted(indexed: false) var optDateCol: DateWrapper?
    @Persisted(indexed: false) var optUuidCol: UUIDWrapper?
    @Persisted(indexed: false) var optObjectIdCol: ObjectIdWrapper?
}

class FailableCustomObject: Object {
    @Persisted var int: IntFailableWrapper
    @Persisted var optInt: IntFailableWrapper?
    @Persisted var listInt: List<IntFailableWrapper>
    @Persisted var optListInt: List<IntFailableWrapper?>
    @Persisted var setInt: MutableSet<IntFailableWrapper>
    @Persisted var optSetInt: MutableSet<IntFailableWrapper?>
    @Persisted var mapInt: Map<String, IntFailableWrapper>
    @Persisted var optMapInt: Map<String, IntFailableWrapper?>
}

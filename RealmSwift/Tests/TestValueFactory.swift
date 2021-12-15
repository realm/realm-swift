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

// MARK: - ObjectFactory

protocol ObjectFactory {
    static func get<T: Object>() -> T
}
struct ManagedObjectFactory: ObjectFactory {
    static func get<T: Object>() -> T {
        let config = Realm.Configuration(inMemoryIdentifier: "test",
                                         objectTypes: [ModernAllTypesObject.self,
                                                       ModernCollectionsOfEnums.self,
                                                       SwiftStringObject.self])
        let realm = try! Realm(configuration: config)
        if !realm.isInWriteTransaction {
            realm.beginWrite()
        }
        let obj = T()
        realm.add(obj)
        return obj
    }
}
struct UnmanagedObjectFactory: ObjectFactory {
    static func get<T: Object>() -> T {
        return T()
    }
}

// MARK: ValueFactory

protocol ValueFactory: RealmCollectionValue, _DefaultConstructible {
    associatedtype Wrapped: RealmCollectionValue = Self
    associatedtype AverageType: AddableType = Double

    static func values() -> [Self]
    static func doubleValue(_ value: AverageType) -> Double
    static func doubleValue(t value: Self) -> Double
    static func doubleValue(w value: Wrapped) -> Double
}
extension ValueFactory {
    static func doubleValue(_ value: Double) -> Double {
        return value
    }
    static func doubleValue(t value: Self) -> Double {
        return (value as! NSNumber).doubleValue
    }
    static func doubleValue(w value: Wrapped) -> Double {
        return (value as! NSNumber).doubleValue
    }
}
extension ValueFactory where Self: PersistableEnum {
    static func values() -> [Self] {
        return Array(Self.allCases)
    }
}

protocol ListValueFactory: ValueFactory {
    associatedtype ListRoot: Object
    static var array: KeyPath<ListRoot, List<Self>> { get }
    static var optArray: KeyPath<ListRoot, List<Self?>> { get }
}

protocol SetValueFactory: ValueFactory {
    associatedtype SetRoot: Object
    static var mutableSet: KeyPath<SetRoot, MutableSet<Self>> { get }
    static var optMutableSet: KeyPath<SetRoot, MutableSet<Self?>> { get }
}

protocol MapValueFactory: ValueFactory {
    associatedtype MapRoot: Object
    static var map: KeyPath<MapRoot, Map<String, Self>> { get }
    static var optMap: KeyPath<MapRoot, Map<String, Self?>> { get }
}

// MARK: Optional

extension Optional: _DefaultConstructible where Wrapped: _DefaultConstructible {
    public init() {
        self = .none
    }
}

extension Optional: ValueFactory where Wrapped: ValueFactory & _DefaultConstructible {
    typealias AverageType = Wrapped.AverageType

    static func doubleValue(_ value: Wrapped.AverageType) -> Double {
        Wrapped.doubleValue(value)
    }
    static func doubleValue(t value: Self) -> Double {
        return Wrapped.doubleValue(t: value!)
    }
    static func doubleValue(w value: Wrapped) -> Double {
        return Wrapped.doubleValue(w: value as! Wrapped.Wrapped)
    }

    static func values() -> [Self] {
        var v = Array<Self>(Wrapped.values())
        v.remove(at: 1)
        v.insert(nil, at: 0)
        return v
    }
}

extension Optional: ListValueFactory where Wrapped: ListValueFactory {
    static var array: KeyPath<Wrapped.ListRoot, List<Self>> { Wrapped.optArray }
    static var optArray: KeyPath<Wrapped.ListRoot, List<Self?>> { fatalError() }
}
extension Optional: SetValueFactory where Wrapped: SetValueFactory {
    static var mutableSet: KeyPath<Wrapped.SetRoot, MutableSet<Self>> { Wrapped.optMutableSet }
    static var optMutableSet: KeyPath<Wrapped.SetRoot, MutableSet<Self?>> { fatalError() }
}
extension Optional: MapValueFactory where Wrapped: MapValueFactory {
    static var map: KeyPath<Wrapped.MapRoot, Map<String, Self>> { Wrapped.optMap }
    static var optMap: KeyPath<Wrapped.MapRoot, Map<String, Self?>> { fatalError() }
}

// MARK: - Bool

extension Bool: ValueFactory {
    private static let _values: [Bool] = [true, false, true]
    static func values() -> [Bool] {
        return _values
    }
}
extension Bool: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Bool>> { \.arrayBool }
    static var optArray: KeyPath<ModernAllTypesObject, List<Bool?>> { \.arrayOptBool }
}
extension Bool: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Bool>> { \.setBool }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Bool?>> { \.setOptBool }
}
extension Bool: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Bool>> { \.mapBool }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Bool?>> { \.mapOptBool }
}

// MARK: - Int

extension Int: ValueFactory {
    private static let _values: [Int] = [1, 2, 3]
    static func values() -> [Int] {
        return _values
    }
}
extension Int: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Int>> { \.arrayInt }
    static var optArray: KeyPath<ModernAllTypesObject, List<Int?>> { \.arrayOptInt }
}
extension Int: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int>> { \.setInt }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int?>> { \.setOptInt }
}
extension Int: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Int>> { \.mapInt }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Int?>> { \.mapOptInt }
}

// MARK: - Int8

extension Int8: ValueFactory {
    private static let _values: [Int8] = [1, 2, 3]
    static func values() -> [Int8] {
        return _values
    }
}
extension Int8: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Int8>> { \.arrayInt8 }
    static var optArray: KeyPath<ModernAllTypesObject, List<Int8?>> { \.arrayOptInt8 }
}
extension Int8: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int8>> { \.setInt8 }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int8?>> { \.setOptInt8 }
}
extension Int8: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Int8>> { \.mapInt8 }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Int8?>> { \.mapOptInt8 }
}

// MARK: - Int16

extension Int16: ValueFactory {
    private static let _values: [Int16] = [1, 2, 3]
    static func values() -> [Int16] {
        return _values
    }
}
extension Int16: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Int16>> { \.arrayInt16 }
    static var optArray: KeyPath<ModernAllTypesObject, List<Int16?>> { \.arrayOptInt16 }
}
extension Int16: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int16>> { \.setInt16 }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int16?>> { \.setOptInt16 }
}
extension Int16: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Int16>> { \.mapInt16 }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Int16?>> { \.mapOptInt16 }
}

// MARK: - Int32

extension Int32: ValueFactory {
    private static let _values: [Int32] = [1, 2, 3]
    static func values() -> [Int32] {
        return _values
    }
}
extension Int32: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Int32>> { \.arrayInt32 }
    static var optArray: KeyPath<ModernAllTypesObject, List<Int32?>> { \.arrayOptInt32 }
}
extension Int32: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int32>> { \.setInt32 }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int32?>> { \.setOptInt32 }
}
extension Int32: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Int32>> { \.mapInt32 }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Int32?>> { \.mapOptInt32 }
}

// MARK: - Int64

extension Int64: ValueFactory {
    private static let _values: [Int64] = [1, 2, 3]
    static func values() -> [Int64] {
        return _values
    }
}
extension Int64: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Int64>> { \.arrayInt64 }
    static var optArray: KeyPath<ModernAllTypesObject, List<Int64?>> { \.arrayOptInt64 }
}
extension Int64: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int64>> { \.setInt64 }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Int64?>> { \.setOptInt64 }
}
extension Int64: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Int64>> { \.mapInt64 }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Int64?>> { \.mapOptInt64 }
}

// MARK: - Float

extension Float: ValueFactory {
    private static let _values: [Float] = [1.1, 2.2, 3.3]
    static func values() -> [Float] {
        return _values
    }
}
extension Float: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Float>> { \.arrayFloat }
    static var optArray: KeyPath<ModernAllTypesObject, List<Float?>> { \.arrayOptFloat }
}
extension Float: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Float>> { \.setFloat }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Float?>> { \.setOptFloat }
}
extension Float: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Float>> { \.mapFloat }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Float?>> { \.mapOptFloat }
}

// MARK: - Double

extension Double: ValueFactory {
    private static let _values: [Double] = [1.1, 2.2, 3.3]
    static func values() -> [Double] {
        return _values
    }
}
extension Double: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Double>> { \.arrayDouble }
    static var optArray: KeyPath<ModernAllTypesObject, List<Double?>> { \.arrayOptDouble }
}
extension Double: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Double>> { \.setDouble }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Double?>> { \.setOptDouble }
}
extension Double: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Double>> { \.mapDouble }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Double?>> { \.mapOptDouble }
}

// MARK: - String

extension String: ValueFactory {
    private static let _values: [String] = ["a", "b", "c"]
    static func values() -> [String] {
        return _values
    }
}
extension String: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<String>> { \.arrayString }
    static var optArray: KeyPath<ModernAllTypesObject, List<String?>> { \.arrayOptString }
}
extension String: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<String>> { \.setString }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<String?>> { \.setOptString }
}
extension String: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, String>> { \.mapString }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, String?>> { \.mapOptString }
}

// MARK: - Data

extension Data: ValueFactory {
    private static let _values: [Data] = ["a".data(using: .utf8)!, "b".data(using: .utf8)!, "c".data(using: .utf8)!]
    static func values() -> [Data] {
        return _values
    }
}
extension Data: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Data>> { \.arrayBinary }
    static var optArray: KeyPath<ModernAllTypesObject, List<Data?>> { \.arrayOptBinary }
}
extension Data: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Data>> { \.setBinary }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Data?>> { \.setOptBinary }
}
extension Data: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Data>> { \.mapBinary }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Data?>> { \.mapOptBinary }
}

// MARK: - Date

extension Date: ValueFactory {
    private static let _values: [Date] = [Date(), Date().addingTimeInterval(10), Date().addingTimeInterval(20)]
    static func values() -> [Date] {
        return _values
    }
}
extension Date: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Date>> { \.arrayDate }
    static var optArray: KeyPath<ModernAllTypesObject, List<Date?>> { \.arrayOptDate }
}
extension Date: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Date>> { \.setDate }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Date?>> { \.setOptDate }
}
extension Date: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Date>> { \.mapDate }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Date?>> { \.mapOptDate }
}

// MARK: - Decimal128

extension Decimal128: ValueFactory {
    private static let _values: [Decimal128] = [Decimal128(number: 1), Decimal128(number: 2), Decimal128(number: 3)]
    static func values() -> [Decimal128] {
        return _values
    }

    static func doubleValue(_ value: Decimal128) -> Double {
        return value.doubleValue
    }
    static func doubleValue(t value: Decimal128) -> Double {
        return value.doubleValue
    }
    static func doubleValue(w value: Decimal128) -> Double {
        return value.doubleValue
    }
}
extension Decimal128: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<Decimal128>> { \.arrayDecimal }
    static var optArray: KeyPath<ModernAllTypesObject, List<Decimal128?>> { \.arrayOptDecimal }
}
extension Decimal128: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<Decimal128>> { \.setDecimal }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<Decimal128?>> { \.setOptDecimal }
}
extension Decimal128: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, Decimal128>> { \.mapDecimal }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, Decimal128?>> { \.mapOptDecimal }
}

// MARK: - ObjectId

extension ObjectId: ValueFactory {
    private static let _values: [ObjectId] = [ObjectId.generate(), ObjectId.generate(), ObjectId.generate()]
    static func values() -> [ObjectId] {
        return _values
    }
}
extension ObjectId: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<ObjectId>> { \.arrayObjectId }
    static var optArray: KeyPath<ModernAllTypesObject, List<ObjectId?>> { \.arrayOptObjectId }
}
extension ObjectId: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<ObjectId>> { \.setObjectId }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<ObjectId?>> { \.setOptObjectId }
}
extension ObjectId: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, ObjectId>> { \.mapObjectId }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, ObjectId?>> { \.mapOptObjectId }
}

// MARK: - UUID

extension UUID: ValueFactory {
    private static let _values: [UUID] = [UUID(), UUID(), UUID()]
    static func values() -> [UUID] {
        return _values
    }
}
extension UUID: ListValueFactory {
    static var array: KeyPath<ModernAllTypesObject, List<UUID>> { \.arrayUuid }
    static var optArray: KeyPath<ModernAllTypesObject, List<UUID?>> { \.arrayOptUuid }
}
extension UUID: SetValueFactory {
    static var mutableSet: KeyPath<ModernAllTypesObject, MutableSet<UUID>> { \.setUuid }
    static var optMutableSet: KeyPath<ModernAllTypesObject, MutableSet<UUID?>> { \.setOptUuid }
}
extension UUID: MapValueFactory {
    static var map: KeyPath<ModernAllTypesObject, Map<String, UUID>> { \.mapUuid }
    static var optMap: KeyPath<ModernAllTypesObject, Map<String, UUID?>> { \.mapOptUuid }
}

// MARK: - EnumInt

enum EnumInt: Int, PersistableEnum {
    case value1 = 1
    case value2 = 2
    case value3 = 3
}
extension EnumInt: ValueFactory {
    static func values() -> [EnumInt] {
        return EnumInt.allCases
    }
}
extension EnumInt: ListValueFactory {
    static var array: KeyPath<ModernCollectionsOfEnums, List<EnumInt>> { \.listInt }
    static var optArray: KeyPath<ModernCollectionsOfEnums, List<EnumInt?>> { \.listIntOpt }
}
extension EnumInt: SetValueFactory {
    static var mutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt>> { \.setInt }
    static var optMutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt?>> { \.setIntOpt }
}
extension EnumInt: MapValueFactory {
    static var map: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt>> { \.mapInt }
    static var optMap: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt?>> { \.mapIntOpt }
}

// MARK: - EnumInt8

enum EnumInt8: Int8, PersistableEnum {
    case value1 = 1
    case value2 = 2
    case value3 = 3
}
extension EnumInt8: ValueFactory {
    static func values() -> [EnumInt8] {
        return EnumInt8.allCases
    }
}
extension EnumInt8: ListValueFactory {
    static var array: KeyPath<ModernCollectionsOfEnums, List<EnumInt8>> { \.listInt8 }
    static var optArray: KeyPath<ModernCollectionsOfEnums, List<EnumInt8?>> { \.listInt8Opt }
}
extension EnumInt8: SetValueFactory {
    static var mutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt8>> { \.setInt8 }
    static var optMutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt8?>> { \.setInt8Opt }
}
extension EnumInt8: MapValueFactory {
    static var map: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt8>> { \.mapInt8 }
    static var optMap: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt8?>> { \.mapInt8Opt }
}

// MARK: - EnumInt16

enum EnumInt16: Int16, PersistableEnum {
    case value1 = 1
    case value2 = 2
    case value3 = 3
}
extension EnumInt16: ValueFactory {
    static func values() -> [EnumInt16] {
        return EnumInt16.allCases
    }
}
extension EnumInt16: ListValueFactory {
    static var array: KeyPath<ModernCollectionsOfEnums, List<EnumInt16>> { \.listInt16 }
    static var optArray: KeyPath<ModernCollectionsOfEnums, List<EnumInt16?>> { \.listInt16Opt }
}
extension EnumInt16: SetValueFactory {
    static var mutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt16>> { \.setInt16 }
    static var optMutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt16?>> { \.setInt16Opt }
}
extension EnumInt16: MapValueFactory {
    static var map: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt16>> { \.mapInt16 }
    static var optMap: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt16?>> { \.mapInt16Opt }
}

// MARK: - EnumInt32

enum EnumInt32: Int32, PersistableEnum {
    case value1 = 1
    case value2 = 2
    case value3 = 3
}
extension EnumInt32: ValueFactory {
    static func values() -> [EnumInt32] {
        return EnumInt32.allCases
    }
}
extension EnumInt32: ListValueFactory {
    static var array: KeyPath<ModernCollectionsOfEnums, List<EnumInt32>> { \.listInt32 }
    static var optArray: KeyPath<ModernCollectionsOfEnums, List<EnumInt32?>> { \.listInt32Opt }
}
extension EnumInt32: SetValueFactory {
    static var mutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt32>> { \.setInt32 }
    static var optMutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt32?>> { \.setInt32Opt }
}
extension EnumInt32: MapValueFactory {
    static var map: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt32>> { \.mapInt32 }
    static var optMap: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt32?>> { \.mapInt32Opt }
}

// MARK: - EnumInt64

enum EnumInt64: Int64, PersistableEnum {
    case value1 = 1
    case value2 = 2
    case value3 = 3
}
extension EnumInt64: ValueFactory {
    static func values() -> [EnumInt64] {
        return EnumInt64.allCases
    }
}
extension EnumInt64: ListValueFactory {
    static var array: KeyPath<ModernCollectionsOfEnums, List<EnumInt64>> { \.listInt64 }
    static var optArray: KeyPath<ModernCollectionsOfEnums, List<EnumInt64?>> { \.listInt64Opt }
}
extension EnumInt64: SetValueFactory {
    static var mutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt64>> { \.setInt64 }
    static var optMutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumInt64?>> { \.setInt64Opt }
}
extension EnumInt64: MapValueFactory {
    static var map: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt64>> { \.mapInt64 }
    static var optMap: KeyPath<ModernCollectionsOfEnums, Map<String, EnumInt64?>> { \.mapInt64Opt }
}

// MARK: - EnumFloat

enum EnumFloat: Float, PersistableEnum {
    case value1 = 1.1
    case value2 = 2.2
    case value3 = 3.3
}
extension EnumFloat: ValueFactory {
    static func values() -> [EnumFloat] {
        return EnumFloat.allCases
    }
}
extension EnumFloat: ListValueFactory {
    static var array: KeyPath<ModernCollectionsOfEnums, List<EnumFloat>> { \.listFloat }
    static var optArray: KeyPath<ModernCollectionsOfEnums, List<EnumFloat?>> { \.listFloatOpt }
}
extension EnumFloat: SetValueFactory {
    static var mutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumFloat>> { \.setFloat }
    static var optMutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumFloat?>> { \.setFloatOpt }
}
extension EnumFloat: MapValueFactory {
    static var map: KeyPath<ModernCollectionsOfEnums, Map<String, EnumFloat>> { \.mapFloat }
    static var optMap: KeyPath<ModernCollectionsOfEnums, Map<String, EnumFloat?>> { \.mapFloatOpt }
}

// MARK: - EnumDouble

enum EnumDouble: Double, PersistableEnum {
    case value1 = 1.1
    case value2 = 2.2
    case value3 = 3.3
}
extension EnumDouble: ValueFactory {
    static func values() -> [EnumDouble] {
        return EnumDouble.allCases
    }
}
extension EnumDouble: ListValueFactory {
    static var array: KeyPath<ModernCollectionsOfEnums, List<EnumDouble>> { \.listDouble }
    static var optArray: KeyPath<ModernCollectionsOfEnums, List<EnumDouble?>> { \.listDoubleOpt }
}
extension EnumDouble: SetValueFactory {
    static var mutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumDouble>> { \.setDouble }
    static var optMutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumDouble?>> { \.setDoubleOpt }
}
extension EnumDouble: MapValueFactory {
    static var map: KeyPath<ModernCollectionsOfEnums, Map<String, EnumDouble>> { \.mapDouble }
    static var optMap: KeyPath<ModernCollectionsOfEnums, Map<String, EnumDouble?>> { \.mapDoubleOpt }
}

// MARK: - EnumString

enum EnumString: String, PersistableEnum {
    case value1 = "a"
    case value2 = "b"
    case value3 = "c"
}
extension EnumString: ValueFactory {
    static func values() -> [EnumString] {
        return EnumString.allCases
    }
}
extension EnumString: ListValueFactory {
    static var array: KeyPath<ModernCollectionsOfEnums, List<EnumString>> { \.listString }
    static var optArray: KeyPath<ModernCollectionsOfEnums, List<EnumString?>> { \.listStringOpt }
}
extension EnumString: SetValueFactory {
    static var mutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumString>> { \.setString }
    static var optMutableSet: KeyPath<ModernCollectionsOfEnums, MutableSet<EnumString?>> { \.setStringOpt }
}
extension EnumString: MapValueFactory {
    static var map: KeyPath<ModernCollectionsOfEnums, Map<String, EnumString>> { \.mapString }
    static var optMap: KeyPath<ModernCollectionsOfEnums, Map<String, EnumString?>> { \.mapStringOpt }
}

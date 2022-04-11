import Foundation

#if os(macOS)
import Realm
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
#endif

// MARK: Schemagen

func generateProperty(objectSchemas: [RLMObjectSchema], objectName: String) -> RLMProperty {
    var allowedPropertyTypes = (0...RLMPropertyType.UUID.rawValue).map { $0 }
    // TODO: Re-enable linking objects at later date
    allowedPropertyTypes.remove(at: Int(RLMPropertyType.linkingObjects.rawValue))
    let type = RLMPropertyType(rawValue: allowedPropertyTypes.randomElement()!)!
    let isCollection = Bool.random()
    let isIndexable: Bool =
        !isCollection && (type == .int || type == .bool || type == .date ||
        type == .string || type == .objectId || type == .UUID ||
        type == .any)
    let isOptional = type == .object && !isCollection ? true : isCollection ? false : Bool.random()
    let property = RLMProperty(name: randomString(Int.random(in: 3..<60)),
                               type: type,
                               objectClassName: type == .object ? objectSchemas.randomElement()?.objectName ?? objectName : nil,
                               linkOriginPropertyName: nil,
                               indexed: isIndexable ? Bool.random() : false,
                               optional: isOptional)
    property.array = isCollection
    return property
}

private func generateObjectSchema(objectSchemas: inout [RLMObjectSchema]) {
    let name = randomString(Int.random(in: 3..<30))
    let schema = RLMObjectSchema(className: name,
                                 objectClass: RLMObject.self,
                                 properties: (0..<Int.random(in: 1..<30)).map { _ in generateProperty(objectSchemas: objectSchemas, objectName: name) })
    let pk = RLMProperty(name: "_id",
                         type: [.int, .string, .objectId, .UUID].randomElement()!,
                         objectClassName: nil,
                         linkOriginPropertyName: nil,
                         indexed: Bool.random(),
                         optional: false)
    schema.properties.append(pk)
    schema.primaryKeyProperty = pk

    objectSchemas.append(schema)
}

func generateSchema() -> RLMSchema {
    var objectSchemas: [RLMObjectSchema] = []
    (3...Int.random(in: 3...10)).forEach { _ in
        generateObjectSchema(objectSchemas: &objectSchemas)
    }
    let schema = RLMSchema()
    schema.objectSchema = objectSchemas
    return schema
}

func generateList<T: RealmCollectionValue>(_ generator: () -> T) -> List<T> {
    (0..<256).reduce(into: List<T>()) { partialResult, _ in
        partialResult.append(generator())
    }
}

func generateObject(for schema: ObjectSchema, fullSchema: [ObjectSchema]) -> [String: Any] {
    schema.properties.reduce(into: [String: Any]()) { dict, property in
        if !property.isOptional {
            switch property.type {
            case .int:
                dict[property.name] =
                property.isArray ? generateList {
                    Int.random(in: Int.min...Int.max)
                } : Int.random(in: Int.min...Int.max)
            case .bool:
                dict[property.name] =
                property.isArray ? generateList { Bool.random() } : Bool.random()
            case .float:
                dict[property.name] =
                property.isArray ? generateList {
                    Float.random(in: Float.leastNormalMagnitude...Float.greatestFiniteMagnitude)
                } : Float.random(in: Float.leastNormalMagnitude...Float.greatestFiniteMagnitude)
            case .double:
                dict[property.name] =
                property.isArray ? generateList {
                    Double.random(in: Double.leastNormalMagnitude...Double.greatestFiniteMagnitude)
                } : Double.random(in: Double.leastNormalMagnitude...Double.greatestFiniteMagnitude)
            case .UUID:
                dict[property.name] = property.isArray ? generateList { UUID() } : UUID()
            case .string:
                dict[property.name] = property.isArray ?
                    generateList { randomString(of: 256) } : randomString(of: 256)
            case .data:
                dict[property.name] = property.isArray ?
                generateList { randomString(of: 256).data(using: .utf8)! } : randomString(of: 256).data(using: .utf8)!
            case .any:
                dict[property.name] = property.isArray ?
                    generateList { AnyRealmValue.randomValue } : AnyRealmValue.randomValue
            case .date:
                dict[property.name] = property.isArray ?
                    generateList { Date() } : Date()// TODO: make more random
            case .objectId:
                dict[property.name] = property.isArray ?
                    generateList { ObjectId.generate() } : ObjectId.generate()
            case .decimal128:
                dict[property.name] = property.isArray ?
                generateList {
                    Decimal128(floatLiteral: Double.random(in: Double.leastNormalMagnitude...Double.greatestFiniteMagnitude)) } :
                Decimal128(floatLiteral: Double.random(in: Double.leastNormalMagnitude...Double.greatestFiniteMagnitude))
            case .object:
                dict[property.name] = property.isArray ? [String: Any]() :
                    Bool.random() ? generateObject(for: fullSchema.first { $0.className == property.objectClassName }!,
                                                   fullSchema: fullSchema) : nil
            default: fatalError()
            }
        }
    }
}

// MARK: OpLog
// TODO: Possibly swap this out with Audit SDK once that project is complete.

/// An action allowed on a realm. Basically CRUD.
enum RealmAction: String, PersistableEnum, CaseIterable {
    case add
    case modify
    case remove
    case read
}

/// A record of an operation commited to the realm
class Operation: Object {
    /// the date an operation was completed
    @Persisted var date = Date()
    /// the action of a given operation
    @Persisted var action: RealmAction = .add
    /// the class name of the object operated on
    @Persisted var objectName: String
    /// the primary key value of the object (if it has one)
    @Persisted var primaryKey: String?
    /// the name of the property modified if the action was `.modify`
    @Persisted var propertyModified: String?
    /// the original value of the property modified if the action was `.modify`
    @Persisted var originalValue: AnyRealmValue
    /// the new value of the property modified if the action was `.modify`
    @Persisted var newValue: AnyRealmValue
    /// the associated list operation if the action `.modify` and the property was of type array
    @Persisted var listOperation: ListOperation?
    /// the associated list operation if the action `.modify` and the property was of type set
    @Persisted var setOperation: SetOperation?

    convenience init(action: RealmAction,
                     objectName: String,
                     primaryKey: String? = nil,
                     propertyModified: String? = nil,
                     originalValue: AnyRealmValue = .none,
                     newValue: AnyRealmValue = .none,
                     listOperation: ListOperation? = nil,
                     setOperation: SetOperation? = nil) {
        self.init()
        self.action = action
        self.objectName = objectName
        self.primaryKey = primaryKey
        self.propertyModified = propertyModified
        self.originalValue = originalValue
        self.newValue = newValue
        self.listOperation = listOperation
        self.setOperation = setOperation
    }
}

/// An action allowed on a list.
enum ListAction: String, PersistableEnum, CaseIterable {
    case add
    case move
    case remove
}

/// An action allowed on a set.
enum SetAction: String, PersistableEnum, CaseIterable {
    case add
    case remove
}

class ListOperation: Object {
    /// The date this operation was completed
    @Persisted var date = Date()
    /// The action of a given list operation
    @Persisted var action: ListAction = .add
    /// the primary keys of the objects affected by the operation (if valid)
    @Persisted var affectedObjectPrimaryKeys: RealmSwift.List<String>
    /// whether or not an object already in the realm was added to the list or a new object was added (or nothing was added)
    @Persisted var didAddExistingObject: Bool
    /// the indices affected by the modification
    @Persisted var indicesAffected: RealmSwift.List<Int>

    convenience init(action: ListAction,
                     affectedObjectPrimaryKeys: [String],
                     didAddExistingObject: Bool,
                     indicesAffected: [Int]) {
        self.init()
        self.action = action
        self.affectedObjectPrimaryKeys.append(objectsIn: affectedObjectPrimaryKeys)
        self.didAddExistingObject = didAddExistingObject
        self.indicesAffected.append(objectsIn: indicesAffected)
    }
}

class SetOperation: Object {
    @Persisted var date = Date()
    @Persisted var action: SetAction = .add
    @Persisted var affectedObjectPrimaryKeys: RealmSwift.List<String>
    @Persisted var didAddExistingObject: Bool

    convenience init(action: SetAction,
                     affectedObjectPrimaryKeys: [String],
                     didAddExistingObject: Bool) {
        self.init()
        self.action = action
        self.affectedObjectPrimaryKeys.append(objectsIn: affectedObjectPrimaryKeys)
        self.didAddExistingObject = didAddExistingObject
    }
}
/// Returns the oplog realm for a given user
func operationRealm(for user: User) -> Realm {
    try! Realm(configuration: Realm.Configuration(fileURL: Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent().appendingPathComponent("operations.\(user.id).realm"),
                                                  objectTypes: [Operation.self,
                                                                ListOperation.self,
                                                                SetOperation.self]))
}

// MARK: Utils

func randomString(of length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    var s = ""
    for _ in 0 ..< length {
        s.append(letters.randomElement()!)
    }
    return s
}

extension Object {
    var primaryKeyValue: String? {
        if objectSchema.primaryKeyProperty != nil {
            let pk = RLMDynamicGetByName(self, self.objectSchema.primaryKeyProperty!.name)
            return {
                switch self.objectSchema.primaryKeyProperty!.type {
                case .string:
                    return pk as? String
                case .objectId:
                    return (pk as! ObjectId).stringValue
                case .UUID:
                    return (pk as! UUID).uuidString
                case .int:
                    return String(pk as! Int)
                default: fatalError("invalid primary key type")
                }
            }()
        } else {
            return nil
        }
    }
}

extension RLMObject {
    var primaryKeyValue: String? {
        if objectSchema.primaryKeyProperty != nil {
            let pk = RLMDynamicGetByName(self, self.objectSchema.primaryKeyProperty!.name)
            return {
                switch self.objectSchema.primaryKeyProperty!.type {
                case .string:
                    return pk as? String
                case .objectId:
                    return (pk as! ObjectId).stringValue
                case .UUID:
                    return (pk as! UUID).uuidString
                case .int:
                    return String(pk as! Int)
                default: fatalError("invalid primary key type")
                }
            }()
        } else {
            return nil
        }
    }
}

extension AnyRealmValue {
    static var randomValue: AnyRealmValue {
        return [
            AnyRealmValue.uuid(UUID()),
            .int(Int.random(in: Int.min...Int.max)),
            .string(randomString(of: 256)),
            .objectId(ObjectId.generate()),
            .none,
            .double(Double.random(in: Double.leastNormalMagnitude...Double.greatestFiniteMagnitude)),
            .date(Date()),
            .data(Data())
        ].randomElement()!
    }
}

// MARK: Operations

/// Read all properties of all objects for a given realm
func readFromRealm(with configuration: RLMRealmConfiguration) throws {
    let realm = ObjectiveCSupport.convert(object: try RLMRealm(configuration: configuration))
    for type in realm.schema.objectSchema {
        realm.dynamicObjects(type.className).forEach { object in
            object.objectSchema.properties.forEach {
                _ = object[$0.name]
            }
        }
    }
}

/// Add a new random managed object to a given realm
func addToRealm(with configuration: RLMRealmConfiguration) throws {
    let realm = ObjectiveCSupport.convert(object: try RLMRealm(configuration: configuration))
    try realm.write {
        let schema = realm.schema.objectSchema.randomElement()!
        let object = generateObject(for: schema, fullSchema: realm.schema.objectSchema)
        if schema.primaryKeyProperty != nil {
            let opRealm = operationRealm(for: configuration.syncConfiguration!.user)
            let pk = object[schema.primaryKeyProperty!.name]
            let strPk: String = {
                switch schema.primaryKeyProperty!.type {
                case .string: return pk as! String
                case .objectId: return (pk as! ObjectId).stringValue
                case .UUID: return (pk as! UUID).uuidString
                case .int: return String(pk as! Int)
                default: fatalError()
                }
            }()
            try opRealm.write {
                opRealm.add(Operation(action: .add,
                                      objectName: schema.className,
                                      primaryKey: strPk))
            }
            realm.dynamicCreate(schema.className, value: object, update: .all)
        } else {
            realm.dynamicCreate(schema.className, value: object)
        }
    }
}

/// Remove a random object of each type for a given realm
func removeFromRealm(with configuration: RLMRealmConfiguration) throws {
    let realm = ObjectiveCSupport.convert(object: try RLMRealm(configuration: configuration))
    try realm.write {
        for type in realm.schema.objectSchema {
            if let object = realm.dynamicObjects(type.className).randomElement() {
                let opRealm = operationRealm(for: configuration.syncConfiguration!.user)
                try! opRealm.write {
                    opRealm.add(Operation(action: .remove,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue))
                }
                realm.delete(object)
            }
        }
    }
}

private func modifyArray(realm: inout Realm, object: Object, property: Property) {
    let opRealm = operationRealm(for: realm.configuration.syncConfiguration!.user)
    switch property.type {
    case .object:
        let oldValue = RLMDynamicGetByName(object, property.name) as! RLMArray<DynamicObject>
        switch ListAction.allCases.randomElement()! {
        case .add:
            let randomElement = realm.dynamicObjects(property.objectClassName!).randomElement()
            if randomElement == nil || Bool.random() {
                let generatedObject = generateObject(for: realm.schema.objectSchema.first { $0.className == property.objectClassName! }!,
                                               fullSchema: realm.schema.objectSchema)
                let newObject = realm.dynamicCreate(property.objectClassName!, value: generatedObject, update: .all)
                try! opRealm.write {
                    opRealm.add(Operation(action: .modify,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue,
                                          propertyModified: property.name,
                                          listOperation: ListOperation(action: .add, affectedObjectPrimaryKeys: [newObject.primaryKeyValue!],
                                                                       didAddExistingObject: false, indicesAffected: [])))
                }
                oldValue.add(newObject)
            } else {
                try! opRealm.write {
                    opRealm.add(Operation(action: .modify,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue,
                                          propertyModified: property.name,
                                          listOperation: ListOperation(action: .add, affectedObjectPrimaryKeys: [randomElement!.primaryKeyValue!], didAddExistingObject: true, indicesAffected: [])))
                }
                oldValue.add(randomElement!)
            }
        case .move:
            if oldValue.count > 0 {
                let idx1 = UInt.random(in: 0..<oldValue.count)
                let idx2 = UInt.random(in: 0..<oldValue.count)
                let affectedObject1 = oldValue.object(at: idx1)
                let affectedObject2 = oldValue.object(at: idx2)
                try! opRealm.write {
                    opRealm.add(Operation(action: .modify,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue,
                                          propertyModified: property.name,
                                          listOperation: ListOperation(action: .move, affectedObjectPrimaryKeys: [affectedObject1.primaryKeyValue!,
                                                                                                                  affectedObject2.primaryKeyValue!], didAddExistingObject: false, indicesAffected: [Int(idx1), Int(idx2)])))
                }
                oldValue.moveObject(at: idx1,
                                    to: idx2)
            }
        case .remove:
            if oldValue.count > 0 {
                let idx = UInt.random(in: 0..<oldValue.count)
                let affectedObject = oldValue.object(at: idx)
                try! opRealm.write {
                    opRealm.add(Operation(action: .modify,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue,
                                          propertyModified: property.name,
                                          listOperation: ListOperation(action: .remove, affectedObjectPrimaryKeys: [affectedObject.primaryKeyValue!], didAddExistingObject: false, indicesAffected: [Int(idx)])))
                }
                oldValue.removeObject(at: idx)
            }
        }
    case .int:
        let oldValue = RLMDynamicGetByName(object, property.name) as! RLMArray<NSNumber>
        switch ListAction.allCases.randomElement()! {
        case .add:
            let newObject = Int.random(in: Int.min ... Int.max)
            try! opRealm.write {
                opRealm.add(Operation(action: .modify,
                                      objectName: object.objectSchema.className,
                                      primaryKey: object.primaryKeyValue,
                                      propertyModified: property.name,
                                      listOperation: ListOperation(action: .add,
                                                                   affectedObjectPrimaryKeys: [],
                                                                   didAddExistingObject: false,
                                                                   indicesAffected: [])))
            }
            oldValue.add(NSNumber(integerLiteral: newObject))
        case .move:
            if oldValue.count > 0 {
                let idx1 = UInt.random(in: 0..<oldValue.count)
                let idx2 = UInt.random(in: 0..<oldValue.count)
                try! opRealm.write {
                    opRealm.add(Operation(action: .modify,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue,
                                          propertyModified: property.name,
                                          listOperation: ListOperation(action: .move, affectedObjectPrimaryKeys: [],
                                                                       didAddExistingObject: false, indicesAffected: [Int(idx1), Int(idx2)])))
                }
                oldValue.moveObject(at: idx1,
                                    to: idx2)
            }
        case .remove:
            if oldValue.count > 0 {
                let idx = UInt.random(in: 0..<oldValue.count)
                try! opRealm.write {
                    opRealm.add(Operation(action: .modify,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue,
                                          propertyModified: property.name,
                                          listOperation: ListOperation(action: .remove, affectedObjectPrimaryKeys: [],
                                                                       didAddExistingObject: false, indicesAffected: [Int(idx)])))
                }
                oldValue.removeObject(at: idx)
            }
        }
    default: break
    }
}

private func modifySet(realm: inout Realm, object: Object, property: Property) {
    let opRealm = operationRealm(for: realm.configuration.syncConfiguration!.user)
    switch property.type {
    case .object:
        let oldValue = RLMDynamicGetByName(object, property.name) as! RLMSet<Object>
        switch ListAction.allCases.randomElement()! {
        case .add:
            let randomElement = realm.dynamicObjects(property.objectClassName!).randomElement()

            if randomElement == nil || Bool.random() {
                let newObject = realm.dynamicCreate(property.objectClassName!)
                try! opRealm.write {
                    opRealm.add(Operation(action: .modify,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue,
                                          propertyModified: property.name,
                                          setOperation: SetOperation(action: .add, affectedObjectPrimaryKeys: [newObject.primaryKeyValue!], didAddExistingObject: false)))
                }
                oldValue.add(newObject)
            } else {
                try! opRealm.write {
                    opRealm.add(Operation(action: .modify,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue,
                                          propertyModified: property.name,
                                          setOperation: SetOperation(action: .add, affectedObjectPrimaryKeys: [randomElement!.primaryKeyValue!], didAddExistingObject: false)))
                }
                oldValue.add(randomElement!)
            }
        case .move:
            break
        case .remove:
            if oldValue.count > 0 {
                let object = oldValue.object(at: UInt.random(in: 0..<oldValue.count)) as! Object
                try! opRealm.write {
                    opRealm.add(Operation(action: .modify,
                                          objectName: object.objectSchema.className,
                                          primaryKey: object.primaryKeyValue,
                                          propertyModified: property.name,
                                          setOperation: SetOperation(action: .remove, affectedObjectPrimaryKeys: [object.primaryKeyValue!], didAddExistingObject: false)))
                }
                oldValue.remove(object)
            }
        }
    default: break
    }
}

/// For each type in a realm, modify all properties of a random object of a given realm
func modifyInRealm(with configuration: RLMRealmConfiguration) throws {
    var realm = ObjectiveCSupport.convert(object: try RLMRealm(configuration: configuration))
    // for each type in schema
    for type in realm.schema.objectSchema {
        try! realm.write {
            // modify all properties of a random object of each type
            if let object = realm.dynamicObjects(type.className).randomElement() {
                object.objectSchema.properties.forEach { property in
                    // Modifying the primaryKey is not supported in general,
                    // and modifying a map is not supported by the fuzz suite yet
                    if object.objectSchema.primaryKeyProperty?.name == property.name
                        || property.isMap {
                        return
                    }

                    if property.isArray {
                        modifyArray(realm: &realm, object: object, property: property)
                    } else if property.isSet {
                        // TODO: Uncomment when #5387 is fixed
                        // modifySet(realm: &realm, object: object, property: property)
                    } else {
                        let opRealm = operationRealm(for: configuration.syncConfiguration!.user)
                        guard !object.isInvalidated else { return }
                        switch property.type {
                        case .int:
                            let oldValue = RLMDynamicGetByName(object, property.name)
                            let newValue = Int.random(in: Int.min ... Int.max)
                            try! opRealm.write {
                                opRealm.add(Operation(action: .modify,
                                                      objectName: object.objectSchema.className,
                                                      primaryKey: object.primaryKeyValue,
                                                      propertyModified: property.name,
                                                      originalValue: oldValue == nil ? .none : .int(oldValue as! Int),
                                                      newValue: .int(newValue)))
                            }
                            RLMDynamicValidatedSet(object, property.name, newValue)
                        case .bool:
                            let oldValue = RLMDynamicGetByName(object, property.name)
                            let newValue = Bool.random()
                            try! opRealm.write {
                                opRealm.add(Operation(action: .modify,
                                                      objectName: object.objectSchema.className,
                                                      primaryKey: object.primaryKeyValue,
                                                      propertyModified: property.name,
                                                      originalValue: oldValue == nil ? .none : .bool(oldValue as! Bool),
                                                      newValue: .bool(newValue)))
                            }
                            RLMDynamicValidatedSet(object, property.name, newValue)
                        case .string:
                            let oldValue = RLMDynamicGetByName(object, property.name)
                            let newValue = randomString(of: 256)
                            try! opRealm.write {
                                opRealm.add(Operation(action: .modify,
                                                      objectName: object.objectSchema.className,
                                                      primaryKey: object.primaryKeyValue,
                                                      propertyModified: property.name,
                                                      originalValue: oldValue == nil ? .none : .string(oldValue as! String),
                                                      newValue: .string(newValue)))
                            }
                            RLMDynamicValidatedSet(object, property.name, newValue)
                        case .UUID:
                            let oldValue = RLMDynamicGetByName(object, property.name)
                            let newValue = UUID()
                            try! opRealm.write {
                                opRealm.add(Operation(action: .modify,
                                                      objectName: object.objectSchema.className,
                                                      primaryKey: object.primaryKeyValue,
                                                      propertyModified: property.name,
                                                      originalValue: oldValue == nil ? .none : .uuid(oldValue as! UUID),
                                                      newValue: .uuid(newValue)))
                            }
                            RLMDynamicValidatedSet(object, property.name, newValue)
                        case .objectId:
                            let oldValue = RLMDynamicGetByName(object, property.name)
                            let newValue = ObjectId.generate()
                            try! opRealm.write {
                                opRealm.add(Operation(action: .modify,
                                                      objectName: object.objectSchema.className,
                                                      primaryKey: object.primaryKeyValue,
                                                      propertyModified: property.name,
                                                      originalValue: oldValue == nil ? .none : .objectId(oldValue as! ObjectId),
                                                      newValue: .objectId(newValue)))
                            }
                            RLMDynamicValidatedSet(object, property.name, newValue)
                        case .object:
                            let oldValue = RLMDynamicGetByName(object, property.name)
                            var newValue: Object? = nil
                            if Bool.random() /* take random element from object type */ {
                                newValue = realm.dynamicObjects(property.objectClassName!).randomElement()
                            } else if Bool.random() /* create new object */ {
                                newValue = realm.dynamicCreate(property.objectClassName!,
                                                               value: generateObject(for: realm.schema.objectSchema.first { $0.className == property.objectClassName }!, fullSchema: realm.schema.objectSchema),
                                                               update: .all)
                            }
                            try! opRealm.write {
                                opRealm.add(Operation(action: .modify,
                                                      objectName: object.objectSchema.className,
                                                      primaryKey: object.primaryKeyValue,
                                                      propertyModified: property.name,
                                                      originalValue: oldValue == nil ? .none : .string((oldValue as! RLMObject).primaryKeyValue!),
                                                      newValue: newValue == nil ? .none : .string(newValue!.primaryKeyValue!)))
                            }
                            RLMDynamicValidatedSet(object, property.name, newValue)
                        case .date:
                            let oldValue = RLMDynamicGetByName(object, property.name)
                            let newValue = Date()
                            try! opRealm.write {
                                opRealm.add(Operation(action: .modify,
                                                      objectName: object.objectSchema.className,
                                                      primaryKey: object.primaryKeyValue,
                                                      propertyModified: property.name,
                                                      originalValue: oldValue != nil ? .date(oldValue as! Date) : .none,
                                                      newValue: .date(newValue)))
                            }
                            RLMDynamicValidatedSet(object, property.name, newValue)
                        case .any:
                            let oldValue = RLMDynamicGetByName(object, property.name)
                            let newValue = AnyRealmValue.randomValue
                            try! opRealm.write {
                                opRealm.add(Operation(action: .modify,
                                                      objectName: object.objectSchema.className,
                                                      primaryKey: object.primaryKeyValue,
                                                      propertyModified: property.name,
                                                      originalValue: oldValue as? AnyRealmValue ?? .none,
                                                      newValue: newValue))
                            }
                            RLMDynamicValidatedSet(object, property.name, newValue)
                        default:
                            break
                        }
                    }
                    guard !object.isInvalidated else { return }
                    RLMDynamicGetByName(object, property.name)
                }
            }
        }
    }
}

var workQueues = [
    DispatchQueue(label: "1"),
    DispatchQueue(label: "2"),
    DispatchQueue(label: "3"),
    DispatchQueue(label: "4"),
    DispatchQueue(label: "5"),
    DispatchQueue(label: "6"),
    DispatchQueue(label: "7"),
    DispatchQueue(label: "8")
]

// MARK: Tests

@available(macOS 12.0.0, *)
class SwiftFuzzTests: SwiftSyncTestCase {
    private let generatedSchema = generateSchema()
    override var schema: RLMSchema {
        generatedSchema
    }

    override class var defaultTestSuite: XCTestSuite {
        // async/await is currently incompatible with thread sanitizer and will
        // produce many false positives
        // https://bugs.swift.org/browse/SR-15444
        if RLMThreadSanitizerEnabled() {
            return XCTestSuite(name: "\(type(of: self))")
        }
        return super.defaultTestSuite
    }

    /// the FileHandle for the client logs
    static let handle = FileHandle(forWritingAtPath: Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent().appendingPathComponent("client_logs.txt").path)!

    func testCRUD() async throws {
        self.flexibleSyncApp.syncManager.errorHandler = { error, session in
            print(error.localizedDescription)
        }
        FileManager.default.createFile(atPath: Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent().appendingPathComponent("client_logs.txt").path, contents: Data())

        self.flexibleSyncApp.syncManager.logLevel = .all
        self.flexibleSyncApp.syncManager.logger = { level, message in
            try! SwiftFuzzTests.handle.write(contentsOf: message.data(using: .utf8)!)
            try! SwiftFuzzTests.handle.write(contentsOf: "\n".data(using: .utf8)!)
        }
        func flxRealm() async throws -> RLMRealm {
            let username = "\(randomString(of: 24))@icloud.com"
            try await self.flexibleSyncApp.emailPasswordAuth.registerUser(email: username, password: "kingkong")
            let config = try await self.flexibleSyncApp.login(credentials: .emailPassword(email: username, password: "kingkong")).flexibleSyncConfiguration()
            let configuration = RLMRealmConfiguration()
            configuration.customSchema = generatedSchema
            configuration.syncConfiguration = ObjectiveCSupport.convert(object:  config.syncConfiguration!)
            let rlmRealm = try RLMRealm(configuration: configuration)
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let rlmRealm = try! RLMRealm(configuration: configuration)
                let subscriptions = rlmRealm.subscriptions
                subscriptions.write({
                    rlmRealm.schema.objectSchema.forEach {
                        subscriptions.addSubscription(withClassName: $0.className, predicate: NSPredicate(format: "TRUEPREDICATE"))
                    }
                }, onComplete: { _ in
                    continuation.resume()
                })
            }
            return rlmRealm
        }

        let realm1 = try await flxRealm()
        let realm2 = try await flxRealm()
        let realm3 = try await flxRealm()

        for i in 0..<1000 {
            print(i)
            print("setting up operations")
            [realm1, realm2, realm3].map { realm -> [DispatchWorkItem] in
                let workItems = (0..<1000).map { _ in
                    DispatchWorkItem {
                        switch RealmAction.allCases.randomElement()! {
                        case .add:
                            try! addToRealm(with: realm.configuration)
                        case .remove:
                            try! removeFromRealm(with: realm.configuration)
                        case .modify:
                            try! modifyInRealm(with: realm.configuration)
                        case .read:
                            try! readFromRealm(with: realm.configuration)
                        }
                    }
                }
                workItems.forEach { item in
                    let first = workQueues.removeFirst()
                    first.async(execute: item)
                    workQueues.append(first)
                }
                print("waiting")
                return workItems
            }.flatMap { $0 }
            .forEach {
                $0.wait()
            }
        }
    }

    // copypasta from above but for PBS, should DRY it up
    func testCRUDPBS() async throws {
        self.app.syncManager.errorHandler = { error, session in
            fatalError(error.localizedDescription)
        }
        FileManager.default.createFile(atPath: Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent().appendingPathComponent("client_logs.txt").path, contents: Data())
        self.app.syncManager.logLevel = .all
        self.app.syncManager.logger = { level, message in
            try! SwiftFuzzTests.handle.write(contentsOf: message.data(using: .utf8)!)
            try! SwiftFuzzTests.handle.write(contentsOf: "\n".data(using: .utf8)!)
        }
        func flxRealm() async throws -> RLMRealm {
            let username = "\(randomString(of: 24))@icloud.com"
            try await self.app.emailPasswordAuth.registerUser(email: username, password: "kingkong")
            let config = try await self.app.login(credentials: .emailPassword(email: username, password: "kingkong")).configuration(partitionValue: "foo")
            let configuration = RLMRealmConfiguration()
            configuration.customSchema = generatedSchema
            configuration.syncConfiguration = ObjectiveCSupport.convert(object:  config.syncConfiguration!)
            return try RLMRealm(configuration: configuration)
        }

        let realm1 = try await flxRealm()
        let realm2 = try await flxRealm()
        let realm3 = try await flxRealm()

        for i in 0..<1000 {
            print(i)
            print("setting up operations")
            [realm1, realm2, realm3].map { realm -> [DispatchWorkItem] in
                let workItems = (0..<1000).map { _ in
                    DispatchWorkItem {
                        switch RealmAction.allCases.randomElement()! {
                        case .add:
                            try! addToRealm(with: realm.configuration)
                        case .remove:
                            try! removeFromRealm(with: realm.configuration)
                        case .modify:
                            try! modifyInRealm(with: realm.configuration)
                        case .read:
                            try! readFromRealm(with: realm.configuration)
                        }
                    }
                }
                workItems.forEach { item in
                    let first = workQueues.removeFirst()
                    first.async(execute: item)
                    workQueues.append(first)
                }
                print("waiting")
                return workItems
            }.flatMap { $0 }
            .forEach {
                $0.wait()
            }
        }
    }

    // Bug replication discovered while testing
    func testSetAddAndDelete() {
        let realm = try! Realm()
        let collectionObject = SwiftCollectionSyncObject()
        let personObject = SwiftPerson()
        try! realm.write {
            realm.add(collectionObject)
            realm.add(personObject)
        }
        try! realm.write {
            collectionObject.objectSet.insert(personObject)
        }
        try! realm.write {
            realm.delete(collectionObject)
        }
        try! realm.write {
            realm.delete(personObject)
        }
    }
}

#endif

//import Foundation
//
////public struct HashedType : Reflectable {
////    public let hashValue: Int
////    
////    public init(_ type: Any.Type)
////    {
////        hashValue = unsafeBitCast(type, to: Int.self)
////    }
////    
////    public init<T>(_ pointer: UnsafePointer<T>)
////    {
////        hashValue = pointer.hashValue
////    }
////    
////    public static func == (lhs: HashedType, rhs: HashedType) -> Bool
////    {
////        return lhs.hashValue == rhs.hashValue
////    }
////    
////    public func hash(into hasher: inout Hasher) {
////        hasher.combine(hashValue)
////    }
////}
////
//////protocol Reflectable : _DefaultConstructible { }
////
////extension Decodable
////{
////    static var keyPaths: [String : AnyKeyPath]? {
////        return KeyPathCache.keyPaths(for: Self.self)
////    }
////    
////    fileprivate subscript(checkedMirrorDescendant key: String) -> Any
////    {
////        let hashedType = HashedType(type(of: self))
////        
////        return KeyPathCache.mirrors[hashedType]!.descendant(key)!
////    }
////}
////
////class KeyPathCache
////{
////    fileprivate static var mirrors: [HashedType : Mirror] = .init()
////    
////    private static var items: [HashedType : [String : AnyKeyPath]] = .init()
////    
////    static func keyPaths<T : Decodable>(for type: T.Type) -> [String : AnyKeyPath]?
////    {
////        let hashedType = HashedType(type)
////        
////        return items[hashedType]
////    }
////    
////    static func register<T : Decodable & _DefaultConstructible>(type: T.Type)
////    {
////        let hashedType = HashedType(type)
////        
////        if mirrors.keys.contains(hashedType)
////        {
////            return
////        }
////        
////        let mirror = Mirror(reflecting: T())
////        
////        mirrors[hashedType] = mirror
////        
////        var keyPathsDictionary: [String : AnyKeyPath] = .init()
////        
////        for case (let key?, _) in mirror.children
////        {
////            keyPathsDictionary[key] = \T.[checkedMirrorDescendant: key] as PartialKeyPath
////        }
////        
////        items[hashedType] = keyPathsDictionary
////    }
////}
//
//private extension Decodable {
////    subscript(checkedMirrorDescendant key: String) -> Any {
////      Mirror(reflecting: <#T##Any#>)(type(of: self))
////      
////      return KeyPathCache.mirrors[hashedType]!.descendant(key)!
////    }
//}
//
////@available(macOS 14.0.0, *)
////struct GroupBy<Value: Codable>: Aggregation {
////
////}
//
//
//class Person: Object, Codable {
//    @Persisted var _id: ObjectId
//    @Persisted var firstName: String
//    @Persisted var lastName: String
//    @Persisted var age: Int
//}
//
//protocol AccumulableProperty: Codable {
//    associatedtype Value
//}
//
//open class AggregateObject<Aggregable>: ObjectBase {
//    @propertyWrapper struct Concat<Value> where Value: _DefaultConstructible {
//        var wrappedValue: Value = .init()
//        init(_ keyPaths: KeyPath<Aggregable, Value>...) {
//            self.wrappedValue = .init()
//        }
//    }
//    final public override class func shouldIncludeInDefaultSchema() -> Bool {
//        false
//    }
//}
//// MARK: Aggregation
//protocol Aggregation<Aggregable> {
//    associatedtype Aggregable: ObjectBase //= Self.Body.Aggregable where Aggregable: ObjectBase
//    associatedtype Body: Aggregation
//    
//    @AggregationBuilder<Aggregable> var aggregation: Self.Body { get }
//}
//
//func get<each V, T>(_ idx: Int, _ tuple: repeat each V) -> T {
//    func map<C>(_ tuple: C, array: inout [T]) {
//        array.append(unsafeBitCast(tuple, to: T.self))
//    }
//    var array = [T]()
//    repeat map(each tuple, array: &array)
//    return array[idx]
//}
//
//func apply<F, each V>(_ f: ((repeat each V) -> F), _ t: repeat each V) -> F {
//    f(repeat each t)
//}
//
////extension Dictionary: Aggregation where Key == String {
//////    typealias Body = Self
////    var aggregation: some Aggregation {
////        self
////    }
////}
//
//@dynamicCallable struct Field {
//    func dynamicallyCall<V>(withKeywordArguments: KeyValuePairs<String, V>) {
//        
//    }
//}
//
//struct _AddFields<From: ObjectBase>: Aggregation {
//    @dynamicMemberLookup class _To: ObjectBase {
//        subscript<V>(dynamicMember member: KeyPath<From, V>) -> V {
//            fatalError()
//        }
//    }
////    static func callAsFunction
//    func dynamicallyCall(withKeywordArguments: KeyValuePairs<String, Any>) {
//        
//    }
//    
//    init(withKeywordArguments: KeyValuePairs<String, Operator<From>>) {
//        
//    }
//    typealias Aggregable = From
//    var aggregation: some Aggregation<From> {
//        self
//    }
//    
//    var output: _To {
//        fatalError()
//    }
//}
//@dynamicCallable protocol DynamicInit {
//    func dynamicallyCall(withKeywordArguments: KeyValuePairs<String, Any>)
//}
//@dynamicCallable struct _A<From: ObjectBase> {
//    func dynamicallyCall(withKeywordArguments: KeyValuePairs<String, Operator<From>>) -> _AddFields<From> {
//        fatalError()
//    }
////    func dynamicallyCall<each T>(withKeywordArguments: repeat KeyValuePairs<String, each T>) -> _AddFields<From> {
////        fatalError()
////    }
//}
//
//extension Aggregation {
//    var AddFields: _A<Aggregable> {
//        _A()
//    }
//}
//let AddFields = _A()
//
//func map<each T, V>(_ components: repeat each T, to: V.Type) -> [V] {
//    func map<C>(_ tuple: C, array: inout [V]) {
//        array.append(unsafeBitCast(tuple, to: V.self))
//    }
//    var array = [V]()
//    repeat map(each components, array: &array)
//    return array
//}
//
//struct BaseBlock<From: ObjectBase>: Aggregation {
//    typealias Aggregable = From
//    var aggregation: some Aggregation<From> {
//        self
//    }
//    
//    func fold<A: Aggregation>(_ aggregation: A) -> Self {
//        fatalError()
//    }
//}
//
//@resultBuilder struct AggregationBuilder<From: ObjectBase> {
////    
////    static func buildBlock<A: Aggregation>(_ component: A) -> BaseBlock<From> where A.Aggregable == From {
////        var builder = BaseBlock<From>()
////        builder = builder.fold(component)
////        return builder
////    }
//    
//    static func buildBlock<each A: Aggregation>(_ components: repeat (each A)) -> BaseBlock<From> {
//        var builder = BaseBlock<From>()
//        for component in map(repeat each components,
//                             to: (any Aggregation).self) {
//            builder = builder.fold(component)
//        }
//        return builder
//    }
//    static func buildExpression(_ expression: Any) -> BaseBlock<From> {
//        fatalError()
//    }
//}
//
////extension Query where T == String {
////    static func +(lhs: Query<String>, rhs: Query<String>) -> Query<Bool> {
////        
////    }
////}
//struct _Match<From: ObjectBase>: Aggregation {
//    typealias Aggregable = From
//    init(_ block: (Query<From>) -> Query<Bool>) {
//        
//    }
//    var aggregation: some Aggregation<From> {
//        self
//    }
//}
//extension Aggregation {
//    var Match: ((Query<Aggregable>) -> Query<Bool>) -> _Match<Aggregable> {
//        _Match<Aggregable>.init
//    }
//}
//enum Operator<From: ObjectBase> {
//    case concat(_ keyPaths: PartialKeyPath<From>)
//}
//
//struct PersonAggregation: Aggregation {
//    typealias Aggregable = Person
//    class AddFieldsStage: AggregateObject<Person> {
//        @Concat(\.firstName, \.lastName) var name: String
//    }
//    var aggregation: some Aggregation<Person> {
//        Match {
//            $0.age > 18
//        }
//        AddFields(name: .concat(\.firstName))
//    }
//}

import Foundation
import RealmSwift
import Realm.Private

struct Test<Value>: Codable, Equatable where Value: Codable, Value: Equatable {
    struct Valid: Codable, Equatable {
        enum CodingKeys: String, CodingKey {
            case description, canonicalExtJSON = "canonical_extjson"
        }
        let description: String
        let canonicalExtJSON: String
        var swiftValue: Value?
    }
    
    enum CodingKeys: String, CodingKey {
        case description, testKey = "test_key", valid
    }
    
    let description: String
    let testKey: String?
    private(set) var valid: [Valid]
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Test.CodingKeys.self)
        self.description = try container.decode(String.self, forKey: .description)
        self.testKey = try container.decode(String.self, forKey: .testKey)
        self.valid = try container.decode([Valid].self, forKey: .valid)
        for idx in 0..<self.valid.count {
            do {
                let value = try ExtJSONDecoder().decode([String: Value].self,
                                                        from: self.valid[idx].canonicalExtJSON.data(using: .utf8)!)
                if let testKey = testKey {
                    self.valid[idx].swiftValue = value[testKey]
                }
            } catch {
                if let value = try? ExtJSONDecoder().decode(Value.self,
                                                            from: self.valid[idx].canonicalExtJSON.data(using: .utf8)!) {
                    self.valid[idx].swiftValue = value
                }
            }
        }
    }
}

protocol Answer<Value> {
    associatedtype Value: Codable, Equatable
    
    var answer: () -> Value { get }
    var line: UInt { get }
    init(_ answer: @escaping @autoclosure () -> Value, line: UInt)
}

extension Answer {
    func compare(to answer: Value) {
        switch answer {
        case let value as Data:
            XCTAssertEqual(unsafeBitCast(self.answer(), to: Data.self).base64EncodedString(),
                           value.base64EncodedString(),
                           line: line)
        case let value as Date:
            XCTAssertEqual((self.answer() as! Date).timeIntervalSince1970,
                           value.timeIntervalSince1970, line: line)
        default:
            XCTAssertEqual(self.answer(), answer, line: line)
        }
    }
    
    func compare(to answer: Value) where Value == Data {
        XCTAssertEqual(self.answer().base64EncodedString(),
                       answer.base64EncodedString(),
                       line: line)
    }
}

private struct _Answer<Value>: Answer where Value: Codable, Value: Equatable {
    let answer: () -> (Value)
    let line: UInt

    init(_ answer: @escaping @autoclosure () -> Value, line: UInt) {
        self.answer = answer
        self.line = line
    }
    
    func compare(to answer: Value) {
        switch answer {
        case let value as Data:
            XCTAssertEqual(unsafeBitCast(self.answer(), to: Data.self).base64EncodedString(),
                           value.base64EncodedString(),
                           line: line)
        default:
            XCTAssertEqual(self.answer(), answer, line: line)
        }
    }
}

private struct Answers<Value>: Collection, ExpressibleByArrayLiteral where Value: Codable, Value: Equatable {
    private let array: [Element]
    
    init(_ array: [Element]) {
        self.array = array
    }
    init(arrayLiteral elements: Element...) {
        self.array = elements
    }
    
    typealias ArrayLiteralElement = Element
    typealias Element = _Answer<Value>
    typealias Index = Int
    
    
    
    var startIndex: Int { array.startIndex }
    var endIndex: Int { array.endIndex }
    
    subscript(position: Int) -> _Answer<Value> {
        array[position]
    }
    func index(after i: Int) -> Int {
        array.index(after: i)
    }
    
    static func +(_ lhs: Self, _ rhs: Self) -> Self {
        Self(lhs.array + rhs.array)
    }
}

//class Answers<Body> where Body: Codable, Body: Equatable {
//    var answers: [Answer<Body>] = []
//}


//@resultBuilder private protocol AnswerBuilder<Body> {
//    associatedtype Body: Answers
//    static func buildPartialBlock(first: @escaping @autoclosure () -> Body.Element.Value) -> Body
//}
private protocol ExtJSONTestView {
    associatedtype Value: Codable, Equatable
    
    static var testName: String { get }
    @AnswerBuilder var body: Answers<Value> { get }
}

@resultBuilder private struct AnswerBuilder {
    static func buildPartialBlock<Value>(first: @escaping @autoclosure () -> Value
                                                 , line: UInt = #line
    ) -> Answers<Value> {
        [_Answer(first(), line: line)]
    }
    static func buildPartialBlock<Value>(accumulated: Answers<Value>,
                                                 next: @escaping @autoclosure () -> Value
                                  , line: UInt = #line
    ) -> Answers<Value> {
        (accumulated + [_Answer(next(), line: line)])
    }
    static func buildPartialBlock(first: UInt = #line) -> [UInt] {
        [first]
    }
    static func buildPartialBlock(accumulated: [UInt], next: UInt = #line) -> [UInt] {
        accumulated + [next]
    }
}

final class ExtJSONCorpusTestCase: XCTestCase {
    private static func run<A: Answer>(test: Test<A.Value>.Valid,
                                       answer: A,
                                       line: UInt) throws {
        answer.compare(to: test.swiftValue!)
        let encoder = ExtJSONEncoder()
        let testValue = try encoder.encode(test.swiftValue)
        let answer = try encoder.encode(answer.answer())
//        print("Comparing \(test.swiftValue) to \(answer.answer())")
        XCTAssertEqual(testValue,
                       answer,
                       line: line)
    }
    
    
    private static func run<A>(test: String,
                               answers: Answers<A>,
                               lossy: Bool = false,
                               function: String = #function,
                               line: UInt = #line) throws {
#if SWIFT_PACKAGE
        let url = Bundle.module.url(forResource: "BsonCorpus/\(test)", withExtension: "json")!
#else
        let url = Bundle(for: Self.self).url(forResource: "BsonCorpus/\(test)", withExtension: "json")!
        #endif
        let data = try Data(contentsOf: url)
        let test: Test = try ExtJSONDecoder().decode(Test<A>.self, from: data)
        
        for (test, answer) in zip(test.valid, answers) {
            try run(test: test, answer: answer, line: answer.line)
        }
    }
    
    private let testViews: [any ExtJSONTestView] = [
        BinaryTestView(),
        ArrayTest(),
        BooleanTest(),
        DateTest()
    ]
    
    func testCorpus() throws {
        func test<E: ExtJSONTestView>(_ e: E) throws {
            try Self.run(test: E.testName, answers: e.body)
        }
        try testViews.forEach { try test($0) }
    }
}

private struct BinaryTestView: ExtJSONTestView {
    static var testName: String { "binary" }
    var body: Answers<Data> {
        Data()
        Data()
        Data(base64Encoded: "//8=")!
        Data(base64Encoded: "//8=")!
        Data(base64Encoded: "//8=")!
        Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!
        Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!
        Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!
        Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!
        Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!
        Data(base64Encoded: "c//SZESzTGmQ6OfR38A11A==")!
        Data(base64Encoded: "//8=")!
    }
}

struct ArrayTest: ExtJSONTestView {
    static var testName: String { "array" }
    fileprivate var body: Answers<[Int]> {
        [Int]()
        [10]
        [10]
        [10]
        [10, 20]
    }
}

private struct BooleanTest: ExtJSONTestView {
    static var testName: String { "boolean" }
    
    var body: Answers<Bool> {
        true
        false
    }
}

private struct DateTest: ExtJSONTestView {
    static var testName: String { "datetime" }
    var body: Answers<Date> {
        Date(timeIntervalSince1970: 0)
        Date(timeIntervalSince1970: 1356351330501)
        Date(timeIntervalSince1970: -284643869501)
        Date(timeIntervalSince1970: 253402300800000)
        Date(timeIntervalSince1970: 1356351330001)
    }
}
class MyObject: Object, Codable {
    @Persisted(primaryKey: true) var _id: UUID
    
    convenience init(_id: UUID) {
        self.init()
        self._id = _id
    }
//    let name: String
//    let age: Int
}

class T: TestCase {
    @MainActor func testMyObject() throws {
        let configuration = Realm.Configuration(objectTypes: [MyObject.self])
        self.measure {
            let realm = try! Realm(configuration: configuration)
            let objects = (0..<100_000).map { _ in
                MyObject(_id: UUID())
            }
            try! realm.write {
                objects.forEach { realm.add($0) }
            }
//            var sb = "_id == \"\(objects.first!._id)\""
//            for object in objects.dropFirst() {
//                sb.append(" OR ")
//                sb.append("_id == \"\(object._id)\"")
//            }
            let ids = objects.map(\._id)
            let results = realm.objects(MyObject.self).filter(NSPredicate(format: "_id IN %@", ids))
//            for object in results {
            try! realm.write {
                results.clear()
            }
//            }
        }
        XCTAssert(try Realm.deleteFiles(for: configuration))
    }
}

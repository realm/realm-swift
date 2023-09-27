import Foundation

extension Scanner {
    package func scanUpToTokens(_ tokens: [Token]) -> Token? {
        if let token = Token(rawValue: string[currentIndex]), tokens.contains(token) {
            self.currentIndex = currentIndex
            return token
        }
        repeat {
            if let token = scanCharacter().map(Token.init), let token = token, tokens.contains(token) {
                self.currentIndex = string.index(before: currentIndex)
                return token
            }
        } while !isAtEnd
        return nil
    }
}

package enum Token : Character {
    case openBrace = "{"
    case closeBrace = "}"
    case openBracket = "["
    case closeBracket = "]"
    case quotation = "\""
    case colon = ":"
    case comma = ","
    
    func view(for json: String, 
              at position: String.Index,
              objectType: (any ObjectSyntaxView.Type)?,
              allowedObjectTypes: [any SyntaxView.Type],
              fields: [String : any SyntaxView.Type] = [:]) -> (any SyntaxView)? {
        switch self {
        case .openBrace: RawObjectSyntaxView(json: json, at: position, allowedObjectTypes: allowedObjectTypes)
        case .closeBrace: nil
        case .quotation: nil
        case .colon: nil
        case .comma, .closeBracket: nil
        case .openBracket: try? RawArraySyntaxView(json: json, at: position, allowedObjectTypes: allowedObjectTypes)
        }
    }
}

// Literal Syntax Views
// - String
// - Int
// - Double
// Structural Syntax Views
// - Object
// - Array
// - Field
// - FieldList
// Object Syntax Views
// - IntObject
// - DoubleObject
// - <Raw>Object
// - <Derived>Object

@resultBuilder struct AnyRawDocumentRepresentableBuilder {
    static func buildBlock(_ components: any RawDocumentRepresentable...) -> [any RawDocumentRepresentable] {
        components
    }
    static func buildBlock<T : RawDocumentRepresentable>(_ components: T) -> T {
        components
    }
    static func buildEither<T : RawDocumentRepresentable>(first component: T) -> T {
        buildPartialBlock(first: component)
    }
    static func buildEither<T : RawDocumentRepresentable>(second component: T) -> T {
        component
    }
    static func buildPartialBlock<T : RawDocumentRepresentable>(first: T) -> T {
        first
    }
    static func buildPartialBlock<each T, V: RawDocumentRepresentable>(accumulated: repeat (each T),
                                                                       next: V) -> (repeat (each T), V) {
        return (repeat each accumulated, next)
    }
    
    static func buildOptional<T : RawDocumentRepresentable>(_ component: T?) -> T? {
        component
    }
}

public protocol LiteralSyntaxView : SyntaxView {
//    init(from value: RawDocumentValue)
//    var rawDocumentRepresentable: any RawDocumentRepresentable { get }
}

extension Int : RawDocumentRepresentable {
    public struct SyntaxView : ObjectSyntaxView {
        public typealias RawDocumentValue = Int
        public let rawDocumentRepresentable: Int
        public let rawObjectSyntaxView: RawObjectSyntaxView
        
        public init(from value: Int) {
            self.rawObjectSyntaxView = ["$numberLong": StringLiteralSyntaxView(stringLiteral: "\(value)")]
            self.rawDocumentRepresentable = value
        }
        
        public init(from view: RawObjectSyntaxView) throws {
            self.rawObjectSyntaxView = view
            guard let view = view["$numberLong"] as? StringLiteralSyntaxView,
                let int = Int(view.string) else {
                throw BSONError.missingKey("$numberLong")
            }
            self.rawDocumentRepresentable = int
        }
    }
}

package struct IntLiteralSyntaxView : LiteralSyntaxView, ExpressibleByIntegerLiteral {
    public let startIndex: String.Index
    public let rawJSON: String
    
    public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any SyntaxView.Type] = []) {
        self.rawJSON = json
        self.startIndex = startIndex
    }
    
    package init(from value: Int) {
        self.init(integerLiteral: value)
    }
    
    package init(integerLiteral value: IntegerLiteralType) {
        self.rawJSON = "\(value)"
        self.startIndex = rawJSON.startIndex
    }
    
    package var description: String {
        String(self.rawJSON[startIndex..<endIndex])
    }
    
    package var integer: IntegerLiteralType {
        let scanner = self.scanner()
        return scanner.scanInt()!
    }
    
    package var rawDocumentRepresentable: Int {
        integer
    }
    
    package var endIndex: String.Index {
        let scanner = self.scanner()
        _ = scanner.scanInt()
        return scanner.currentIndex
    }
}


//@BSONCodable public struct DBRef {
//    public let collectionName: String
//    public let _id: any RawDocumentRepresentable
//}
//
//public struct DBRefSyntaxView : ObjectSyntaxView {
//    public init?(from view: RawObjectSyntaxView) {
//        view.fieldList.fields.first(where: { $0.key.string == "$ref" }) {
//            
//        }
//    }
//    
//    public var rawJSON: String
//    
//    public static var fields: [String : any SyntaxView.Type] {
//        ["$ref": StringLiteralSyntaxView.self,
//        "$id": AnyValueSyntaxView.self]
//    }
//    
//    public var startIndex: String.Index {
//        objectView.startIndex
//    }
//    
//    public var endIndex: String.Index {
//        objectView.endIndex
//    }
//    
//    let collectionName: StringLiteralSyntaxView
//    let _id: AnyValueSyntaxView
//    private let allowedObjectTypes: [ObjectSyntaxViewProtocol.Type]
//    private let objectView: ObjectSyntaxView
//    
//    public init(dbRef: DBRef) {
//        self.collectionName = StringLiteralSyntaxView(stringLiteral: dbRef.collectionName)
//    }
//    
//    public init?(from objectView: ObjectSyntaxView) throws {
//        self.objectView = objectView
//    }
//    
//    public init(json: String,
//                at startIndex: String.Index,
//                allowedObjectTypes: [ObjectSyntaxViewProtocol.Type]) {
//        
//    }
//    
//    public var rawDocumentRepresentable: any RawDocumentRepresentable {
//        fatalError()
////        allowedObjectTypes.first(where: {"\($0)" == collectionName.string}).map {
////            $0.init(from: objectView)?.rawDocumentRepresentable
////        }
//    }
//    
//    public var description: String {
//        objectView.description
//    }
//}



//public protocol ObjectSyntaxViewProtocol : SyntaxView {
//    associatedtype RawDocumentValue : RawDocumentObjectRepresentable
//    init?(from objectView: ObjectSyntaxView) throws
//    var value: RawDocumentValue { get }
//    static var fields: [String : any SyntaxView.Type] { get }
//}
//
//extension ObjectSyntaxViewProtocol {
//    public func `as`<View>(_ type: View.Type) -> View? where View : SyntaxView {
//        if let type = (type as? any ObjectSyntaxViewProtocol.Type), let self = self as? ObjectSyntaxView {
//            return try? type.init(from: self) as? View
//        } else if type is Self.Type {
//            return self as? View
//        }
//        return nil
//    }
//}
//
//
//extension ObjectSyntaxViewProtocol {
//    public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any ObjectSyntaxViewProtocol.Type] = []) {
//        var view = ObjectSyntaxView(for: json, at: startIndex)
//        view.allowedObjectTypes = allowedObjectTypes
//        view.fields = Self.fields
//        view.objectType = Self.self
//        try! self.init(from: view)!
//    }
//}


public struct BoolSyntaxView : LiteralSyntaxView, ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    
    public var startIndex: String.Index
    
    public var endIndex: String.Index {
        let scanner = scanner()
        if let `true` = scanner.scanString("true") { return scanner.currentIndex }
        else if let `false` = scanner.scanString("false") { return scanner.currentIndex }
        else { fatalError() }
    }
    
    public let rawJSON: String
    public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any SyntaxView.Type] = []) {
        self.rawJSON = json
        self.startIndex = startIndex
        let scanner = Scanner(string: json)
        scanner.currentIndex = startIndex
        if let `true` = scanner.scanString("true") { boolean = true }
        else if let `false` = scanner.scanString("false") { boolean = false }
        else { fatalError() }
    }
    private let boolean: Bool
    public init(booleanLiteral value: Bool) {
        self.boolean = value
        self.rawJSON = "\(value)"
        startIndex = rawJSON.startIndex
    }
    public init(from value: Bool) {
        self.init(booleanLiteral: value)
    }
    public var rawDocumentRepresentable: Bool {
        boolean
    }
    
    public var description: String {
        "\(boolean)"
    }
}

public let defaultSchema: [any SyntaxView.Type] = _defaultSchema()

import Realm.Private


//@resultBuilder package struct SyntaxViewBuilder : SyntaxView {
//    package var startIndex: String.Index {
//        syntaxView.startIndex
//    }
//    
//    package var endIndex: String.Index {
//        syntaxView.endIndex
//    }
//    
//    package var rawJSON: String {
//        syntaxView.rawJSON
//    }
//    
//    package init(json: String,
//         at startIndex: String.Index,
//         allowedObjectTypes: [any RawDocumentRepresentable.Type]) {
//        fatalError()
//    }
//    
//    package var rawDocumentRepresentable: any RawDocumentRepresentable {
//        syntaxView.rawDocumentRepresentable
//    }
//    
//    package var description: String {
//        syntaxView.description
//    }
//    
//    public static func buildBlock(_ components: any SyntaxView) -> any SyntaxView {
//        components
//    }
//    public static func buildOptional(_ component: (any SyntaxView)?) -> any SyntaxView {
//        component!
//    }
//    static func buildEither(first component: any SyntaxView) -> any SyntaxView {
//        component
//    }
//    static func buildEither(second component: any SyntaxView) -> any SyntaxView {
//        component
//    }
//    private let syntaxView: any SyntaxView
//    init(@SyntaxViewBuilder _ syntaxViewBuilder: () -> any SyntaxView) {
//        self.syntaxView = syntaxViewBuilder()
//    }
//}

extension ObjectBase {
    fileprivate static var syntaxView: (any SyntaxView.Type)? {
        guard let view = (Self() as? any RawDocumentRepresentable) else {
            return nil
        }
        return view.syntaxViewType
    }
}

private func _defaultSchema() -> [any SyntaxView.Type] {
    [
        Int.SyntaxView.self, ObjectId.SyntaxView.self, Double.SyntaxView.self
    ] + (Realm.Configuration.defaultConfiguration.objectTypes.map {
        $0.compactMap {
            $0.syntaxView
        } 
    } ?? [])
}


package struct ExtJSON {
    public struct Configuration {
        let objectType: (any ObjectSyntaxView.Type)?
        let fields: [String: any SyntaxView.Type]
        public let linkDepth: UInt8
        public let schema: [any SyntaxView.Type]
    }
    private let extJSON: String
    private let objectType: (any ObjectSyntaxView.Type)?
    private let fields: [String: any SyntaxView.Type]
    public let configuration: Configuration
    
    public init(extJSON: String) {
        self.extJSON = extJSON
        self.objectType = nil
        self.fields = [:]
        self.configuration = .init(objectType: objectType, fields: fields, linkDepth: 5, schema: defaultSchema)
    }
    
    public init<R : RawDocumentRepresentable>(_ type: R.Type, extJSON: String) where R.SyntaxView : ObjectSyntaxView {
        self.extJSON = extJSON
        self.objectType = R.SyntaxView.self
        self.fields = [:]// R.SyntaxView.fields
        self.configuration = .init(objectType: objectType, fields: fields, linkDepth: 5, schema: defaultSchema)
    }
    
    package func parse() -> any SyntaxView {
        guard let token = extJSON.first.map(Token.init),
              let view = token?.view(for: extJSON, at: extJSON.startIndex, objectType: objectType, allowedObjectTypes: configuration.schema, fields: fields) else {
            fatalError("Malformed JSON")
        }
        return view
    }
}

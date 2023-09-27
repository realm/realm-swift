import Foundation

public protocol ObjectSyntaxView : SyntaxView where RawDocumentValue: RawDocumentRepresentable, RawDocumentValue.SyntaxView == Self {
    
    init(from view: RawObjectSyntaxView) throws
    var rawDocumentRepresentable: RawDocumentValue { get }
    var rawObjectSyntaxView: RawObjectSyntaxView { get }
}

extension ObjectSyntaxView {
    public var rawJSON: String {
        self.rawObjectSyntaxView.rawJSON
    }
    public var startIndex: String.Index {
        self.rawObjectSyntaxView.startIndex
    }
    public var endIndex: String.Index {
        self.rawObjectSyntaxView.endIndex
    }
    public var description: String {
        self.rawObjectSyntaxView.description
    }
    public init(json: String,
                at startIndex: String.Index,
                allowedObjectTypes: [any SyntaxView.Type]) throws {
        try self.init(from: RawObjectSyntaxView(json: json,
                                                at: startIndex,
                                                allowedObjectTypes: allowedObjectTypes))
    }
}

public struct RawObjectSyntaxView : LiteralSyntaxView,
                                        ExpressibleByDictionaryLiteral,
                                        ExpressibleByStringLiteral,
                                    Sequence {
    public typealias StringLiteralType = String
    
    public typealias Key = String
    public typealias Value = any SyntaxView
    public typealias Element = (String, any SyntaxView)
    
    package struct FieldSyntaxView {
        public let rawJSON: String
        public let startIndex: String.Index
        private let allowedObjectTypes: [any SyntaxView.Type]
        private func scanner() -> Scanner {
            let scanner = Scanner(string: rawJSON)
            scanner.currentIndex = startIndex
            return scanner
        }
        public var description: String {
            """
            \(key):\(value)
            """
        }
        fileprivate var fields: [String : any SyntaxView.Type] = [:]
        public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any SyntaxView.Type] = []) {
            fatalError()
        }
        package init(json: String, at position: String.Index, allowedObjectTypes: [any SyntaxView.Type], fields: [String : any SyntaxView.Type] = [:]) {
            self.rawJSON = json
            self.startIndex = position
            self.fields = fields
            self.allowedObjectTypes = allowedObjectTypes
        }
        
        public init(key: String, value: any SyntaxView) {
            self.rawJSON = """
            \"\(key)\":\(value)
            """
            self.startIndex = rawJSON.startIndex
            self.fields = [key : type(of: value)]
            self.allowedObjectTypes = defaultSchema
//            if let value = value as? any RawDocumentRepresentable {
//                self.allowedObjectTypes = defaultSchema
//            } else {
//                self.allowedObjectTypes = defaultSchema
//            }
        }
        
        private func key(_ scanner: Scanner) -> String {
            _ = scanner.scanCharacters(from: CharacterSet(charactersIn: "\""))
            guard let key = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "\"")) else {
                fatalError("Malformed Key")
            }
            return key
        }
        package var key: StringLiteralSyntaxView {
            StringLiteralSyntaxView(json: rawJSON, at: startIndex)
        }
        
        private func value(_ scanner: Scanner) -> any SyntaxView {
            let scanner = self.scanner()
            _ = key(scanner)
            guard let token = scanner.scanUpToTokens([.colon]),
                  scanner.scanCharacter() == ":" else {
                fatalError()
            }
            let leadingIndex = scanner.currentIndex
            return AnyValueSyntaxView<RawObjectSyntaxView>.map(json: rawJSON, at: scanner.currentIndex, allowedObjectTypes: allowedObjectTypes)
        }
        
        package var value: any SyntaxView {
            value(self.scanner())
        }
        
        init(from value: RawDocumentValue) {
            fatalError()
        }
        
        public var endIndex: String.Index {
            let scanner = self.scanner()
            return value(scanner).endIndex
        }
    }
    
    public struct Iterator : IteratorProtocol {
        fileprivate let json: String
        fileprivate let startIndex: String.Index
        fileprivate private(set) var lastEndIndex: String.Index
        fileprivate private(set) var endIndex: String.Index
        fileprivate let fields: [String : any SyntaxView.Type]
        private var allowedObjectTypes: [any SyntaxView.Type] = []
        
        init(json: String, startIndex: String.Index, endIndex: String.Index,
             allowedObjectTypes: [any SyntaxView.Type],
             fields: [String : any SyntaxView.Type]) {
            self.json = json
            self.startIndex = startIndex
            self.endIndex = endIndex
            self.lastEndIndex = startIndex
            self.fields = fields
            self.allowedObjectTypes = allowedObjectTypes
        }
        
        public mutating func next() -> (String, any SyntaxView)? {
            guard !json.isEmpty && lastEndIndex <= endIndex else {
                return nil
            }
            if lastEndIndex == startIndex {
                let field = FieldSyntaxView(json: json, at: lastEndIndex, allowedObjectTypes: allowedObjectTypes, fields: fields)
                lastEndIndex = field.endIndex
                return (field.key.string, field.value)
            }
            let scanner = Scanner(string: json)
            
            scanner.currentIndex = lastEndIndex
            guard scanner.scanUpToTokens([.comma]) != nil, scanner.scanCharacter().map(Token.init) == .comma else {
                return nil
            }
//            guard scanner.scanCharacter().map(Token.init) == .comma else {
//                return nil
//            }
            
            guard scanner.currentIndex < endIndex else {
                return nil
            }

            let field = FieldSyntaxView(json: json, at: scanner.currentIndex, allowedObjectTypes: allowedObjectTypes, fields: fields)
            lastEndIndex = field.endIndex
            return (field.key.string, field.value)
        }
    }
    
    public func makeIterator() -> Iterator {
        Iterator(json: rawJSON, 
                 startIndex: rawJSON.index(after: startIndex),
                 endIndex: rawJSON.index(before: endIndex),
                 allowedObjectTypes: allowedObjectTypes,
                 fields: fields)
    }
    
    public typealias RawDocumentValue = RawDocument
    
    public let rawJSON: String
    public let startIndex: String.Index
    public var allowedObjectTypes: [any SyntaxView.Type] = []
    public var fields: [String : any SyntaxView.Type] = [:]
    
    public init(json: String,
                at startIndex: String.Index,
                allowedObjectTypes: [any SyntaxView.Type]) {
        self.rawJSON = json
        self.startIndex = startIndex
        self.allowedObjectTypes = allowedObjectTypes
        let scanner = Scanner(string: json)
        scanner.currentIndex = startIndex
        _ = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "{"))
        _ = scanner.scanCharacter()
        var stack = 1
        while let characters = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "}")) {
//            print(characters)
            stack -= 1
            let enteredObjectCount = characters.filter({ $0 == "{" }).count
            if enteredObjectCount > 0 {
                stack += enteredObjectCount
                _ = scanner.scanCharacter()
                continue
            } else if stack == 0 {
                _ = scanner.scanCharacter()
                break
            } else {
                _ = scanner.scanCharacter()
            }
        }
//        let _ = scanner.scanCharacter()
        if scanner.isAtEnd {
            self.endIndex = json.endIndex
        } else {
            self.endIndex = scanner.currentIndex
        }
    }

    public init(from rawDocumentValue: RawDocumentValue) {
        self.rawJSON = """
        {\(rawDocumentValue.map {
            """
            "\($0.key)":\($0.value.syntaxView.description)
            """
        }.joined(separator: ","))}
        """
        self.startIndex = rawJSON.startIndex
        self.endIndex = rawJSON.endIndex
    }
    
    public init(dictionaryLiteral elements: (String, any SyntaxView)...) {
        let fields = elements
        self.rawJSON = """
        {\(fields.map(FieldSyntaxView.init).map(\.description).joined(separator: ","))}
        """
        self.startIndex = rawJSON.startIndex
        self.endIndex = rawJSON.endIndex
    }

    public init(stringLiteral value: String) {
        self.init(json: value, at: value.startIndex, allowedObjectTypes: [])
    }
    
    public var description: String {
        String(rawJSON[startIndex..<endIndex])
    }
    
    public let endIndex: String.Index
    
    public var rawDocumentRepresentable: [String : any RawDocumentRepresentable] {
        reduce(into: [String: any RawDocumentRepresentable]()) { partialResult, field in
            partialResult[field.0] = field.1.rawDocumentRepresentable
        }
    }
    
    public subscript(key: String) -> (any SyntaxView)? {
        get {
            first(where: {
                $0.0 == key
            })?.1
        }
    }
}

@attached(extension, conformances: ObjectSyntaxView, names: arbitrary)
public macro ObjectSyntaxView() = #externalMacro(module: "MongoDataAccessMacros", type: "ObjectSyntaxViewMacro")

//
//@ObjectSyntaxView public struct ObjectIdSyntaxView {
//    public let rawDocumentRepresentable: ObjectId
////    package let objectId: ObjectId
////    private let objectSyntaxView: ObjectSyntaxView
////    
////    public init?(from objectView: ObjectSyntaxView) {
////        self.objectSyntaxView = objectView
////        var fields = objectView.fieldList.fields
////        guard let oid = fields.next(),
////              oid.key.string == "$oid",
////            fields.next() == nil,
////            let oidValue = oid.value as? StringSyntaxView,
////            let objectId = try? ObjectId(string: oidValue.string) else {
////            return nil
////        }
////        self.objectId = objectId
////    }
////    
////    public init(objectId: ObjectId) {
////        self.objectSyntaxView = ObjectSyntaxView {
////            FieldSyntaxView(key: "$oid", value: StringSyntaxView(stringLiteral: "\(objectId)"))
////        }
////        self.objectId = objectId
////    }
////    
////    public static var fields: [String : any SyntaxView.Type] {
////        ["$oid": StringSyntaxView.self]
////    }
////    
////    public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any ObjectSyntaxViewProtocol.Type] = []) {
////        var view = ObjectSyntaxView(for: json, at: startIndex)
////        view.fields = Self.fields
////        view.objectType = Self.self
////        self.init(from: view)!
////    }
////    
////    public var rawDocumentRepresentable: any RawDocumentRepresentable {
////        objectId
////    }
////    
////    public var startIndex: String.Index {
////        objectSyntaxView.startIndex
////    }
////    public var endIndex: String.Index {
////        objectSyntaxView.endIndex
////    }
////    
////    public var description: String {
////        objectSyntaxView.description
////    }
//}

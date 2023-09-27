import Foundation

//public struct ArraySyntaxView<Element : RawDocumentRepresentable> : LiteralSyntaxView, Sequence {
//    public typealias Element = Element.SyntaxView
//    
//    package struct FieldSyntaxView {
//        public let rawJSON: String
//        public let startIndex: String.Index
//        private let allowedObjectTypes: [any SyntaxView.Type]
//        private func scanner() -> Scanner {
//            let scanner = Scanner(string: rawJSON)
//            scanner.currentIndex = startIndex
//            return scanner
//        }
//        public var description: String {
//            """
//            \(value)
//            """
//        }
//        fileprivate var fields: [any SyntaxView.Type] = []
//        public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any SyntaxView.Type] = []) {
//            fatalError()
//        }
//        package init(json: String, at position: String.Index, allowedObjectTypes: [any SyntaxView.Type], fields: [any SyntaxView.Type] = []) {
//            self.rawJSON = json
//            self.startIndex = position
//            self.fields = fields
//            self.allowedObjectTypes = allowedObjectTypes
//        }
//        
//        public init(value: any SyntaxView) {
//            self.rawJSON = """
//            \(value)
//            """
//            self.startIndex = rawJSON.startIndex
//            self.fields = [type(of: value)]
//            self.allowedObjectTypes = defaultSchema
//        }
//        package var key: StringLiteralSyntaxView {
//            StringLiteralSyntaxView(json: rawJSON, at: startIndex)
//        }
//        
//        private func value(_ scanner: Scanner) -> Element.SyntaxView {
//            let scanner = self.scanner()
//            let leadingIndex = scanner.currentIndex
//            if let value = try? Element.SyntaxView.init(json: rawJSON, at: leadingIndex, allowedObjectTypes: allowedObjectTypes) {
//                return value
//            } else {
//                return AnyValueSyntaxView<Element.SyntaxView>.map(json: rawJSON, at: scanner.currentIndex, allowedObjectTypes: allowedObjectTypes) as! Element.SyntaxView
//            }
//        }
//        
//        package var value: any SyntaxView {
//            value(self.scanner())
//        }
//        
//        init(from value: RawDocumentValue) {
//            fatalError()
//        }
//        
//        public var endIndex: String.Index {
//            let scanner = self.scanner()
//            return value(scanner).endIndex
//        }
//    }
//    
//    public struct Iterator : IteratorProtocol {
//        fileprivate let json: String
//        fileprivate let startIndex: String.Index
//        fileprivate private(set) var lastEndIndex: String.Index
//        fileprivate private(set) var endIndex: String.Index
//        fileprivate let fields: [any SyntaxView.Type]
//        private var allowedObjectTypes: [any SyntaxView.Type] = []
//        
//        init(json: String, startIndex: String.Index, endIndex: String.Index,
//             allowedObjectTypes: [any SyntaxView.Type],
//             fields: [any SyntaxView.Type]) {
//            self.json = json
//            self.startIndex = startIndex
//            self.endIndex = endIndex
//            self.lastEndIndex = startIndex
//            self.fields = fields
//            self.allowedObjectTypes = allowedObjectTypes
//        }
//        
//        public mutating func next() -> Element.SyntaxView? {
//            guard !json.isEmpty && lastEndIndex <= endIndex else {
//                return nil
//            }
//            if lastEndIndex == startIndex {
//                let field = FieldSyntaxView(json: json, at: lastEndIndex, allowedObjectTypes: allowedObjectTypes, fields: fields)
//                lastEndIndex = field.endIndex
//                return (field.value) as! Element
//            }
//            let scanner = Scanner(string: json)
//            
//            scanner.currentIndex = lastEndIndex
//            guard scanner.scanCharacter().map(Token.init) == .comma else {
//                return nil
//            }
//            
//            guard scanner.currentIndex < endIndex else {
//                return nil
//            }
//
//            let field = FieldSyntaxView(json: json, at: scanner.currentIndex, allowedObjectTypes: allowedObjectTypes, fields: fields)
//            lastEndIndex = field.endIndex
//            return (field.value) as! Element
//        }
//    }
//    var fields: [any SyntaxView.Type] = []
//    public func makeIterator() -> Iterator {
//        Iterator(json: rawJSON, startIndex: rawJSON.index(after: startIndex), endIndex: rawJSON.index(before: endIndex), allowedObjectTypes: allowedObjectTypes, fields: fields)
//    }
//    
//    public typealias RawDocumentValue = Array<Element>
//    
//    public var startIndex: String.Index
//    
//    public var endIndex: String.Index
//    
//    public var rawJSON: String
//    
//    private let allowedObjectTypes: [any SyntaxView.Type]
//    public var rawDocumentRepresentable: RawDocumentValue
//    
//    public init(json: String,
//                at startIndex: String.Index,
//                allowedObjectTypes: [any SyntaxView.Type]) throws {
//        self.rawJSON = json
//        self.startIndex = startIndex
//        self.allowedObjectTypes = allowedObjectTypes
//        let scanner = Scanner(string: rawJSON)
//        scanner.currentIndex = startIndex
//        _ = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "["))
//        _ = scanner.scanCharacter()
//        while let characters = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "]")) {
//            if characters.contains("[") {
//                _ = scanner.scanCharacter()
//                continue
//            } else {
//                break
//            }
//        }
//        let _ = scanner.scanCharacter()
//        if scanner.isAtEnd {
//            self.endIndex = json.endIndex
//        } else {
//            self.endIndex = scanner.currentIndex
//        }
//        var iterator = Iterator(json: rawJSON, startIndex: rawJSON.index(after: startIndex), endIndex: rawJSON.index(before: endIndex), allowedObjectTypes: allowedObjectTypes, fields: fields)
//        var array = [Element]()
//        while let element = iterator.next() {
//            array.append(element.rawDocumentRepresentable as! Element)
//        }
//        rawDocumentRepresentable = array
//    }
//    
//    public init(from value: Array<Element>) {
//        self.rawJSON = """
//        [\(value.map(Element.SyntaxView.init).map(\.description).joined(separator: ","))]
//        """
//        self.startIndex = rawJSON.startIndex
//        self.endIndex = rawJSON.endIndex
//        self.rawDocumentRepresentable = value
//        self.allowedObjectTypes = []
//    }
//    
//    public var description: String {
//        "[\(rawDocumentRepresentable.map(\.syntaxView.description).joined(separator: ","))]"
//    }
//}

public struct RawArraySyntaxView : LiteralSyntaxView, Sequence, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public typealias Element = any SyntaxView
    
    public struct FieldSyntaxView {
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
            \(value)
            """
        }
        fileprivate var fields: [any SyntaxView.Type] = []
        public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any SyntaxView.Type] = []) {
            fatalError()
        }
        package init(json: String, at position: String.Index, allowedObjectTypes: [any SyntaxView.Type], fields: [any SyntaxView.Type] = []) {
            self.rawJSON = json
            self.startIndex = position
            self.fields = fields
            self.allowedObjectTypes = allowedObjectTypes
        }
        
        public init(value: any SyntaxView) {
            self.rawJSON = """
            \(value)
            """
            self.startIndex = rawJSON.startIndex
            self.fields = [type(of: value)]
            self.allowedObjectTypes = defaultSchema
        }
        private func value(_ scanner: Scanner) -> any SyntaxView {
            let scanner = self.scanner()
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
        fileprivate let fields: [any SyntaxView.Type]
        private var allowedObjectTypes: [any SyntaxView.Type] = []
        
        init(json: String, startIndex: String.Index, endIndex: String.Index,
             allowedObjectTypes: [any SyntaxView.Type],
             fields: [any SyntaxView.Type]) {
            self.json = json
            self.startIndex = startIndex
            self.endIndex = endIndex
            self.lastEndIndex = startIndex
            self.fields = fields
            self.allowedObjectTypes = allowedObjectTypes
        }
        
        public mutating func next() -> (any SyntaxView)? {
            guard !json.isEmpty && lastEndIndex <= endIndex else {
                return nil
            }
            if lastEndIndex == startIndex {
                let field = FieldSyntaxView(json: json, at: lastEndIndex, allowedObjectTypes: allowedObjectTypes, fields: fields)
                lastEndIndex = field.endIndex
                return (field.value)
            }
            let scanner = Scanner(string: json)
            
            scanner.currentIndex = lastEndIndex
//            guard scanner.scanUpToTokens([.comma]) != nil, scanner.scanCharacter().map(Token.init) == .comma else {
//                return nil
//            }
            guard scanner.scanCharacter().map(Token.init) == .comma else {
                return nil
            }
            
            guard scanner.currentIndex < endIndex else {
                return nil
            }

            let field = FieldSyntaxView(json: json, at: scanner.currentIndex, allowedObjectTypes: allowedObjectTypes, fields: fields)
            lastEndIndex = field.endIndex
            return (field.value)
        }
    }
    var fields: [any SyntaxView.Type] = []
    public func makeIterator() -> Iterator {
        Iterator(json: rawJSON,
                 startIndex: rawJSON.index(after: startIndex),
                 endIndex: rawJSON.index(before: endIndex),
                 allowedObjectTypes: allowedObjectTypes,
                 fields: fields)
    }
    
    public typealias RawDocumentValue = Array<any RawDocumentRepresentable>
    
    public var startIndex: String.Index
    
    public var endIndex: String.Index
    
    public var rawJSON: String
    
    private let allowedObjectTypes: [any SyntaxView.Type]
    public var rawDocumentRepresentable: RawDocumentValue
    
    public init(stringLiteral value: String) {
        try! self.init(json: value, at: value.startIndex, allowedObjectTypes: [])
    }
    public init(json: String,
                at startIndex: String.Index,
                allowedObjectTypes: [any SyntaxView.Type]) throws {
        self.rawJSON = json
        self.startIndex = startIndex
        self.allowedObjectTypes = allowedObjectTypes
        let scanner = Scanner(string: rawJSON)
        scanner.currentIndex = startIndex
        _ = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "["))
        _ = scanner.scanCharacter()
        var stack = 1
        while let characters = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "]")) {
//            print(characters)
            stack -= 1
            let enteredObjectCount = characters.filter({ $0 == "[" }).count
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
        var iterator = Iterator(json: rawJSON,
                                startIndex:
                                    rawJSON.index(after: startIndex),
                                endIndex: rawJSON.index(before: endIndex), 
                                allowedObjectTypes: allowedObjectTypes, fields: fields)
        var array = [AnyRawDocumentRepresentable]()
        while let element = iterator.next() {
            array.append(AnyRawDocumentRepresentable(rawDocumentRepresentable: element.rawDocumentRepresentable))
        }
        
        rawDocumentRepresentable = array
    }
    
    public init(from value: Array<any RawDocumentRepresentable>) {
        self.rawJSON = """
        [\(value.map(\.syntaxView.description).joined(separator: ","))]
        """
        self.startIndex = rawJSON.startIndex
        self.endIndex = rawJSON.endIndex
        self.rawDocumentRepresentable = value
        self.allowedObjectTypes = []
    }
    public init<Value: RawDocumentRepresentable>(from value: Array<Value>) {
        self.rawJSON = """
        [\(value.map(\.syntaxView.description).joined(separator: ","))]
        """
        self.startIndex = rawJSON.startIndex
        self.endIndex = rawJSON.endIndex
        self.rawDocumentRepresentable = value
        self.allowedObjectTypes = []
    }
    public var description: String {
        "[\(rawDocumentRepresentable.map(\.syntaxView.description).joined(separator: ","))]"
    }
    
    public subscript(idx: Int) -> any SyntaxView {
        var iter = makeIterator()
        var i = 0
        while let value = iter.next() {
            if idx == i {
                return value
            }
            i += 1
        }
        fatalError()
    }
}

extension List: RawDocumentRepresentable where Element: RawDocumentRepresentable {
    public struct SyntaxView : LiteralSyntaxView {
        
        public typealias RawDocumentValue = List<Element>
        
        public let startIndex: String.Index
        
        public let endIndex: String.Index
        
        public let rawJSON: String
        
        public let description: String
        public let rawDocumentRepresentable: List<Element>
        
        public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any MongoDataAccess.SyntaxView.Type]) throws {
            let syntaxView = try RawArraySyntaxView(json: json, at: startIndex, allowedObjectTypes: allowedObjectTypes)
            self.description = syntaxView.description
            self.rawJSON = syntaxView.rawJSON
            self.startIndex = syntaxView.startIndex
            self.endIndex = syntaxView.endIndex
            self.rawDocumentRepresentable = syntaxView.compactMap({
                $0.rawDocumentRepresentable as? Element
            }).reduce(into: List<Element>(), {
                $0.append($1)
            })
        }
        
        public init(from value: List<Element>) {
            let syntaxView = RawArraySyntaxView(from: value.map { $0 as any RawDocumentRepresentable })
            self.description = syntaxView.description
            self.rawJSON = syntaxView.rawJSON
            self.startIndex = syntaxView.startIndex
            self.endIndex = syntaxView.endIndex
            self.rawDocumentRepresentable = value
        }
    }
}

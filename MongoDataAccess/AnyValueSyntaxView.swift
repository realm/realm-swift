import Foundation

//extension SyntaxView {
//    private static func syntaxView(for json: String, at startIndex: String.Index, configuration: inout Configuration) -> any SyntaxView {
//        let scanner = Scanner(string: json)
//        scanner.currentIndex = startIndex
//        let leadingIndex = scanner.currentIndex
//        if scanner.scanDouble() != nil {
//            return DoubleLiteralSyntaxView(json: json, at: leadingIndex, configuration: &configuration)
//        }
//        if scanner.scanInt() != nil {
//            return IntLiteralSyntaxView(json: json, at: leadingIndex, configuration: &configuration)
//        }
//        if scanner.scanString("true") != nil {
//            return BoolSyntaxView(json: json, at: leadingIndex, configuration: &configuration)
//        }
//        if scanner.scanString("false") != nil {
//            return BoolSyntaxView(json: json, at: leadingIndex, configuration: &configuration)
//        }
//
//        guard let token = scanner.scanUpToTokens([.openBrace, .quotation, .openBracket]) else {
//            fatalError("Malformed JSON")
//        }
//        switch token {
//        case .openBrace:
//            return RawObjectSyntaxView(json: json,
//                                       at: scanner.currentIndex,
//                                       allowedObjectTypes: allowedObjectTypes + defaultSchema)
//        case .quotation:
//            return StringLiteralSyntaxView(json: json,
//                                           at: scanner.currentIndex)
//        case .openBracket:
//            return try! RawArraySyntaxView(json: json,
//                                           at: scanner.currentIndex,
//                                           allowedObjectTypes: allowedObjectTypes)
//        default:
//            fatalError("Unsupported type")
//        }
//    }
//    
//    public static func map(json: String,
//                           at startIndex: String.Index,
//                           allowedObjectTypes: [any SyntaxView.Type]) -> any SyntaxView {
//        Self.syntaxView(for: json, at: startIndex, allowedObjectTypes: allowedObjectTypes)
//    }
//}

public struct AnyValueSyntaxView<View : SyntaxView> : LiteralSyntaxView {
    public var startIndex: String.Index
    public var endIndex: String.Index
    public let syntaxView: View
    public var rawJSON: String
    
//    public init(json: String, at startIndex: String.Index) throws {
//        try self.init(json: json, at: startIndex, configuration: .default)
//    }
    
    public init(json: String, 
                at startIndex: String.Index,
                configuration: inout Configuration) throws {
        self.rawJSON = json
        self.startIndex = startIndex
        self.syntaxView = try View.init(json: json, at: startIndex, configuration: &configuration)
        self.endIndex = syntaxView.endIndex
    }
    
    public var description: String {
        syntaxView.description
    }
    
    public init(from view: View) {
        self.rawJSON = view.rawJSON
        self.startIndex = view.startIndex
        self.syntaxView = view
        self.endIndex = view.endIndex
    }
    
    public init(from rawDocumentValue: View.RawDocumentValue) {
        self.init(from: View(from: rawDocumentValue))
    }
    
    public var rawDocumentRepresentable: View.RawDocumentValue {
        syntaxView.rawDocumentRepresentable
//        switch syntaxView {
//        case let view as StringLiteralSyntaxView: view.string
//        case let view as DoubleLiteralSyntaxView: view.double
//        case let view as IntLiteralSyntaxView: view.integer
//        default: Optional<String>(nilLiteral: ())
//        }
    }
}

//extension Optional : RawDocumentRepresentable where Wrapped : RawDocumentRepresentable {
//    public struct SyntaxView : LiteralSyntaxView, ObjectSyntaxView, ExpressibleByNilLiteral {
//        public init(from view: RawObjectSyntaxView) throws {
//            try self.init(json: view.rawJSON, at: view.startIndex, allowedObjectTypes: view.allowedObjectTypes)
//            self.rawObjectSyntaxView = view
//        }
//        
//        public var rawObjectSyntaxView: RawObjectSyntaxView
//        
//        public init(from value: Optional<Wrapped>) {
//            if let value = value {
//                let syntaxView = value.syntaxView
//                try! self.init(json: syntaxView.rawJSON, at: syntaxView.startIndex, allowedObjectTypes: [])
////                self.startIndex = syntaxView.startIndex
////                self.endIndex = syntaxView.endIndex
////                self.rawJSON = syntaxView.rawJSON
////                self.rawDocumentRepresentable = syntaxView.rawDocumentRepresentable as? Wrapped
//            } else {
//                try! self.init(json: "null", at: "null".startIndex, allowedObjectTypes: [])
//            }
//        }
//        
////        public init(from value: Optional<Wrapped>) where Wrapped : RealmSwift.Object {
////            if let value = value {
////                let dbRef = DBRef(collectionName: Wrapped.className(), databaseName: nil, id: value.value(forKeyPath: "_id") as! any RawDocumentRepresentable)
////                let syntaxView = dbRef.syntaxView
////                try! self.init(json: syntaxView.rawJSON, at: syntaxView.startIndex, allowedObjectTypes: [])
//////                self.startIndex = syntaxView.startIndex
//////                self.endIndex = syntaxView.endIndex
//////                self.rawJSON = syntaxView.rawJSON
//////                self.rawDocumentRepresentable = syntaxView.rawDocumentRepresentable as? Wrapped
////            } else {
////                try! self.init(json: "null", at: "null".startIndex, allowedObjectTypes: [])
////            }
////        }
//        
//        public init(nilLiteral: ()) {
//            let null = "null"
//            try! self.init(json: null, at: null.startIndex, allowedObjectTypes: [])
//        }
//        
//        public var rawDocumentRepresentable: Wrapped?
//        
//        public var startIndex: String.Index
//        
//        public var endIndex: String.Index
//        
//        public var rawJSON: String
//        
//        public init(_ some: Wrapped.SyntaxView) {
//            self.rawDocumentRepresentable = Optional(some.rawDocumentRepresentable)
//            fatalError()
//        }
//        
//        public init(json: String,
//                    at startIndex: String.Index,
//                    configuration: inout Configuration) throws {
//            self.rawJSON = json
//            self.startIndex = startIndex
//            let scanner = Scanner(string: rawJSON)
//            scanner.currentIndex = startIndex
//            if scanner.scanString("null") != nil {
//                self.endIndex = scanner.currentIndex
//                self.rawDocumentRepresentable = nil
//            } else {
//                let syntaxView = try Wrapped.SyntaxView(json: rawJSON,
//                                                        at: startIndex,
//                                                        configuration: &configuration)
//                self.endIndex = syntaxView.endIndex
//                self.rawDocumentRepresentable = syntaxView.rawDocumentRepresentable
//            }
//            self.rawObjectSyntaxView = RawObjectSyntaxView(json: json, 
//                                                           at: startIndex,
//                                                           configuration: &configuration)
//        }
//        
//        public var description: String {
//            rawDocumentRepresentable.map {
//                $0.syntaxView.description
//            } ?? "null"
//        }
//    }
//}

//@BSONCodable struct DBRef {
//    @DocumentKey("$ref") let collectionName: String
//    @DocumentKey("$db") let databaseName: String?
//    @DocumentKey("$id") let id: any RawDocumentRepresentable
//}

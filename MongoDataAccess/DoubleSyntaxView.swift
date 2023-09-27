import Foundation

extension Double : RawDocumentRepresentable {
    public struct SyntaxView : ObjectSyntaxView {
        public let rawObjectSyntaxView: RawObjectSyntaxView
        public let rawDocumentRepresentable: Double
        
        public init(from view: RawObjectSyntaxView) throws {
            self.rawObjectSyntaxView = view
            guard let view = view["$numberDouble"] else {
                throw BSONError.missingKey("$numberDouble")
            }
            
            if let view = view as? DoubleLiteralSyntaxView {
                self.rawDocumentRepresentable = view.double
            } else if let view = view as? StringLiteralSyntaxView {
                if view.string == "Infinity" {
                    self.rawDocumentRepresentable = .infinity
                } else if view.string == "-Infinity" {
                    self.rawDocumentRepresentable = -.infinity
                } else {
                    throw BSONError.invalidType(key: "$numberDouble")
                }
            } else {
                throw BSONError.invalidType(key: "$numberDouble")
            }
        }
        
        public init(from rawDocumentRepresentable: Double) {
            self.rawDocumentRepresentable = rawDocumentRepresentable
            self.rawObjectSyntaxView = [
                "$numberDouble": {
                    switch rawDocumentRepresentable {
                    case .infinity: StringLiteralSyntaxView(stringLiteral: "Infinity")
                    case -.infinity: StringLiteralSyntaxView(stringLiteral: "-Infinity")
                    case rawDocumentRepresentable where rawDocumentRepresentable.isNaN: StringLiteralSyntaxView(stringLiteral: "NaN")
                    default: DoubleLiteralSyntaxView(floatLiteral: rawDocumentRepresentable)
                    }
                }()
            ]
        }
    }

    public init(from view: SyntaxView) throws {
        self = view.rawDocumentRepresentable
    }

    public func encode() -> SyntaxView {
        SyntaxView(from: self)
    }
}

package struct DoubleLiteralSyntaxView : LiteralSyntaxView, ExpressibleByFloatLiteral {
    public let rawJSON: String
    
    public typealias FloatLiteralType = Double
    
    package typealias SyntaxViewProtocol = Self
    
    public let startIndex: String.Index
    
    public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any SyntaxView.Type] = []) {
        self.rawJSON = json
        self.startIndex = startIndex
    }
    
    package init(from value: Double) {
        self.init(floatLiteral: value)
    }
    
    package init(floatLiteral value: FloatLiteralType) {
        self.rawJSON = "\(value)"
        self.startIndex = rawJSON.startIndex
    }
    
    package var description: String {
        String(self.rawJSON[startIndex..<endIndex])
    }
    
    package var double: Double {
        let scanner = self.scanner()
        return scanner.scanDouble()!
    }
    
    package var rawDocumentRepresentable: Double {
        double
    }
    
    package var endIndex: String.Index {
        let scanner = self.scanner()
        _ = scanner.scanDouble()
        return scanner.currentIndex
    }
}

//public struct DoubleSyntaxView : ObjectSyntaxViewProtocol, ExpressibleByFloatLiteral {
//    public typealias RawDocumentValue = Double
//
//    public var rawJSON: String
//
//    public static var fields: [String : any SyntaxView.Type] {
//        ["$numberDouble": AnyValueSyntaxView.self]
//    }
//
//    public let double: Double
//
//    public init?(from objectView: ObjectSyntaxView) {
//        var objectSyntaxView = objectView
//        objectSyntaxView.objectType = Self.self
//        objectSyntaxView.fields = Self.fields
//        var fields = objectSyntaxView.fieldList.fields
//        guard let oid = fields.next(),
//              oid.key.string == "$numberDouble",
//            fields.next() == nil,
//            let oidValue = oid.value as? AnyValueSyntaxView else {
//            return nil
//        }
//
//        self.objectSyntaxView = objectSyntaxView
//        let raw = oidValue.rawDocumentRepresentable
//        if let raw = raw as? Double {
//            self.double = raw
//        } else if let raw = raw as? String {
//            if raw == "Infinity" {
//                self.double = .infinity
//            } else if raw == "-Infinity" {
//                self.double = -.infinity
//            } else if raw == "NaN" {
//                self.double = .nan
//            } else {
//                fatalError()
//            }
//        } else {
//            fatalError()
//        }
//    }
//
//    public init(floatLiteral: Double) {
//        var objectSyntaxView = RawObjectSyntaxView(fields: {
//            if floatLiteral == .infinity {
//                FieldSyntaxView(key: "$numberDouble",
//                                value: StringLiteralSyntaxView(stringLiteral: "Infinity"))
//            } else if floatLiteral == -.infinity {
//                FieldSyntaxView(key: "$numberDouble",
//                                value: StringLiteralSyntaxView(stringLiteral: "-Infinity"))
//            } else if floatLiteral.isNaN {
//                FieldSyntaxView(key: "$numberDouble",
//                                value: StringLiteralSyntaxView(stringLiteral: "NaN"))
//            } else {
//                FieldSyntaxView(key: "$numberDouble",
//                                value: DoubleLiteralSyntaxView(floatLiteral: floatLiteral))
//            }
//        })
//        objectSyntaxView.objectType = Self.self
//        objectSyntaxView.fields = Self.fields
//        self.double = floatLiteral
//        self.objectSyntaxView = objectSyntaxView
//    }
//
//    public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any ObjectSyntaxViewProtocol.Type] = []) {
//        var view = ObjectSyntaxView(for: json, at: startIndex)
//        view.fields = Self.fields
//        view.objectType = Self.self
//        view.allowedObjectTypes = [Double.SyntaxView.self]
//        self.init(from: view)!
//    }
//    public var startIndex: String.Index {
//        objectSyntaxView.startIndex
//    }
//    public var endIndex: String.Index {
//        objectSyntaxView.endIndex
//    }
//
//    public var description: String {
//        objectSyntaxView.description
//    }
//
//    public var rawDocumentRepresentable: any RawDocumentRepresentable {
//        double
//    }
//}

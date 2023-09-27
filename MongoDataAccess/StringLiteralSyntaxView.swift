import Foundation

public struct StringLiteralSyntaxView : LiteralSyntaxView, ExpressibleByStringLiteral {
    public let startIndex: String.Index
    public let rawJSON: String
    
    package init?(from syntaxView: any SyntaxView) {
        if let syntaxView = syntaxView as? StringLiteralSyntaxView {
            self = syntaxView
        } else {
            return nil
        }
    }
    
    public init(from value: String) {
        self.init(stringLiteral: value)
    }
    public init(json: String, at startIndex: String.Index, allowedObjectTypes: [any SyntaxView.Type] = []) {
        self.rawJSON = json
        self.startIndex = startIndex
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self.rawJSON = "\"\(value)\""
        self.startIndex = rawJSON.startIndex
    }
    
    public var description: String {
        String(self.rawJSON[startIndex..<endIndex])
    }
    
    public var string: String {
        let scanner = self.scanner()
        _ = scanner.scanCharacters(from: CharacterSet(charactersIn: "\""))
        guard let string = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "\"")) else {
            fatalError("Malformed string")
        }
        return string
    }
    
    public var rawDocumentRepresentable: String {
        string
    }
    
    public var endIndex: String.Index {
        let scanner = self.scanner()
        _ = scanner.scanCharacters(from: CharacterSet(charactersIn: "\""))
        _ = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "\""))
        return rawJSON.index(after: scanner.currentIndex)
    }
}

extension String : RawDocumentRepresentable {
    public typealias SyntaxView = StringLiteralSyntaxView
}

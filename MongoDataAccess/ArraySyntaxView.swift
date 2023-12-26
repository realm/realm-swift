import Foundation

//extension Array : RawDocumentRepresentable where Element == any RawDocumentRepresentable {
//    public init(from scanner: inout Scanner) throws {
//        precondition(scanner.scanCharacter() == "[")
//        self.init()
//        while true {
//            guard scanner.peekCharacter() != "]" else {
//                precondition(scanner.scanCharacter() == "]")
//                return
//            }
//            let node = try SyntaxNode(from: &scanner).view
//            self.append(node)
//            switch scanner.scanCharacter().map(Token.init) {
//            case .comma: continue
//            case .closeBracket: return
//            case let token: preconditionFailure(token?.debugDescription ?? "unknown token")
//            }
//        }
//    }
//    
//    public var jsonLiteralView: String {
//        """
//        [\(self.map(\.jsonLiteralView).joined(separator: ","))]
//        """
//    }
//}
//
//extension Array where Element == any RawDocumentRepresentable {
//    public init(from scanner: inout Scanner) throws {
//        precondition(scanner.scanCharacter() == "[")
//        self.init()
//        while true {
//            guard scanner.peekCharacter() != "]" else {
//                precondition(scanner.scanCharacter() == "]")
//                return
//            }
//            let node = try SyntaxNode(from: &scanner)
//            self.append(node.view)
//            switch scanner.scanCharacter().map(Token.init) {
//            case .comma: continue
//            case .closeBracket: return
//            case let token: preconditionFailure(token?.debugDescription ?? "unknown token")
//            }
//        }
//    }
//}
//
//extension List: RawDocumentRepresentable where Element: RawDocumentRepresentable {
//    public var jsonLiteralView: String {
//        self.map { $0 }.jsonLiteralView
//    }
//    
//    public convenience init(from scanner: inout Scanner) throws {
//        self.init()
//        (try [any RawDocumentRepresentable](from: &scanner)).forEach {
//            self.append($0 as! Element)
//        }
//    }
//}

import Foundation
import RealmSwift

package enum PrimaryKey : Hashable {
    case string(String)
    case int(Int)
    case objectId(ObjectId)
}

public struct Configuration {
    public let linkDepth: UInt8
//    package let discoveredObjects: [PrimaryKey : RawObjectSyntaxView]
    
//    public static let `default` = Configuration(linkDepth: 0, discoveredObjects: [:])
}

public protocol SyntaxView : CustomStringConvertible {
    associatedtype RawDocumentValue : RawDocumentRepresentable

    var startIndex: String.Index { get }
    var endIndex: String.Index { get }
    var rawJSON: String { get }
//    var configuration: Configuration { get }
    
    init(json: String,
         at startIndex: String.Index,
         configuration: inout Configuration) throws
    init(from value: RawDocumentValue)
    @AnyRawDocumentRepresentableBuilder var rawDocumentRepresentable: RawDocumentValue { get }
}

extension SyntaxView {
    package func scanner() -> Scanner {
        let scanner = Scanner(string: rawJSON)
        scanner.currentIndex = startIndex
        return scanner
    }
}

extension SyntaxView {
//    public func `as`<View>(_ type: View.Type) throws -> View? where View : ObjectSyntaxView {
//        if let self = self as? RawObjectSyntaxView {
//            return try View.init(from: self)
//        } else {
//            return self as? View
//        }
//    }
//
//    public func `as`<View>(_ type: View?.Type) throws -> View? where View : ObjectSyntaxView {
//        if let self = self as? RawObjectSyntaxView {
//            return try View.init(from: self)
//        } else {
//            return self as? View
//        }
//    }

//    public func `as`<View : SyntaxView>(_ type: View.Type) throws -> View? {
//        if let self = self as? View {
//            return self
//        } else if let self = self as? RawArraySyntaxView {
//            return try View.init(json: self.rawJSON, at: self.startIndex, configuration: &self.configuration)
//        } else {
//            return nil
//        }
//    }
//    
//    public func `as`<View: SyntaxView>(_ type: View.Type) throws -> View? where Self == RawArraySyntaxView {
//        return try View.init(json: self.rawJSON, at: self.startIndex, configuration: &self.configuration)
//    }
}

extension SyntaxView where RawDocumentValue : Object {
    public func `as`<View>(_ type: View.Type) throws -> View? {
        if let self = self as? View {
            return self
        } else {
            return nil
        }
    }
}

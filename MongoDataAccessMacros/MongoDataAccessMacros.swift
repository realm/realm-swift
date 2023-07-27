import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct BSONCodableMacro : ConformanceMacro, MemberMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingConformancesOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [(SwiftSyntax.TypeSyntax, SwiftSyntax.GenericWhereClauseSyntax?)] {
        return [
            ("BSONCodable", nil)
        ]
    }
    
    private static func declName(_ member: MemberDeclListSyntax.Element) -> String {
        guard let decl = member.decl.as(VariableDeclSyntax.self),
            let binding = decl.bindings.compactMap({
                $0.pattern.as(IdentifierPatternSyntax.self)
            }).first else {
                fatalError()
            }
        return "\(binding.identifier)"
    }
    private static func declType(_ member: MemberDeclListSyntax.Element) -> String {
        guard let decl = member.decl.as(VariableDeclSyntax.self),
              let type = decl.bindings.compactMap({
                  $0.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self)?.name
              }).first else {
                fatalError()
            }
        return "\(type)"
    }
    private static func declAsArg(_ member: MemberDeclListSyntax.Element) -> String {
        guard let decl = member.decl.as(VariableDeclSyntax.self),
            let binding = decl.bindings.compactMap({
                $0.pattern.as(IdentifierPatternSyntax.self)
            }).first,
            let type = decl.bindings.compactMap({
                $0.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self)?.name
            }).first else {
                fatalError()
            }
        return "\(binding.identifier): \(type)"
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        return [
            """
            init(\(raw: declaration.memberBlock.members.map(declAsArg).joined(separator: ","))) {
                \(raw: declaration.memberBlock.members.map {
                """
                self.\(declName($0)) = \(declName($0))
                """
                }.joined(separator: "\n"))
            }
            """,
            """
            init(from document: Document) throws {
                \(raw: declaration.memberBlock.members.compactMap { member in
                    guard let decl = member.decl.as(VariableDeclSyntax.self),
                        let binding = decl.bindings.compactMap({
                            $0.pattern.as(IdentifierPatternSyntax.self)
                        }).first,
                        let type = decl.bindings.compactMap({
                            $0.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self)?.name
                        }).first
                    else { return nil }

                    return """
                    guard let \(binding.identifier) = document["\(binding.identifier)"] else {
                        throw BSONError.missingKey("\(binding.identifier)")
                    }
                    guard let \(binding.identifier): \(type) = try \(binding.identifier)?.as() else {
                        throw BSONError.invalidType(key: "\(binding.identifier)")
                    }
                    self.\(binding.identifier) = \(binding.identifier)
                    """
                }.joined(separator: "\n"))
            }
            """,
            """
            func encode(to document: inout Document) {
                \(raw: declaration.memberBlock.members.compactMap { member in
                    guard let decl = member.decl.as(VariableDeclSyntax.self),
                        let binding = decl.bindings.compactMap({
                            $0.pattern.as(IdentifierPatternSyntax.self)
                        }).first
                    else { return nil }

                    return """
                    document["\(binding.identifier)"] = AnyBSON(\(binding))
                    """
                }.joined(separator: "\n"))
            }
            """,
            """
            struct Filter : BSONFilter {
                var documentRef = DocumentRef()
                \(raw: declaration.memberBlock.members.compactMap { member in
                    guard let decl = member.decl.as(VariableDeclSyntax.self),
                        let binding = decl.bindings.compactMap({
                            $0.pattern.as(IdentifierPatternSyntax.self)
                        }).first,
                        let type = decl.bindings.compactMap({
                            $0.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self)?.name
                        }).first
                    else { return nil }

                    return """
                    var \(binding.identifier): BSONQuery<\(type)>
                    """
                }.joined(separator: "\n"))
                init() {
                    \(raw: declaration.memberBlock.members.compactMap { member in
                    guard let decl = member.decl.as(VariableDeclSyntax.self),
                        let binding = decl.bindings.compactMap({
                            $0.pattern.as(IdentifierPatternSyntax.self)
                        }).first,
                        let type = decl.bindings.compactMap({
                            $0.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self)?.name
                        }).first
                    else { return nil }
            
                    return """
                    \(binding.identifier) = BSONQuery<\(type)>(identifier: "\(binding.identifier)", documentRef: documentRef)
                    """
                    }.joined(separator: "\n"))
                }
                mutating func encode() -> Document {
                    return documentRef.document
                }
            }
            """,
        ]
    }
}
/**
 var document = Document()
 \(raw: declaration.memberBlock.members.compactMap { member in
     guard let decl = member.decl.as(VariableDeclSyntax.self),
         let binding = decl.bindings.compactMap({
             $0.pattern.as(IdentifierPatternSyntax.self)
         }).first
     else { return nil }

     return """
     document.merge(\(binding.identifier).filterDocument, uniquingKeysWith: { lhs, rhs in lhs })
     """
 }.joined(separator: "\n"))
 return document
 */
@main
struct MongoDataAccessMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BSONCodableMacro.self
    ]
}

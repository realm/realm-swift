import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension String {
    func lowercasingFirstLetter() -> String {
      return prefix(1).lowercased() + self.dropFirst()
    }
}

public struct BSONCodableMacro : ExtensionMacro, MemberMacro, PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        if declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) {
            return []
        }
//        guard let arguments = node.arguments,
//              let arguments = arguments.as(LabeledExprListSyntax.self),
//              let key = arguments.first,
////              key.label?.text == "key",
//              let content = key.expression.as(StringLiteralExprSyntax.self) else {
////            throw Error.invalidDeclaration("")
////            throw Error.invalidDeclaration("\(node.arguments!.as(LabeledExprListSyntax.self)!.first!.expression.as(StringLiteralExprSyntax.self)!.description)")
//        }
//        throw Error.invalidDeclaration(
//            
//        )
//        let variableName = declaration.as(VariableDeclSyntax.self)!.bindings.first!.pattern.as(IdentifierPatternSyntax.self)!.identifier
//        throw Error.invalidDeclaration(content.description)
        return [
//            """
//            private static var _\(variableName)Key: String {
//                \(content)
//            }
//            """
        ]
    }

    public static func expansion(of node: SwiftSyntax.AttributeSyntax, 
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        var typeName = "\(type)"
        if typeName.contains(".") {
            typeName = String(typeName.split(separator: ".")[1])
        }
        let lowercasedType = typeName.lowercasingFirstLetter()
        let members = try declaration.memberBlock.members.compactMap(view(for:))
        var isStruct = declaration is StructDeclSyntax
        return [.init(extendedType: type, inheritanceClause: InheritanceClauseSyntax.init(inheritedTypes: .init(arrayLiteral: .init(type: TypeSyntax(stringLiteral: "ExtJSONQueryRepresentable")))), memberBlock: """
            {
                \(raw: !isStruct ? "convenience" : "") init(extJSONValue value: ExtJSONDocument) throws {
                    \(raw: !isStruct ? "self.init()" : "")
                    \(raw: try members.compactMap { member in
                        if member.ignore {
                            if member.assignment == nil && !member.isOptional {
                                throw Error.invalidDeclaration("Non-optional ignored properties must provide a default value.")
                            } else if member.assignment != nil {
                                return ""
                            }
                            return """
                            self.\(member.name) = \(member.assignment ?? "nil")
                            """
                        }
                        return """
                        self.\(member.name) = try ExtJSONSerialization.read(from: value, for: Self._\(member.name)Key)
                        """
                    }.joined(separator: "\n"))
                }
                var extJSONValue: ExtJSONDocument {
                    [
                        \(raw: members.filter{ !$0.ignore }.compactMap { member in
                            return """
                            "\(member.name)": \(member.isExistential ? member.name : "\(member.name).extJSONValue")
                            """
                        }.joined(separator: ",\n"))
                    ]
                }
            
                static var keyPaths: [PartialKeyPath<\(raw: type)> : String] {
                    [
                        \(raw: members.compactMap { member in
                            return """
                            \\.\(member.name): "\(member.name)"
                            """.trimmingCharacters(in: .whitespaces)
                        }.joined(separator: ",\n"))
                    ]
                }
            
                static var schema: [String : Any.Type] {
                    [
                        \(raw: members.compactMap { member in
                            return """
                            "\(member.name)": (\(member.type)).self
                            """.trimmingCharacters(in: .whitespaces)
                        }.joined(separator: ",\n"))
                    ]
                }
            }
            """)]
    }
    
    enum Error : Swift.Error {
        case invalidDeclaration(String)
    }
    
    private static func declName(_ member: MemberBlockItemListSyntax.Element) -> String? {
        guard let decl = member.decl.as(VariableDeclSyntax.self),
            let binding = decl.bindings.compactMap({
                $0.pattern.as(IdentifierPatternSyntax.self)
            }).first else {
                return nil
            }
        return "\(binding.identifier)"
    }
    
    private static func declType(_ member: MemberBlockItemListSyntax.Element) throws -> String? {
        guard let decl = member.decl.as(VariableDeclSyntax.self),
              let type = decl.bindings.compactMap({
                  $0.typeAnnotation?.type
              }).first, !type.is(StructDeclSyntax.self)  else {
            return nil
        }
        return "\(type)"
    }
    private static func declAsArg(_ member: MemberBlockItemListSyntax.Element) throws -> String? {
        guard let decl = member.decl.as(VariableDeclSyntax.self),
            let binding = decl.bindings.compactMap({
                $0.pattern.as(IdentifierPatternSyntax.self)
            }).first,
            let type = decl.bindings.compactMap({
                $0.typeAnnotation?.type
            }).first, !type.is(StructDeclSyntax.self) else {
            return nil
//            throw Error.invalidDeclaration(member.debugDescription)
        }
        return "\(binding.identifier): \(type)"
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
//        let extendedType = type
        let members = try declaration.memberBlock.members.compactMap(view(for:))
        let isStruct = declaration is StructDeclSyntax
        return [
            """
            \(raw: !isStruct ? "convenience" : "") init(\(raw: members.reduce(into: [String]()) { strings, member in
                    strings.append("\(member.name): \(member.type)")
                if let assignment = member.assignment {
                    strings[strings.index(before: strings.endIndex)] += " = \(assignment)"
                }
                }.joined(separator: ",\n"))) {
                \(raw: !isStruct ? "self.init()" : "")
                \(raw: members.filter { $0.assignment == nil }.reduce(into: [String]()) { strings, member in
                            strings.append("self.\(member.name) = \(member.name)")
                }.joined(separator: "\n"))
            }
            """,
            """
            \(raw: members.map { member in
                """
                private static var _\(member.name)Key: String {
                    "\(member.attributeKey ?? member.name)"
                }
                """
            }.joined(separator: "\n"))
            """
//            """
//            convenience init(\(raw: members.reduce(into: [String]()) { strings, member in
//                    strings.append("\(member.name): \(member.type)")
//                if let assignment = member.assignment {
//                    strings[strings.index(before: strings.endIndex)] += " = \(assignment)"
//                }
//                }.joined(separator: ",\n"))) {
//                self.init()
//                \(raw: members.reduce(into: [String]()) { strings, member in
//                            strings.append("self.\(member.name) = \(member.name)")
//                }.joined(separator: "\n"))
//            }
//            """,
        ]
    }
}
private struct MemberView {
    let name: String
    let type: String
    var attributeKey: String?
    var assignment: String?
    var isExistential: Bool
    var isOptional: Bool
    var ignore: Bool
}

enum Error : Swift.Error {
    case blah(String)
}
private func view(for member: MemberBlockItemListSyntax.Element) throws -> MemberView? {
    guard let decl = member.decl.as(VariableDeclSyntax.self),
          let binding = decl.bindings.compactMap({
              $0.pattern.as(IdentifierPatternSyntax.self)
          }).first,
          let type = decl.bindings.compactMap({
              $0.typeAnnotation?.type
          }).first,
            !type.is(StructDeclSyntax.self) else {
        return nil
    }
    var memberView = MemberView(name: "\(binding.identifier.text.replacingOccurrences(of: "`", with: ""))", type: "\(type)", attributeKey: nil, isExistential: false, isOptional: false, ignore: false)
    if let macroName = decl.attributes.first(where: { element in
            element.as(AttributeSyntax.self)?.attributeName
            .as(IdentifierTypeSyntax.self)?.name.text == "BSONCodable"
        })?.as(AttributeSyntax.self)?
        .arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(StringLiteralExprSyntax.self) {
        memberView.attributeKey = "\(macroName.segments)"
    }
    if let macroName = decl.attributes.first(where: { element in
            element.as(AttributeSyntax.self)?.attributeName
            .as(IdentifierTypeSyntax.self)?.name.text == "BSONCodable"
        })?.as(AttributeSyntax.self)?
        .arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(StringLiteralExprSyntax.self) {
        memberView.attributeKey = "\(macroName.segments)"
    }
    if let macroName = decl.attributes.first(where: { element in
            element.as(AttributeSyntax.self)?.attributeName
            .as(IdentifierTypeSyntax.self)?.name.text == "BSONCodable"
        })?.as(AttributeSyntax.self)?
        .arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(BooleanLiteralExprSyntax.self) {
        memberView.ignore = macroName.literal.tokenKind == .keyword(.true)
    }
    if decl.tokens(viewMode: .sourceAccurate).contains(where: { $0.tokenKind == .keyword(.Any) }) {
        memberView.isExistential = true
    }
    if decl.tokens(viewMode: .sourceAccurate).contains(where: { $0.tokenKind == .postfixQuestionMark || $0.tokenKind == .exclamationMark }) ||
        (memberView.name.starts(with: "Optional<") && memberView.name.hasSuffix(">")) {
        memberView.isOptional = true
    }
    
    if let assignment = decl.bindings.compactMap({
        $0.initializer?.value
    }).first {
        memberView.assignment = "\(assignment)"
    }
    return memberView
}
//public struct RawDocumentQueryRepresentableMacro : MemberMacro, ExtensionMacro, PeerMacro {
//    
//    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
//        []
//    }
//    
//    private static func declName(_ member: MemberBlockItemListSyntax.Element) -> String? {
//        guard let decl = member.decl.as(VariableDeclSyntax.self),
//            let binding = decl.bindings.compactMap({
//                $0.pattern.as(IdentifierPatternSyntax.self)
//            }).first else {
//                return nil
//            }
//        return "\(binding.identifier)"
//    }
//    
//    private static func declType(_ member: MemberBlockItemListSyntax.Element) throws -> String? {
//        guard let decl = member.decl.as(VariableDeclSyntax.self),
//              let type = decl.bindings.compactMap({
//                  $0.typeAnnotation?.type
//              }).first, !type.is(StructDeclSyntax.self)  else {
//            return nil
//        }
//        return "\(type)"
//    }
//    
//    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
//        guard declaration.is(ClassDeclSyntax.self) else {
//            return []
//        }
//        let members = try declaration.memberBlock.members.compactMap(view(for:))
//        return [
//            """
//            convenience init(\(raw: members.reduce(into: [String]()) { strings, member in
//                    strings.append("\(member.name): \(member.type)")
//                if let assignment = member.assignment {
//                    strings[strings.index(before: strings.endIndex)] += " = \(assignment)"
//                }
//                }.joined(separator: ",\n"))) {
//                self.init()
//                \(raw: members.reduce(into: [String]()) { strings, member in
//                            strings.append("self.\(member.name) = \(member.name)")
//                }.joined(separator: "\n"))
//            }
//            """
//        ]
//    }
//    
//    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
//        let extendedType = type
//        let members = try declaration.memberBlock.members.compactMap(view(for:))
//        return [
//            .init(extendedType: type, inheritanceClause: .init(inheritedTypes: .init(arrayLiteral: .init(type: TypeSyntax(stringLiteral: "RawDocumentQueryRepresentable")))), memberBlock: """
//                {
//                    struct SyntaxView : ObjectSyntaxView {
//                        typealias RawDocumentValue = \(type)
//                        \(members.reduce(into: "") { string, member in
//                            if member.type.contains("any") && member.type.contains("RawDocumentRepresentable") {
//                                string += "let \(member.name): any MongoDataAccess.SyntaxView\n"
//                            } else {
//                                string += "let \(member.name): \(member.type).SyntaxView\n"
//                            }
//                        })
//                        init(from view: RawObjectSyntaxView) throws {
//                            \(raw: members.reduce(into: [String]()) { strings, member in
//                                if member.type.contains("any") && member.type.contains("RawDocumentRepresentable") {
//                                    strings.append("""
//                                    guard let \(member.name)View = view["\(member.attributeKey ?? member.name)"] else {
//                                            throw BSONError.missingKey("\(member.attributeKey ?? member.name)")
//                                    }
//                                    self.\(member.name) = \(member.name)View
//                                    """)
//                                } else {
//                                strings.append("""
//                                guard let \(member.name)View = try view["\(member.attributeKey ?? member.name)"]?.as(\(member.type).SyntaxView.self) else {
//                                        throw BSONError.missingKey("\(member.name)")
//                                }
//                                self.\(member.name) = \(member.name)View
//                                """)
//                                }
//                            }.joined(separator: "\n"))
//                            self.rawDocumentRepresentable = RawDocumentValue(\(raw: try 
//                            declaration.memberBlock.members.reduce(into: Array<String>()) { strings, member in
//                                try declName(member).map { name in
//                                    try declType(member).map { type in
//                                        strings.append("\(name): self.\(name).rawDocumentRepresentable")
//                                    }
//                                }
//                            }.joined(separator: ",\n")))
//                        }
//                        init(from rawDocumentValue: RawDocumentValue) {
//                            \(raw: try declaration.memberBlock.members.reduce(into: [String]()) { strings, member in
//                                try declName(member).map { name in
//                                    try declType(member).map { type in
//                                        if type.contains("any") && type.contains("RawDocumentRepresentable") {
//                                            strings.append("""
//                                            self.\(name) = rawDocumentValue.\(name).syntaxView
//                                            """)
//                                        } else {
//                                            strings.append("""
//                                            self.\(name) = \(type).SyntaxView(from: rawDocumentValue.\(name))
//                                            """)
//                                        }
//                                    }
//                                }
//                            }.joined(separator: "\n"))
//                            self.rawDocumentRepresentable = rawDocumentValue
//                        }
//                        let rawDocumentRepresentable: RawDocumentValue
//                        var rawObjectSyntaxView: RawObjectSyntaxView {
//                             [
//                                \(raw: try declaration.memberBlock.members.reduce(into: [String]()) { strings, member in
//                                try declName(member).map { name in
//                                    try declType(member).map { type in
//                                        strings.append("""
//                                        "\(name)": self.\(name)
//                                        """)
//                                    }
//                                    }
//                                }.joined(separator: ",\n"))
//                            ]
//                        }
//                    }
//                    static var keyPaths: [PartialKeyPath<\(extendedType)> : String] {
//                        [\(raw: try declaration.memberBlock.members.reduce(into: [String]()) { strings, member in
//                        try declName(member).map { name in
//                            try declType(member).map { type in
//                                strings.append("\\\(extendedType).\(name): \"\(name)\"")
//                            }
//                        }
//                        }.joined(separator: ",\n"))]
//                    }
//                }
//                """)
//        ]
//    }
//}

@main
struct MongoDataAccessMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BSONCodableMacro.self, 
//        MockMacro.self, MockMacro2.self, RawRepresentableUnionMacro.self, ObjectSyntaxViewMacro.self, RawDocumentQueryRepresentableMacro.self
    ]
}

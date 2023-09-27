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

public struct BSONCodableMacro : ExtensionMacro, MemberMacro, MemberAttributeMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AttributeSyntax] {
        [
            
        ]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        var typeName = "\(type)"
        if typeName.contains(".") {
            typeName = String(typeName.split(separator: ".")[1])
        }
        let lowercasedType = typeName.lowercasingFirstLetter()
        return [.init(extendedType: type, inheritanceClause: InheritanceClauseSyntax.init(inheritedTypes: .init(arrayLiteral: .init(type: TypeSyntax(stringLiteral: "RawDocumentObjectRepresentable")))), memberBlock: """
            {
                struct \(raw: typeName)SyntaxView : ObjectSyntaxViewProtocol {
                    package let objectView: ObjectSyntaxView
                    private let \(raw: lowercasedType): \(type)
                    init?(from objectView: ObjectSyntaxView) {
                        self.objectView = objectView
                        guard let document = objectView.rawDocumentRepresentable as? [String : any RawDocumentRepresentable] else {
                            return nil
                        }
                        do {
                            self.\(raw: lowercasedType) = try \(raw: type).init(from: document)
                        } catch {
                            print(error)
                            return nil
                        }
                    }
                    package init(allowedObjectTypes: [any ObjectSyntaxViewProtocol.Type], @SyntaxViewBuilder fields: () -> [FieldSyntaxView]) {
                        var objectView = ObjectSyntaxView(fields: fields)
                        objectView.allowedObjectTypes = \(raw: type).rawDocumentObjectRepresentableSchema + defaultSchema
                        objectView.objectType = Self.self
                        objectView.fields = Self.fields
                        self.init(from: objectView)!
                    }
                    var startIndex: String.Index {
                        objectView.endIndex
                    }
                    
                    var endIndex: String.Index {
                        objectView.endIndex
                    }
                    
                    var description: String {
                        objectView.description
                    }
                    var rawDocumentRepresentable: any RawDocumentRepresentable {
                        \(raw: lowercasedType)
                    }
                    static var fields: [String : any MongoDataAccess.SyntaxView.Type] {
                        [
                            \(raw: declaration.memberBlock.members.compactMap { member in
                                guard let decl = member.decl.as(VariableDeclSyntax.self),
                                    let binding = decl.bindings.compactMap({
                                        $0.pattern.as(IdentifierPatternSyntax.self)
                                    }).first,
                                      let type = decl.bindings.compactMap({
                                          $0.typeAnnotation?.type
                                      }).first, !type.is(StructDeclSyntax.self)
                                else { return nil }
                                let typeString = type.description == "any RawDocumentRepresentable" ? "MongoDataAccess.AnyValueSyntaxView.self" :
                "\(type).SyntaxView.self"
                                return """
                                "\(binding)": \(typeString)
                                """
                            }.joined(separator: ","))
                        ]
                    }
                }
                public var syntaxView: \(raw: typeName)SyntaxView {
                    \(raw: typeName)SyntaxView(allowedObjectTypes: Self.rawDocumentObjectRepresentableSchema) {
                        \(raw: declaration.memberBlock.members.compactMap { member in
                            guard let decl = member.decl.as(VariableDeclSyntax.self),
                                let binding = decl.bindings.compactMap({
                                    $0.pattern.as(IdentifierPatternSyntax.self)
                                }).first
                            else { return nil }

                            return """
                            FieldSyntaxView(key: "\(binding)", value: \(binding).syntaxView)
                            """
                        }.joined(separator: "\n"))
                    }
                }
                static var rawDocumentObjectRepresentableSchema: [any ObjectSyntaxViewProtocol.Type] {
                    var rawDocumentObjectRepresentableSchema: [any ObjectSyntaxViewProtocol.Type] = []
                    rawDocumentObjectRepresentableSchema.append(Self.SyntaxView.self)
                    func syntaxViewType<T: RawDocumentObjectRepresentable>(_ t: T.Type) -> [any ObjectSyntaxViewProtocol.Type] {
                        return [T.SyntaxView.self] + t.rawDocumentObjectRepresentableSchema
                    }
                    \(raw: declaration.memberBlock.members.compactMap { member in
                        guard let decl = member.decl.as(VariableDeclSyntax.self),
                            let binding = decl.bindings.compactMap({
                                $0.pattern.as(IdentifierPatternSyntax.self)
                            }).first,
                            let type = decl.bindings.compactMap({
                                $0.typeAnnotation?.type
                            }).first, !type.is(StructDeclSyntax.self)
                        else { return nil }
                        if type.description == "any RawDocumentRepresentable" {
                            return ""
                        }
                        return """
                        if let type = \(type).self as? any RawDocumentObjectRepresentable.Type {
                            rawDocumentObjectRepresentableSchema.append(contentsOf: syntaxViewType(type))
                        }
                        """
                    }.joined(separator: "\n"))
                    return rawDocumentObjectRepresentableSchema
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
        return [
            """
            init(\(raw: try declaration.memberBlock.members.compactMap(declAsArg).joined(separator: ","))) {
                \(raw: declaration.memberBlock.members.compactMap(declName).map {
                """
                self.\($0) = \($0)
                """
                }.joined(separator: "\n"))
            }
            """,
            """
            init(from document: RawDocument) throws {
                \(raw: declaration.memberBlock.members.compactMap { member in
                    guard let decl = member.decl.as(VariableDeclSyntax.self),
                        let binding = decl.bindings.compactMap({
                            $0.pattern.as(IdentifierPatternSyntax.self)
                        }).first,
                      let type = decl.bindings.compactMap({
                          $0.typeAnnotation?.type
                      }).first, !type.is(StructDeclSyntax.self)
                    else { return nil }

                    return """
                    guard let \(binding.identifier) = document["\(binding.identifier)"] else {
                        throw BSONError.missingKey("\(binding.identifier)")
                    }
                    guard let \(binding.identifier): \(type) = try \(binding.identifier) as? \(type) else {
                        throw BSONError.invalidType(key: "\(binding.identifier)")
                    }
                    self.\(binding.identifier) = \(binding.identifier)
                    """
                }.joined(separator: "\n"))
            }
            """,
            """
            func encode(to document: inout RawDocument) {
                \(raw: declaration.memberBlock.members.compactMap { member in
                    guard let decl = member.decl.as(VariableDeclSyntax.self),
                        let binding = decl.bindings.compactMap({
                            $0.pattern.as(IdentifierPatternSyntax.self)
                        }).first
                    else { return nil }

                    return """
                    document["\(binding.identifier)"] = \(binding)
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
                mutating func encode() -> RawDocument {
                    return documentRef.document
                }
            }
            """,
            """
            typealias Id = \(raw: try declaration.memberBlock.members.compactMap({ (declName($0), try declType($0)) })
                .first(where: {$0.0 == "_id"})?.1 ?? "ObjectId")
            """
        ]
    }
}

public struct MockMacro : PeerMacro, DeclarationMacro {
    // freestanding
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        let object = node.argumentList[node.argumentList.startIndex]
        guard let selector = node.argumentList[node.argumentList.index(after: node.argumentList.startIndex)].expression.as(MacroExpansionExprSyntax.self)?.argumentList.first?.expression.as(IdentifierExprSyntax.self)?.identifier else {
            throw BSONCodableMacro.Error.invalidDeclaration("\(node.argumentList[node.argumentList.index(after: node.argumentList.startIndex)].expression.debugDescription)")
        }
        return [
            """
            object_setClass(\(object.expression), __\(selector).self)
            """
        ]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let fn = declaration.as(FunctionDeclSyntax.self) else {
            throw BSONCodableMacro.Error.invalidDeclaration("\(declaration)")
        }
        return [
            """
            @objc class __\(raw: fn.identifier) : NSObject {
                @objc func \(raw: fn.identifier)\(raw: fn.signature)\(raw: fn.body!)
            }
            """
        ]
    }
    
}


public struct MockMacro2 : DeclarationMacro, ExpressionMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        let object = node.argumentList[node.argumentList.startIndex]
        guard let closure = node.trailingClosure else {
            throw BSONCodableMacro.Error.invalidDeclaration("\(node.argumentList[node.argumentList.index(after: node.argumentList.startIndex)].expression.debugDescription)")
        }
        let name = context.makeUniqueName("Mock")
        
        let statements = closure.statements.map {
            if let fn = $0.item.as(FunctionDeclSyntax.self) {
                return "@objc \(fn)"
            } else {
                return "\($0)"
            }
        }.joined(separator: "\n")
        return
            """
            _ = {
                @objc class \(name) : NSObject {
                    \(raw: statements)
                }
                object_setClass(\(object.expression), \(name).self)
            }()
            """
    }
    
    // freestanding
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        let object = node.argumentList[node.argumentList.startIndex]
        guard let closure = node.trailingClosure else {
            throw BSONCodableMacro.Error.invalidDeclaration("\(node.argumentList[node.argumentList.index(after: node.argumentList.startIndex)].expression.debugDescription)")
        }
        let name = context.makeUniqueName("Mock")
        
        let statements = closure.statements.map {
            if let fn = $0.item.as(FunctionDeclSyntax.self) {
                return "@objc \(fn)"
            } else {
                return "\($0)"
            }
        }.joined(separator: "\n")
        return [
            """
            let _ = {
                @objc class \(name) : NSObject {
                    \(raw: statements)
                }
                object_setClass(\(object.expression), \(name).self)
            }()
            """
        ]
    }
    
}


public struct RawRepresentableUnionMacro : MemberMacro, ExtensionMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let caseAndTypes: [(case: TokenSyntax, type: TypeSyntax)] = declaration.memberBlock.members.compactMap({ (member) -> (case: TokenSyntax, type: TypeSyntax)? in
            guard let caseElement = member.decl.as(EnumCaseDeclSyntax.self)?.elements.first,
                  let identifier = caseElement.parameterClause?.parameters.first?.type else {
                return nil
            }
            return (case: caseElement.name, type: identifier)
        })
        return [
            .init(extendedType: type,
//                  inheritanceClause: .init(inheritedTypes: .init(arrayLiteral: .init(type: TypeSyntax(stringLiteral: "RawDocumentRepresentable")))), 
                  memberBlock: """
                {
                \(raw: caseAndTypes.map {
                    """
                    init(_ \($0.case): \($0.type)) {
                        self = .\($0.case)(\($0.case))
                    }
                    """
                }.joined(separator: "\n"))
                public var rawValue: any RawDocumentRepresentable {
                    switch self {
                    \(raw: caseAndTypes.map {
                        """
                        case .\($0.case)(let value): return value.rawValue
                        """
                    }.joined(separator: "\n"))
                    }
                }
                public var value: any RawDocumentRepresentable {
                    switch self {
                    \(raw: caseAndTypes.map {
                        """
                        case .\($0.case)(let value): return value
                        """
                    }.joined(separator: "\n"))
                    }
                }
                }
                """)
        ]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        let caseAndTypes: [(case: TokenSyntax, type: TypeSyntax)] = declaration.memberBlock.members.compactMap({ (member) -> (case: TokenSyntax, type: TypeSyntax)? in
            guard let caseElement = member.decl.as(EnumCaseDeclSyntax.self)?.elements.first,
                  let identifier = caseElement.parameterClause?.parameters.first?.type else {
                return nil
            }
            return (case: caseElement.name, type: identifier)
        })
        var newMembers = caseAndTypes.map {
            """
            init(_ \($0.case): \($0.type)) {
                self = .\($0.case)(\($0.case))
            }
            """
        }
//        newMembers.append("""
//        enum CodingKeys : CodingKey {
//            case \(caseAndTypes.map(\.case).map { "\($0)" }.joined(separator: ","))
//        }
//        """)
        newMembers.append("""
        package init(_ value: any RawDocumentRepresentable) {
            switch value {
            \(caseAndTypes.map {
                """
                case let value as \($0.type): self = .\($0.case)(value)
                """
            }.joined(separator: "\n"))
                default: fatalError("Value is not RawDocumentRepresentable")
            }
        }
        """)
//        newMembers.append("""
//        package init(from decoder: Decoder) throws {
//            let container = try decoder.container(keyedBy: CodingKeys.self)
//            \(caseAndTypes.map {
//                """
//                if container.contains(.\($0.case)) {
//                    self = try .\($0.case)(\($0.type)(from: container.decode(\($0.type).RawDocumentValue.self, forKey: .\($0.case))))
//                }
//                """
//            }.joined(separator: "\n else "))
//            else {
//                fatalError()
//            }
//        }
//        """)
//        newMembers.append("""
//        package func encode(to encoder: Encoder) throws {
//            var container = encoder.container(keyedBy: CodingKeys.self)
//            switch self {
//            \(caseAndTypes.map {
//                """
//                
//                case .\($0.case)(let value): try container.encode(value.rawValue, forKey: .\($0.case))
//                """
//            }.joined(separator: "\n"))
//            }
//        }
//        """)
//        newMembers.append("""
//        public var rawValue: any RawDocumentRepresentable {
//            switch self {
//            \(caseAndTypes.map {
//                """
//                case .\($0.case)(let value): return value.rawValue
//                """
//            }.joined(separator: "\n"))
//            }
//        }
//        """)
        newMembers.append("""
        public var value: any RawDocumentRepresentable {
            switch self {
            \(caseAndTypes.map {
                """
                case .\($0.case)(let value): return value.value
                """
            }.joined(separator: "\n"))
            }
        }
        """)
        return newMembers.map(DeclSyntax.init)
    }
}

public struct ObjectSyntaxViewMacro : MemberMacro, ExtensionMacro {
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
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        [
            "let rawDocumentRepresentable: RawDocumentRepresentable",
            "let rawObjectSyntaxView: RawObjectSyntaxView"
        ]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        var initSyntax = try declaration.memberBlock.members.compactMap { member in
            try declName(member).map({ name in try declType(member).map({ (name, $0) }) })
        }.map {
            
        }
        return [
            .init(extendedType: type, inheritanceClause: InheritanceClauseSyntax(inheritedTypes: .init(arrayLiteral: InheritedTypeSyntax.init(type: TypeSyntax(stringLiteral: "ObjectSyntaxView")))),
                  memberBlock: """
            {
                init(from rawDocumentRepresentable: RawDocumentValue) {
                    self.rawObjectSyntaxView = RawObjectSyntaxView {
                        \(raw: try declaration.memberBlock.members.compactMap { member in
                            try declName(member).flatMap({ name in try declType(member).map({ (name: name, type: $0) }) })
                        }.map {
                            "FieldSyntaxView(key: \"\($0.name)\", value: \($0.type).syntaxView)"
                        })
                    }
                    self.rawDocumentRepresentable = rawDocumentRepresentable
                }
                init?(from view: RawObjectSyntaxView) {
                    self.rawObjectSyntaxView = raw
                    \(raw: try declaration.memberBlock.members.compactMap { member in
                        try declName(member).flatMap({ name in try declType(member).map({ (name: name, type: $0) }) })
                    }.map {
                        "FieldSyntaxView(key: \"\($0.name)\", value: \($0.type).syntaxView)"
                    })
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
            }
            """)
        ]
    }
}

public struct RawDocumentQueryRepresentableMacro : MemberMacro, ExtensionMacro, PeerMacro {
    private struct MemberView {
        let name: String
        let type: String
        var attributeKey: String?
        var assignment: String?
    }
    enum Error : Swift.Error {
        case blah(String)
    }
    private static func view(for member: MemberBlockItemListSyntax.Element) throws -> MemberView? {
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
        var memberView = MemberView(name: "\(binding.identifier)", type: "\(type)", attributeKey: nil)
        if let macroName = decl.attributes.first(where: { element in
                element.as(AttributeSyntax.self)?.attributeName
                .as(IdentifierTypeSyntax.self)?.name.text == "DocumentKey"
            })?.as(AttributeSyntax.self)?
            .arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(StringLiteralExprSyntax.self) {
            memberView.attributeKey = "\(macroName.segments)"
        }
        if let assignment = decl.bindings.compactMap({
            $0.initializer?.value
        }).first {
            memberView.assignment = "\(assignment)"
        }
        return memberView
    }
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        []
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
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            return []
        }
        let members = try declaration.memberBlock.members.compactMap(view(for:))
        return [
            """
            convenience init(\(raw: members.reduce(into: [String]()) { strings, member in
                    strings.append("\(member.name): \(member.type)")
                if let assignment = member.assignment {
                    strings[strings.index(before: strings.endIndex)] += " = \(assignment)"
                }
                }.joined(separator: ",\n"))) {
                self.init()
                \(raw: members.reduce(into: [String]()) { strings, member in
                            strings.append("self.\(member.name) = \(member.name)")
                }.joined(separator: "\n"))
            }
            """
        ]
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let extendedType = type
        let members = try declaration.memberBlock.members.compactMap(view(for:))
        return [
            .init(extendedType: type, inheritanceClause: .init(inheritedTypes: .init(arrayLiteral: .init(type: TypeSyntax(stringLiteral: "RawDocumentQueryRepresentable")))), memberBlock: """
                {
                    struct SyntaxView : ObjectSyntaxView {
                        typealias RawDocumentValue = \(type)
                        \(members.reduce(into: "") { string, member in
                            if member.type.contains("any") && member.type.contains("RawDocumentRepresentable") {
                                string += "let \(member.name): any MongoDataAccess.SyntaxView\n"
                            } else {
                                string += "let \(member.name): \(member.type).SyntaxView\n"
                            }
                        })
                        init(from view: RawObjectSyntaxView) throws {
                            \(raw: members.reduce(into: [String]()) { strings, member in
                                if member.type.contains("any") && member.type.contains("RawDocumentRepresentable") {
                                    strings.append("""
                                    guard let \(member.name)View = view["\(member.attributeKey ?? member.name)"] else {
                                            throw BSONError.missingKey("\(member.attributeKey ?? member.name)")
                                    }
                                    self.\(member.name) = \(member.name)View
                                    """)
                                } else {
                                strings.append("""
                                guard let \(member.name)View = try view["\(member.attributeKey ?? member.name)"]?.as(\(member.type).SyntaxView.self) else {
                                        throw BSONError.missingKey("\(member.name)")
                                }
                                self.\(member.name) = \(member.name)View
                                """)
                                }
                            }.joined(separator: "\n"))
                            self.rawDocumentRepresentable = RawDocumentValue(\(raw: try 
                            declaration.memberBlock.members.reduce(into: Array<String>()) { strings, member in
                                try declName(member).map { name in
                                    try declType(member).map { type in
                                        strings.append("\(name): self.\(name).rawDocumentRepresentable")
                                    }
                                }
                            }.joined(separator: ",\n")))
                        }
                        init(from rawDocumentValue: RawDocumentValue) {
                            \(raw: try declaration.memberBlock.members.reduce(into: [String]()) { strings, member in
                                try declName(member).map { name in
                                    try declType(member).map { type in
                                        if type.contains("any") && type.contains("RawDocumentRepresentable") {
                                            strings.append("""
                                            self.\(name) = rawDocumentValue.\(name).syntaxView
                                            """)
                                        } else {
                                            strings.append("""
                                            self.\(name) = \(type).SyntaxView(from: rawDocumentValue.\(name))
                                            """)
                                        }
                                    }
                                }
                            }.joined(separator: "\n"))
                            self.rawDocumentRepresentable = rawDocumentValue
                        }
                        let rawDocumentRepresentable: RawDocumentValue
                        var rawObjectSyntaxView: RawObjectSyntaxView {
                             [
                                \(raw: try declaration.memberBlock.members.reduce(into: [String]()) { strings, member in
                                try declName(member).map { name in
                                    try declType(member).map { type in
                                        strings.append("""
                                        "\(name)": self.\(name)
                                        """)
                                    }
                                    }
                                }.joined(separator: ",\n"))
                            ]
                        }
                    }
                    static var keyPaths: [PartialKeyPath<\(extendedType)> : String] {
                        [\(raw: try declaration.memberBlock.members.reduce(into: [String]()) { strings, member in
                        try declName(member).map { name in
                            try declType(member).map { type in
                                strings.append("\\\(extendedType).\(name): \"\(name)\"")
                            }
                        }
                        }.joined(separator: ",\n"))]
                    }
                }
                """)
        ]
    }
    
    
}
@main
struct MongoDataAccessMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BSONCodableMacro.self, MockMacro.self, MockMacro2.self, RawRepresentableUnionMacro.self, ObjectSyntaxViewMacro.self, RawDocumentQueryRepresentableMacro.self
    ]
}

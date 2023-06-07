import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
) throws -> [AttributeSyntax] {
    return []
    guard let property = member.as(VariableDeclSyntax.self), property.bindings.count == 1 else {
        return []
    }

    if let attributes = property.attributes {
        for attr in attributes {
            if case let .attribute(attr) = attr {
                if attr.attributeName.as(SimpleTypeIdentifierSyntax.self)?.name.text == "Ignored" {
                    return []
                }
            }
        }
    }

    let binding = property.bindings.first!
    switch binding.accessor {
    case .none:
        break
    case .accessors(let node):
        for accessor in node.accessors {
            switch accessor.accessorKind.tokenKind {
            case .keyword(.get), .keyword(.set):
                return []
            default:
                break
            }
        }
        break
    case .getter:
        return []
    }

    return [
        AttributeSyntax(
            attributeName: SimpleTypeIdentifierSyntax(name: .identifier("Persisted"))
        )
        .with(\.leadingTrivia, [.newlines(1), .spaces(2)])
    ]
}

enum RealmSchemaDiscoveryError: CustomStringConvertible, Error {
    case missingTypeAnnotation
    case noProperties

    var description: String {
        switch self {
        case .missingTypeAnnotation:
            return "@RealmSchemaDiscovery requires an explicit type annotation for all @Persisted properties and cannot infer the type from the default value"
        case .noProperties:
            return "No properties found in @RealmModel class. All object types must have at least one persisted property."
        }
    }
}

public struct RealmSchemaDiscovery: MemberMacro, ConformanceMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        return [(TypeSyntax("RealmSwift._RealmObjectSchemaDiscoverable"), nil)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(ClassDeclSyntax.self) else { fatalError() }
        let className = declaration.identifier
        let properties = try declaration.memberBlock.members.compactMap { (decl) -> (String, String, AttributeSyntax)? in
            guard let property = decl.decl.as(VariableDeclSyntax.self), property.bindings.count == 1 else {
                return nil
            }
            guard let attributes = property.attributes else { return nil }
            let persistedAttr = attributes.compactMap { attr in
                if case let .attribute(attr) = attr {
                    if attr.attributeName.as(SimpleTypeIdentifierSyntax.self)?.name.text == "Persisted" {
                        return attr
                    }
                }
                return nil
            }.first
            guard let persistedAttr else { return nil }

            let binding = property.bindings.first!
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else { return nil }
            guard let typeAnnotation = binding.typeAnnotation else {
                throw RealmSchemaDiscoveryError.missingTypeAnnotation
            }
            let name = identifier.identifier.text
            let type = typeAnnotation.type.trimmedDescription
            return (name, type, persistedAttr)
        }

        let rlmProperties = properties.map { (name, type, persistedAttr) in
            let expr = ExprSyntax("RLMProperty(name: \(literal: name), type: \(raw: type).self, keyPath: \\\(className).\(raw: name))")
            var functionCall = expr.as(FunctionCallExprSyntax.self)!

            if let argument = persistedAttr.argument, case let .argumentList(argList) = argument {
                var argumentList = Array(functionCall.argumentList)
                argumentList[argumentList.count - 1].trailingComma = ", "
                argumentList.append(contentsOf: argList)
                functionCall.argumentList = TupleExprElementListSyntax(argumentList)
            }
            return functionCall.as(ExprSyntax.self)!
        }
        return ["""

        static var _realmProperties: [RLMProperty] = \(ArrayExprSyntax {
            for property in rlmProperties {
                ArrayElementSyntax(expression: property)
            }
            })
        """]
    }
}

func validatedProperty(_ property: some DeclSyntaxProtocol) -> VariableDeclSyntax? {
    guard let property = property.as(VariableDeclSyntax.self), property.bindings.count == 1 else {
        return nil
    }

    if property.modifiers != nil {
        return nil
    }

    if let attributes = property.attributes {
        for attr in attributes {
            if case let .attribute(attr) = attr {
                if attr.attributeName.as(SimpleTypeIdentifierSyntax.self)?.name.text == "Ignored" {
                    return nil
                }
            }
        }
    }

    let binding = property.bindings.first!
    switch binding.accessor {
    case .none:
        break
    case .accessors(let node):
        for accessor in node.accessors {
            switch accessor.accessorKind.tokenKind {
            case .keyword(.get), .keyword(.set):
                return nil
            default:
                break
            }
        }
        break
    case .getter:
        return nil
    }
    return property
}

func appendArgument(_ call: inout FunctionCallExprSyntax, label: TokenSyntax, expression: some ExprSyntaxProtocol) {
    let trivia: Trivia? = call.argumentList.isEmpty ? nil : ", "
    call = call.addArgument(TupleExprElementSyntax(leadingTrivia: trivia, label: label, colon: ": ", expression: expression))
}

struct Property {
    var parentName: TokenSyntax
    var name: TokenSyntax
    var index: Int
    var indexed: Bool = false
    var primaryKey: Bool = false
    var originProperty: ExprSyntax? = nil

    var rlmProperty: FunctionCallExprSyntax {
        var call = ExprSyntax("RLMProperty(name: \(literal: name.text), index: \(literal: index), keyPath: \(keyPath))").as(FunctionCallExprSyntax.self)!
        if primaryKey {
            appendArgument(&call, label: "primaryKey", expression: BooleanLiteralExprSyntax(booleanLiteral: true))
        }
        else if indexed {
            appendArgument(&call, label: "indexed", expression: BooleanLiteralExprSyntax(booleanLiteral: true))
        }
        if let originProperty {
            appendArgument(&call, label: "originProperty", expression: originProperty)
        }
        return call
    }

    var rlmProperty2: FunctionCallExprSyntax {
        var call = ExprSyntax("RLMProperty(name: \(literal: name.text), keyPath: \(keyPath))").as(FunctionCallExprSyntax.self)!
        if primaryKey {
            appendArgument(&call, label: "primaryKey", expression: BooleanLiteralExprSyntax(booleanLiteral: true))
        }
        else if indexed {
            appendArgument(&call, label: "indexed", expression: BooleanLiteralExprSyntax(booleanLiteral: true))
        }
        if let originProperty {
            appendArgument(&call, label: "originProperty", expression: originProperty)
        }
        return call
    }

    var keyPath: ExprSyntax {
        "\\\(parentName).\(name)"
    }
}

func getProperties(ofClass cls: ClassDeclSyntax) -> [Property] {
    var index = 0
    return cls.memberBlock.members.compactMap { (member) -> Property? in
        guard let property = validatedProperty(member.decl),
              let binding = property.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            return nil
        }
        var p = Property(parentName: cls.identifier, name: identifier.identifier, index: index)
        index += 1

        if let attributes = property.attributes {
            for attribute in attributes.compactMap({ $0.as(AttributeSyntax.self) }) {
                switch attribute.attributeName.trimmedDescription {
                case "PrimaryKey", "RealmSwift.PrimaryKey":
                    p.primaryKey = true
                case "Indexed", "RealmSwift.Indexed":
                    p.indexed = true
                case "OriginProperty", "RealmSwift.OriginProperty":
                    p.originProperty = attribute.argument?.as(TupleExprElementListSyntax.self)?.first?.expression
                default:
                    print("Unrecognized attribute: \(attribute.attributeName.trimmedDescription)")
                    break
                }
            }
        }

        return p
    }
}

public struct RealmObjectMacro: MemberMacro, ConformanceMacro, MemberAttributeMacro {
    static public func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let property = validatedProperty(member) else { return [] }
        guard let cls = declaration.as(ClassDeclSyntax.self) else { return [] }
        var index = 0
        let description = property.trimmedDescription
        for decl in cls.memberBlock.members {
            if decl.decl.trimmedDescription == description {
                break;
            }
            if validatedProperty(decl.decl) != nil {
                index += 1
            }
        }

        return ["@_PersistedProperty(index: \(raw: index))"]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        return [(TypeSyntax("RealmSwift._RealmObjectSchemaDiscoverable"), nil)]
    }


    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(ClassDeclSyntax.self) else { fatalError() }
        let properties = getProperties(ofClass: declaration)
        if properties.isEmpty {
            throw RealmSchemaDiscoveryError.noProperties
        }
        return [
            "@Ignored private var _realmUnmanagedStorage = _unmanagedStorage(\(raw: properties.map(\.keyPath).map(\.trimmedDescription).joined(separator: ", ")))",
            "public static var _realmProperties: [RLMProperty] = [\n\(raw: properties.map(\.rlmProperty).map(\.trimmedDescription).joined(separator: ",\n"))\n]"
        ]
    }
}

public struct RealmObjectMacro2: MemberMacro, ConformanceMacro, MemberAttributeMacro {
    static public func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let property = validatedProperty(member) else { return [] }
        guard let cls = declaration.as(ClassDeclSyntax.self) else { return [] }
        var index = 0
        let description = property.trimmedDescription
        for decl in cls.memberBlock.members {
            if decl.decl.trimmedDescription == description {
                break;
            }
            if validatedProperty(decl.decl) != nil {
                index += 1
            }
        }

        return ["@_PersistedProperty(index: \(raw: index))"]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        return [(TypeSyntax("RealmSwift._RealmObjectSchemaDiscoverable"), nil)]
    }


    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(ClassDeclSyntax.self) else { fatalError() }
        let properties = getProperties(ofClass: declaration)
        if properties.isEmpty {
            throw RealmSchemaDiscoveryError.noProperties
        }
        return [
            "public static var _realmProperties: [RLMProperty] = [\n\(raw: properties.map(\.rlmProperty2).map(\.trimmedDescription).joined(separator: ",\n"))\n]"
        ]
    }
}

public struct Marker: AccessorMacro {
    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        return []
    }
}

public struct PersistedProperty: AccessorMacro {
    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
//        let prop = validatedProperty(declaration)
        let index = node.argument!.as(TupleExprElementListSyntax.self)!.first!.expression
        return [
            """
                get {
                    if let unmanaged = _realmUnmanagedStorage {
                        return unmanaged.\(index)
                    } else {
                        return RealmSwift._getProperty(self, \(index))
                    }
                }
            """,
            """
                set {
                    if _realmUnmanagedStorage != nil {
                        _realmUnmanagedStorage!.\(index) = newValue
                    } else {
                        RealmSwift._setProperty(self, \(index), newValue)
                    }
                }
            """,
        ]
    }
}

public struct PersistedProperty2: AccessorMacro, PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let prop = validatedProperty(declaration)!.bindings.first!
        let name = prop.pattern.as(IdentifierPatternSyntax.self)!.identifier
        let type = prop.typeAnnotation!.type.trimmed
        let ret: [DeclSyntax] = ["@Ignored var _$\(name) = PropertyStorage<\(type)>.unmanagedNoDefault()"]
        print("\(ret[0].description)")
        return ret
    }
    
    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        let name = validatedProperty(declaration)!.bindings.first!.pattern.as(IdentifierPatternSyntax.self)!.identifier
        return [
            """
                get {
                    _$\(name).get(self)
                }
            """,
            """
                set {
                    _$\(name).set(self, value: newValue)
                }
            """,
        ]
    }
}

@main
struct RealmMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RealmSchemaDiscovery.self,
        RealmObjectMacro.self,
        RealmObjectMacro2.self,
        Marker.self,
        PersistedProperty.self,
        PersistedProperty2.self,
    ]
}

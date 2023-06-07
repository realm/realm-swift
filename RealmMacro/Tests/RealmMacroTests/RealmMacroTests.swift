import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import RealmMacroMacros
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftParser
import SwiftBasicFormat

final class RealmMacroTests: XCTestCase {
    func _testStuff() {
        assertMacroExpansion(
            #"""
            @RealmModel class MacroObject: Object {
                @PrimaryKey var pk: ObjectId
                @Ignored var ignored: Int = 1
                var intCol: Int = 2
                @Indexed var indexed: Int
                var obj: MacroObject?
                @OriginProperty(name: "obj")
                var linkingObjects: LinkingObjects<MacroObject>
            }
            """#,
            expandedSource: #"""
            class MacroObject: Object {
                var pk: ObjectId {
                    get {
                        if let unmanaged = _realmUnmanagedStorage {
                            return unmanaged.0
                        } else {
                            return ObjectId._rlmGetProperty(self, 0)
                        }
                    }
                    set {
                        if _realmUnmanagedStorage != nil {
                            _realmUnmanagedStorage!.0 = newValue
                        } else {
                            ObjectId._rlmSetProperty(self, 0, newValue)
                        }
                    }
                }
                var ignored: Int = 1
                var intCol: Int {
                    get {
                        if let unmanaged = _realmUnmanagedStorage {
                            return unmanaged.1
                        } else {
                            return Int._rlmGetProperty(self, 1)
                        }
                    }
                    set {
                        if _realmUnmanagedStorage != nil {
                            _realmUnmanagedStorage!.1 = newValue
                        } else {
                            Int._rlmSetProperty(self, 1, newValue)
                        }
                    }
                }
                var indexed: Int {
                    get {
                        if let unmanaged = _realmUnmanagedStorage {
                            return unmanaged.2
                        } else {
                            return Int._rlmGetProperty(self, 2)
                        }
                    }
                    set {
                        if _realmUnmanagedStorage != nil {
                            _realmUnmanagedStorage!.2 = newValue
                        } else {
                            Int._rlmSetProperty(self, 2, newValue)
                        }
                    }
                }
                var obj: MacroObject? {
                    get {
                        if let unmanaged = _realmUnmanagedStorage {
                            return unmanaged.3
                        } else {
                            return MacroObject?._rlmGetProperty(self, 3)
                        }
                    }
                    set {
                        if _realmUnmanagedStorage != nil {
                            _realmUnmanagedStorage!.3 = newValue
                        } else {
                            MacroObject?._rlmSetProperty(self, 3, newValue)
                        }
                    }
                }
                var linkingObjects: LinkingObjects<MacroObject> {
                    get {
                        if let unmanaged = _realmUnmanagedStorage {
                            return unmanaged.4
                        } else {
                            return LinkingObjects<MacroObject> ._rlmGetProperty(self, 4)
                        }
                    }
                    set {
                        if _realmUnmanagedStorage != nil {
                            _realmUnmanagedStorage!.4 = newValue
                        } else {
                            LinkingObjects<MacroObject> ._rlmSetProperty(self, 4, newValue)
                        }
                    }
                }
                private var _realmUnmanagedStorage: (ObjectId, Int, Int, MacroObject?, LinkingObjects<MacroObject>)? = nil
                public static var _realmProperties: [RLMProperty] = [
                    RLMProperty(name: "pk", index: 0, keyPath: \MacroObject.pk),
                    RLMProperty(name: "intCol", index: 1, keyPath: \MacroObject.intCol),
                    RLMProperty(name: "indexed", index: 2, keyPath: \MacroObject.indexed),
                    RLMProperty(name: "obj", index: 3, keyPath: \MacroObject.obj),
                    RLMProperty(name: "linkingObjects", index: 4, keyPath: \MacroObject.linkingObjects)
                ]
            }
            extension MacroObject: RealmSwift._RealmObjectSchemaDiscoverable {
            }
            """#,
            macros: [
                "RealmModel": RealmObjectMacro.self,
                "PrimaryKey": Marker.self,
                "Indexed": Marker.self,
                "Ignored": Marker.self,
                "OriginProperty": Marker.self,
                "_PersistedProperty": PersistedProperty.self
            ])
    }

    func testStuff2() {
        assertMacroExpansion(
            #"""
            @RealmModel class MacroObject: Object {
                @PrimaryKey var pk: ObjectId
                @Ignored var ignored: Int = 1
                var intCol: Int = 2
                @Indexed var indexed: Int
                var obj: MacroObject?
                @OriginProperty(name: "obj")
                var linkingObjects: LinkingObjects<MacroObject>
            }
            """#,
            expandedSource: #"""
            class MacroObject: Object {
                var pk: ObjectId {
                    get {
                        _$pk.get(self)
                    }
                    set {
                        _$pk.set(self, newValue)
                    }
                }
                var _$pk: PropertyStorage<ObjectId> = .unmanagedNoDefault
                var ignored: Int = 1
                var intCol: Int {
                    get {
                        _$intCol.get(self)
                    }
                    set {
                        _$intCol.set(self, newValue)
                    }
                }
                var _$intCol: PropertyStorage<Int> = .unmanagedNoDefault
                var indexed: Int {
                    get {
                        _$indexed.get(self)
                    }
                    set {
                        _$indexed.set(self, newValue)
                    }
                }
                var _$indexed: PropertyStorage<Int> = .unmanagedNoDefault
                var obj: MacroObject? {
                    get {
                        _$obj.get(self)
                    }
                    set {
                        _$obj.set(self, newValue)
                    }
                }
                var _$obj: PropertyStorage<MacroObject?> = .unmanagedNoDefault
                var linkingObjects: LinkingObjects<MacroObject> {
                    get {
                        _$linkingObjects.get(self)
                    }
                    set {
                        _$linkingObjects.set(self, newValue)
                    }
                }
                var _$linkingObject: PropertyStorage<LinkingObjects<MacroObject>> = .unmanagedNoDefault
                public static var _realmProperties: [RLMProperty] = [
                    RLMProperty(name: "pk", keyPath: \MacroObject.pk, primaryKey: true),
                    RLMProperty(name: "intCol", keyPath: \MacroObject.intCol),
                    RLMProperty(name: "indexed", keyPath: \MacroObject.indexed, indexed: true),
                    RLMProperty(name: "obj", keyPath: \MacroObject.obj),
                    RLMProperty(name: "linkingObjects", keyPath: \MacroObject.linkingObjects, originProperty: "obj")
                ]
            }
            extension MacroObject: RealmSwift._RealmObjectSchemaDiscoverable {
            }
            """#,
            macros: [
                "RealmModel": RealmObjectMacro2.self,
                "PrimaryKey": Marker.self,
                "Indexed": Marker.self,
                "Ignored": Marker.self,
                "OriginProperty": Marker.self,
                "_PersistedProperty": PersistedProperty2.self
            ])
    }

    func testStuff3() {
        assertMacroExpansion(
            #"""
            class MacroObject: Object {
                @_PersistedProperty var pk: ObjectId
                @_PersistedProperty var intCol: Int = 2
            }
            """#,
            expandedSource: #"""
            class MacroObject: Object {
                var pk: ObjectId {
                    get {
                        _$pk.get(self)
                    }
                    set {
                        _$pk.set(self, value: newValue)
                    }
                }
                @Ignored var _$pk: PropertyStorage<ObjectId> = .unmanagedNoDefault
                var intCol: Int = 2 {
                    get {
                        _$intCol.get(self)
                    }
                    set {
                        _$intCol.set(self, value: newValue)
                    }
                }
                @Ignored var _$intCol: PropertyStorage<Int> = .unmanagedNoDefault
            }
            """#,
            macros: [
                "_PersistedProperty": PersistedProperty2.self
            ])

    }
}

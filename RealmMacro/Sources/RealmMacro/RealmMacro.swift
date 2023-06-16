@attached(conformance)
@attached(member, names: named(_realmProperties))
//@attached(memberAttribute)
public macro RealmSchemaDiscovery() -> Void = #externalMacro(module: "RealmMacroMacros", type: "RealmSchemaDiscovery")

@attached(conformance)
@attached(member, names: named(_realmProperties), named(_realmUnmanagedStorage))
@attached(memberAttribute)
public macro RealmModel() -> () = #externalMacro(module: "RealmMacroMacros", type: "RealmObjectMacro2")

@attached(accessor)
@attached(peer, names: arbitrary)
public macro _PersistedProperty(index: Int) -> () = #externalMacro(module: "RealmMacroMacros", type: "PersistedProperty2")

@attached(peer, names: arbitrary)
public macro PersistedProperty(index: Int) -> () = #externalMacro(module: "RealmMacroMacros", type: "PersistedProperty2")

@attached(accessor)
public macro OriginProperty(name: String) -> () = #externalMacro(module: "RealmMacroMacros", type: "Marker")

@attached(accessor)
public macro PrimaryKey() -> () = #externalMacro(module: "RealmMacroMacros", type: "Marker")
@attached(accessor)
public macro Indexed() -> () = #externalMacro(module: "RealmMacroMacros", type: "Marker")
@attached(accessor)
public macro Ignored() -> () = #externalMacro(module: "RealmMacroMacros", type: "Marker")

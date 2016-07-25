//
//  RealmBoundObject.swift
//  Realm
//
//  Created by Realm on 7/14/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Realm

#if swift(>=3.0)
    
/// An object that can be handed over between threads
@objc public protocol Handoverable {
    // Runtime-enforced requirement that type also conforms to `_Handoverable`
}

// Conformance to `_Handoverable` by `Handoverable` types cannot be verified by the typechecker or tests
internal protocol _Handoverable {
    var realm: Realm? { get }
    var bridgedHandoverable: RLMThreadConfined { get }
    var bridgedMetadata: Any? { get }
    static func bridge(handoverable: RLMThreadConfined, metadata: Any?) -> Self
}

extension Handoverable {
    internal var _handoverable: _Handoverable {
        if let object = self as? _Handoverable {
            return object
        } else {
            fatalError("Illegal custom conformances to `RLMThreadConfined` by \(self.dynamicType)")
        }
    }

    static internal var _handoverable: _Handoverable.Type {
        if let type = self as? _Handoverable.Type {
            return type
        } else {
            fatalError("Illegal custom conformances to `RLMThreadConfined` by \(self)")
        }
    }

    /// The `Realm` the object is associated with
    // Note: cannot be a protocol requirement since `Realm` is not an Objective-C type.
    public var realm: Realm? {
        return _handoverable.realm
    }
}

public class HandoverPackage<T: Handoverable> {
    private var metadata: [Any?]
    private var types: [Handoverable.Type]
    private let package: RLMHandoverPackage

    internal init(realm: Realm, objects: [T]) {
        self.metadata = objects.map { $0._handoverable.bridgedMetadata }
        self.types = objects.map { $0.dynamicType }
        self.package = realm.rlmRealm.packageObjects(forHandover: objects.map { $0._handoverable.bridgedHandoverable })
    }

    public func importOnCurrentThead() throws -> (Realm, [T]) {
        defer {
            metadata = []
            types = []
        }

        let handoverImport = try package.importOnCurrentThread()
        // Swift Arrays must be properly typed on index access, and `Object` does not conform to `RLMThreadConfined`
        let handoverables = unsafeBitCast(handoverImport.objects, to: [AnyObject].self)

        let objects: [T] = zip(types, zip(handoverables, metadata)).map { type, arguments in
            let handoverable = unsafeBitCast(arguments.0, to: RLMThreadConfined.self)
            let metadata = arguments.1
            return type._handoverable.bridge(handoverable: handoverable, metadata: metadata) as! T
        }
        return (Realm(handoverImport.realm), objects)
    }
}

#else

/// An object that can be handed over between threads
@objc public protocol Handoverable {
    // Runtime-enforced requirement that type also conforms to `_Handoverable`
}

// Conformance to `_Handoverable` by `Handoverable` types cannot be verified by the typechecker or tests
internal protocol _Handoverable {
    var realm: Realm? { get }
    var bridgedHandoverable: RLMThreadConfined { get }
    var bridgedMetadata: Any? { get }
    static func bridge(handoverable: RLMThreadConfined, metadata: Any?) -> Self
}

extension Handoverable {
    internal var _handoverable: _Handoverable {
        if let object = self as? _Handoverable {
            return object
        } else {
            fatalError("Illegal custom conformances to `RLMThreadConfined` by \(self.dynamicType)")
        }
    }

    static internal var _handoverable: _Handoverable.Type {
        if let type = self as? _Handoverable.Type {
            return type
        } else {
            fatalError("Illegal custom conformances to `RLMThreadConfined` by \(self)")
        }
    }

    /// The `Realm` the object is associated with
    // Note: cannot be a protocol requirement since `Realm` is not an Objective-C type.
    public var realm: Realm? {
        return _handoverable.realm
    }
}

public class HandoverPackage<T: Handoverable> {
    private var metadata: [Any?]
    private var types: [Handoverable.Type]
    private let package: RLMHandoverPackage

    internal init(realm: Realm, objects: [T]) {
        self.metadata = objects.map { $0._handoverable.bridgedMetadata }
        self.types = objects.map { $0.dynamicType }
        self.package = realm.rlmRealm.packageObjectsForHandover(objects.map { $0._handoverable.bridgedHandoverable })
    }

    public func importOnCurrentThead() throws -> (Realm, [T]) {
        defer {
            metadata = []
            types = []
        }

        let handoverImport = try package.importOnCurrentThread()
        // Swift Arrays must be properly typed on index access, and `Object` does not conform to `RLMThreadConfined`
        let handoverables = unsafeBitCast(handoverImport.objects, [AnyObject].self)

        let objects: [T] = zip(types, zip(handoverables, metadata)).map { type, arguments in
            let handoverable = unsafeBitCast(arguments.0, RLMThreadConfined.self)
            let metadata = arguments.1
            return type._handoverable.bridge(handoverable, metadata: metadata) as! T
        }
        return (Realm(handoverImport.realm), objects)
    }
}

#endif

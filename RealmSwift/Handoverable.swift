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
    var bridgedHandoverable: RLMHandoverable { get }
    var bridgedMetadata: Any? { get }
    static func bridge(handoverable: RLMHandoverable, metadata: Any?) -> Self
}

extension Handoverable {
    internal var _handoverable: _Handoverable {
        if let object = self as? _Handoverable {
            return object
        } else {
            fatalError("Illegal custom conformances to `RLMHandoverable` by \(self.dynamicType)")
        }
    }

    static internal var _handoverable: _Handoverable.Type {
        if let type = self as? _Handoverable.Type {
            return type
        } else {
            fatalError("Illegal custom conformances to `RLMHandoverable` by \(self)")
        }
    }

    /// The `Realm` the object is associated with
    // Note: cannot be a protocol requirement since `Realm` is not an Objective-C type.
    public var realm: Realm? {
        return _handoverable.realm
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
    var bridgedHandoverable: RLMHandoverable { get }
    var bridgedMetadata: Any? { get }
    static func bridge(handoverable: RLMHandoverable, metadata: Any?) -> Self
}

extension Handoverable {
    internal var _handoverable: _Handoverable {
        if let object = self as? _Handoverable {
            return object
        } else {
            fatalError("Illegal custom conformances to `RLMHandoverable` by \(self.dynamicType)")
        }
    }

    static internal var _handoverable: _Handoverable.Type {
        if let type = self as? _Handoverable.Type {
            return type
        } else {
            fatalError("Illegal custom conformances to `RLMHandoverable` by \(self)")
        }
    }

    /// The `Realm` the object is associated with
    // Note: cannot be a protocol requirement since `Realm` is not an Objective-C type.
    public var realm: Realm? {
        return _handoverable.realm
    }
}

#endif

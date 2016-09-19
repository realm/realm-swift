////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Realm

#if swift(>=3.0)
    extension RLMRealm {
        @nonobjc public class func schemaVersion(at url: URL, usingEncryptionKey key: Data? = nil) throws -> UInt64 {
            var error: NSError?
            let version = __schemaVersion(at: url, encryptionKey: key, error: &error)
            guard version != RLMNotVersioned else {
                throw error!
            }
            return version
        }

        @nonobjc public func resolve<Confined: RLMThreadConfined>(reference: RLMThreadSafeReference<Confined>) -> Confined? {
            return __resolve(reference as! RLMThreadSafeReference<RLMThreadConfined>) as! Confined?
        }
    }

    extension RLMObject {
        // Swift query convenience functions
        public class func objects(where predicateFormat: String, _ args: CVarArg...) -> RLMResults<RLMObject> {
            return objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }

        public class func objects(in realm: RLMRealm,
                                  where predicateFormat: String,
                                  _ args: CVarArg...) -> RLMResults<RLMObject> {
            return objects(in: realm, with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }
    }

    public final class RLMIterator: IteratorProtocol {
        private let iteratorBase: NSFastEnumerationIterator

        internal init(collection: RLMCollection) {
            iteratorBase = NSFastEnumerationIterator(collection)
        }

        public func next() -> RLMObject? {
            return iteratorBase.next() as! RLMObject?
        }
    }

    // Sequence conformance for RLMArray and RLMResults is provided by RLMCollection's
    // `makeIterator()` implementation.
    extension RLMArray: Sequence {}
    extension RLMResults: Sequence {}

    extension RLMCollection {
        // Support Sequence-style enumeration
        public func makeIterator() -> RLMIterator {
            return RLMIterator(collection: self)
        }
    }

    extension RLMCollection {
        // Swift query convenience functions
        public func indexOfObject(where predicateFormat: String, _ args: CVarArg...) -> UInt {
            return indexOfObject(with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }

        public func objects(where predicateFormat: String, _ args: CVarArg...) -> RLMResults<RLMObject> {
            return objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }
    }

#else
    extension RLMRealm {
        @nonobjc public class func schemaVersionAtURL(url: NSURL, encryptionKey key: NSData? = nil,
                                                      error: NSErrorPointer) -> UInt64 {
            return __schemaVersionAtURL(url, encryptionKey: key, error: error)
        }
    }

    extension RLMObject {
        // Swift query convenience functions
        public class func objectsWhere(predicateFormat: String, _ args: CVarArgType...) -> RLMResults {
            return objectsWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }

        public class func objectsInRealm(realm: RLMRealm,
                                         _ predicateFormat: String,
                                         _ args: CVarArgType...) -> RLMResults {
            return objectsInRealm(realm,
                                  withPredicate: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }
    }

    public final class RLMGenerator: GeneratorType {
        private let generatorBase: NSFastGenerator

        internal init(collection: RLMCollection) {
            generatorBase = NSFastGenerator(collection)
        }

        public func next() -> RLMObject? {
            return generatorBase.next() as! RLMObject?
        }
    }

    extension RLMArray: SequenceType {
        // Support Sequence-style enumeration
        public func generate() -> RLMGenerator {
            return RLMGenerator(collection: self)
        }

        // Swift query convenience functions
        public func indexOfObjectWhere(predicateFormat: String, _ args: CVarArgType...) -> UInt {
            return indexOfObjectWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }

        public func objectsWhere(predicateFormat: String, _ args: CVarArgType...) -> RLMResults {
            return objectsWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }
    }

    extension RLMResults: SequenceType {
        // Support Sequence-style enumeration
        public func generate() -> RLMGenerator {
            return RLMGenerator(collection: self)
        }

        // Swift query convenience functions
        public func indexOfObjectWhere(predicateFormat: String, _ args: CVarArgType...) -> UInt {
            return indexOfObjectWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }

        public func objectsWhere(predicateFormat: String, _ args: CVarArgType...) -> RLMResults {
            return objectsWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args)))
        }
    }
#endif

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
        // TODO: Figure out why this causes the Swift 3 compiler to segfault.
//        public class func schemaVersion(at url: URL, usingEncryptionKey key: Data? = nil) throws -> UInt64 {
//            var error: NSError?
//            let version = __schemaVersion(at: url, encryptionKey: key, error: &error)
//            guard version != RLMNotVersioned else {
//                throw error!
//            }
//            return version
//        }
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

    // SR-2348: A bug in Objective-C generics currently make this impossible w/o an error or compiler crash.
//    extension RLMArray: Sequence  {
//        // Support Sequence-style enumeration
//        public func makeIterator() -> RLMIterator {
//            return RLMIterator(collection: self)
//        }
//    }
//
//    extension RLMResults: Sequence {
//        // Support Sequence-style enumeration
//        public func makeIterator() -> RLMIterator {
//            return RLMIterator(collection: self)
//        }
//    }

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

    extension NSNumber {
        static func float(_ value: Float?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullFloat() }
            return NSNumber(value: value)
        }

        static func double(_ value: Double?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullDouble() }
            return NSNumber(value: value)
        }

        static func bool(_ value: Bool?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullBool() }
            return NSNumber(value: value)
        }

        static func int(_ value: Int?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt() }
            return NSNumber(value: value)
        }

        static func int8(_ value: Int8?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt8() }
            return NSNumber(value: value)
        }

        static func int16(_ value: Int16?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt16() }
            return NSNumber(value: value)
        }

        static func int32(_ value: Int32?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt32() }
            return NSNumber(value: value)
        }

        static func int64(_ value: Int64?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt64() }
            return NSNumber(value: value)
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

    extension NSNumber {
        static func float(value: Float?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullFloat() }
            return NSNumber(float: value)
        }

        static func double(value: Double?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullDouble() }
            return NSNumber(double: value)
        }

        static func bool(value: Bool?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullBool() }
            return NSNumber(bool: value)
        }

        static func int(value: Int?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt() }
            return NSNumber(integer: value)
        }

        static func int8(value: Int8?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt8() }
            return NSNumber(char: value)
        }

        static func int16(value: Int16?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt16() }
            return NSNumber(short: value)
        }

        static func int32(value: Int32?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt32() }
            return NSNumber(int: value)
        }

        static func int64(value: Int64?) -> NSNumber {
            guard let value = value else { return RLMNumericNull.nullInt64() }
            return NSNumber(longLong: value)
        }
    }
#endif

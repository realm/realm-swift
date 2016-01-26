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

extension RLMObject {
    // Swift query convenience functions
    public class func objectsWhere(predicateFormat: String, _ args: CVarArgType...) -> RLMResults {
        return objectsWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args)))
    }

    public class func objectsInRealm(realm: RLMRealm, _ predicateFormat: String, _ args: CVarArgType...) -> RLMResults {
        return objectsInRealm(realm, withPredicate:NSPredicate(format: predicateFormat, arguments: getVaList(args)))
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

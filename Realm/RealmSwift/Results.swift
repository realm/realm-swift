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

// Types which can be used for min()/max()
public protocol MinMaxType {}
extension Double: MinMaxType {}
extension Float: MinMaxType {}
extension Int16: MinMaxType {}
extension Int32: MinMaxType {}
extension Int64: MinMaxType {}
extension Int: MinMaxType {}
extension NSDate: MinMaxType {}

// Types which can be used for average/sum
public protocol AddableType {}
extension Double: AddableType {}
extension Float: AddableType {}
extension Int16: AddableType {}
extension Int32: AddableType {}
extension Int64: AddableType {}
extension Int: AddableType {}

public final class Results<T: Object>: Printable, SequenceType {
    let rlmResults: RLMResults

    // MARK: Properties

    public var realm: Realm { return Realm(rlmRealm: rlmResults.realm) }
    public var description: String { return rlmResults.description }
    public var count: Int { return Int(rlmResults.count) }

    // MARK: Initializers

    init(_ rlmResults: RLMResults) {
        self.rlmResults = rlmResults
    }

    // MARK: Index Retrieval

    public func indexOf(object: T) -> Int? {
        return notFoundToNil(rlmResults.indexOfObject(unsafeBitCast(object, RLMObject.self)))
    }

    public func indexOf(predicate: NSPredicate) -> Int? {
        return notFoundToNil(rlmResults.indexOfObjectWithPredicate(predicate))
    }

    public func indexOf(predicateFormat: String, _ args: CVarArgType...) -> Int? {
        return notFoundToNil(rlmResults.indexOfObjectWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args))))
    }

    // MARK: Object Retrieval

    public subscript(index: Int) -> T {
        get {
            return rlmResults[UInt(index)] as T
        }
    }

    public var first: T? { return rlmResults.firstObject() as T? }

    public var last: T? { return rlmResults.lastObject() as T? }

    // MARK: Subarray Retrieval

    public func filter(predicateFormat: String, _ args: CVarArgType...) -> Results<T> {
        return Results<T>(rlmResults.objectsWithPredicate(NSPredicate(format: predicateFormat, arguments: getVaList(args))))
    }

    public func filter(predicate: NSPredicate) -> Results<T> {
        return Results<T>(rlmResults.objectsWithPredicate(predicate))
    }

    // MARK: Sorting

    public func sorted(property: String, ascending: Bool = true) -> Results<T> {
        return Results<T>(rlmResults.sortedResultsUsingProperty(property, ascending: ascending))
    }

    // MARK: Aggregate Operations

    public func min<U: MinMaxType>(property: String) -> U {
        return rlmResults.minOfProperty(property) as U
    }

    public func max<U: MinMaxType>(property: String) -> U {
        return rlmResults.maxOfProperty(property) as U
    }

    public func sum<U: AddableType>(property: String) -> U {
        return rlmResults.sumOfProperty(property) as AnyObject as U
    }

    public func average<U: AddableType>(property: String) -> U {
        return rlmResults.averageOfProperty(property) as AnyObject as U
    }

    // MARK: Sequence Support

    public func generate() -> GeneratorOf<T> {
        var i: UInt = 0
        return GeneratorOf<T>() {
            if (i >= self.rlmResults.count) {
                return .None
            } else {
                return self.rlmResults[i++] as? T
            }
        }
    }

    // MARK: Private stuff

    private func notFoundToNil(index: UInt) -> Int? {
        if index == UInt(NSNotFound) {
            return nil
        }
        return Int(index)
    }
}

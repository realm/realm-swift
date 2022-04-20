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

import Foundation

public class Ownable<T: ThreadConfined> {

    private(set) var realm: Realm?
    private(set) var threadConfined: ThreadSafeReference<T>?
    private(set) var unmanaged: T?

    public convenience init(item: T) {
        if let realm = item.realm {
            let wrappedObj = ThreadSafeReference(to: item)
            self.init(threadConfined: wrappedObj, unmanaged: nil, realm: realm)
        } else {
            self.init(threadConfined: nil, unmanaged: item, realm: nil)
        }
    }

    public init(threadConfined: ThreadSafeReference<T>?, unmanaged: T?, realm: Realm?) {
        self.threadConfined = threadConfined
        self.unmanaged = unmanaged
        self.realm = realm
    }

    public func take() throws -> T {
        if let threadConfined = threadConfined, let realm = realm {
            if let result = realm.resolve(threadConfined) {
                return result
            } else {
                throw RealmError("Object was deleted in another thread!!")
            }
        } else if let unmanaged = unmanaged {
            return unmanaged
        } else {
            throw RealmError("Require either a realm bound or managed object")
        }
    }
}

////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

private func isSameCollection(_ lhs: RLMCollection, _ rhs: Any) -> Bool {
    // Managed isEqual checks if they're backed by the same core field, so it does exactly what we need
    if lhs.realm != nil {
        return lhs.isEqual(rhs)
    }
    // For unmanaged we want to check if the backing collection is the same instance
    if let rhs = rhs as? RLMSwiftCollectionBase {
        return lhs === rhs._rlmCollection
    }
    return lhs === rhs as AnyObject
}

internal protocol MutableRealmCollection {
    func assign(_ value: Any)

    // Unmanaged collection properties need a reference to their parent object for
    // KVO to work because the mutation is done via the collection object but the
    // observation is on the parent.
    func setParent(_ object: RLMObjectBase, _ property: RLMProperty)
}

extension List: MutableRealmCollection {
    func assign(_ value: Any) {
        guard !isSameCollection(_rlmCollection, value) else { return }
        RLMAssignToCollection(_rlmCollection, value)
    }
    func setParent(_ object: RLMObjectBase, _ property: RLMProperty) {
        rlmArray.setParent(object, property: property)
    }
}

extension MutableSet: MutableRealmCollection {
    func assign(_ value: Any) {
        guard !isSameCollection(_rlmCollection, value) else { return }
        RLMAssignToCollection(_rlmCollection, value)
    }
    func setParent(_ object: RLMObjectBase, _ property: RLMProperty) {
        rlmSet.setParent(object, property: property)
    }
}

extension Map: MutableRealmCollection {
    func assign(_ value: Any) {
        guard !isSameCollection(_rlmCollection, value) else { return }
        rlmDictionary.setDictionary(value)
    }
    func setParent(_ object: RLMObjectBase, _ property: RLMProperty) {
        rlmDictionary.setParent(object, property: property)
    }
}

////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#ifndef REALM_DELEGATE_HPP
#define REALM_DELEGATE_HPP

#include "index_set.hpp"

#include <tuple>
#include <vector>

namespace realm {
class RealmDelegate {
public:
    virtual ~RealmDelegate() = default;

    // Change information for a single field of a row
    struct ColumnInfo {
        bool changed = false;
        enum class Kind {
            None,
            Set,
            Insert,
            Remove,
            SetAll
        } kind = Kind::None;
        IndexSet indices;
    };

    // Information about an observed row in a table
    struct ObserverState {
        // Initial table and row which is observed
        // May be updated by row insertions and removals
        size_t table_ndx;
        size_t row_ndx;

        // Opaque userdata for the delegate's use
        void* info;

        // Populated with information about which columns were changed
        // May be shorter than the actual number of columns if the later columns
        // are not modified
        std::vector<ColumnInfo> changes;

        // Simple lexographic ordering
        friend bool operator<(ObserverState const& lft, ObserverState const& rgt) {
            return std::tie(lft.table_ndx, lft.row_ndx) < std::tie(rgt.table_ndx, rgt.row_ndx);
        }
    };

    // There are now new versions available for the Realm, but it has not
    // had its read version advanced
    virtual void changes_available() = 0;

    // Called before changing the read transaction. Should return a list of
    // ObserverStates for each row for which detailed change information is
    // desired.
    virtual std::vector<ObserverState> get_observed_rows() = 0;

    // The Realm's read version will change
    // Only called if get_observed_row() returned a non-empty array.
    // observers is the vector returned from get_observed_rows()
    // invalidated is the `info` pointers for each observed object which was deleted
    virtual void will_change(std::vector<ObserverState> const& observers,
                             std::vector<void*> const& invalidated) = 0;

    // The Realm's read version has changed
    // observers is the vector returned from get_observed_rows()
    // invalidated is the `info` pointers for each observed object which was deleted
    // Is called with empty change information following a local commit or if
    // the Realm isn't in a read transaction yet
    virtual void did_change(std::vector<ObserverState> const& observers,
                            std::vector<void*> const& invalidated) = 0;
};
} // namespace realm

#endif /* REALM_DELEGATE_HPP */

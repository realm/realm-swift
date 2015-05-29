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

#ifndef __realm__object_store__
#define __realm__object_store__

#include <realm/group.hpp>

namespace realm {
    class ObjectStore {
    public:
        // Schema version used for uninitialized Realms
        static const uint64_t NotVersioned;

        // check if the realm already has all metadata tables
        static bool has_metadata_tables(realm::Group *group);

        // create any metadata tables that don't already exist
        // must be in write transaction to set
        // returns true if it actually did anything
        static bool create_metadata_tables(realm::Group *group);

        // get the last set schema version
        static uint64_t get_schema_version(realm::Group *group);

        // set a new schema version
        static void set_schema_version(realm::Group *group, uint64_t version);

        // get primary key property name for object type
        static StringData get_primary_key_for_object(realm::Group *group, StringData object_type);
        
        // sets primary key property for object type
        // must be in write transaction to set
        static void set_primary_key_for_object(realm::Group *group, StringData object_type, StringData primary_key);
    };
}

#endif /* defined(__realm__object_store__) */


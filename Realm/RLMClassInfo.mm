////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMClassInfo.hpp"

#import "RLMRealm_Private.hpp"
#import "RLMObjectSchema_Private.h"
#import "RLMSchema.h"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMUtil.hpp"

#import "object_schema.hpp"
#import "object_store.hpp"
#import "schema.hpp"
#import "shared_realm.hpp"

#import <realm/table.hpp>

using namespace realm;

RLMClassInfo::RLMClassInfo(RLMRealm *realm, RLMObjectSchema *rlmObjectSchema,
                           const realm::ObjectSchema *objectSchema)
: realm(realm), rlmObjectSchema(rlmObjectSchema), objectSchema(objectSchema) { }

realm::TableRef RLMClassInfo::table() const {
    if (auto key = objectSchema->table_key) {
        return realm.group.get_table(objectSchema->table_key);
    }
    return nullptr;
}

RLMProperty *RLMClassInfo::propertyForTableColumn(ColKey col) const noexcept {
    auto const& props = objectSchema->persisted_properties;
    for (size_t i = 0; i < props.size(); ++i) {
        if (props[i].column_key == col) {
            return rlmObjectSchema.properties[i];
        }
    }
    return nil;
}

RLMProperty *RLMClassInfo::propertyForPrimaryKey() const noexcept {
    return rlmObjectSchema.primaryKeyProperty;
}

realm::ColKey RLMClassInfo::tableColumn(NSString *propertyName) const {
    return tableColumn(RLMValidatedProperty(rlmObjectSchema, propertyName));
}

realm::ColKey RLMClassInfo::tableColumn(RLMProperty *property) const {
    return objectSchema->persisted_properties[property.index].column_key;
}

RLMClassInfo &RLMClassInfo::linkTargetType(size_t propertyIndex) {
    return realm->_info[rlmObjectSchema.properties[propertyIndex].objectClassName];
}

RLMClassInfo &RLMClassInfo::linkTargetType(realm::Property const& property) {
    REALM_ASSERT(property.type == PropertyType::Object);
    return linkTargetType(&property - &objectSchema->persisted_properties[0]);
}

RLMClassInfo &RLMClassInfo::freeze(__unsafe_unretained RLMRealm *const frozenRealm) {
    REALM_ASSERT(frozenRealm.frozen);
    // FIXME
    return frozenRealm->_info[rlmObjectSchema.className];
}

RLMSchemaInfo::impl::iterator RLMSchemaInfo::begin() noexcept { return m_objects.begin(); }
RLMSchemaInfo::impl::iterator RLMSchemaInfo::end() noexcept { return m_objects.end(); }
RLMSchemaInfo::impl::const_iterator RLMSchemaInfo::begin() const noexcept { return m_objects.begin(); }
RLMSchemaInfo::impl::const_iterator RLMSchemaInfo::end() const noexcept { return m_objects.end(); }

RLMClassInfo& RLMSchemaInfo::operator[](NSString *name) {
    auto it = m_objects.find(name);
    if (it == m_objects.end()) {
        @throw RLMException(@"Object type '%@' is not managed by the Realm. "
                            @"If using a custom `objectClasses` / `objectTypes` array in your configuration, "
                            @"add `%@` to the list of `objectClasses` / `objectTypes`.",
                            name, name);
    }
    return *&it->second;
}

RLMSchemaInfo::RLMSchemaInfo(RLMRealm *realm) {
    RLMSchema *rlmSchema = realm.schema;
    realm::Schema const& schema = realm->_realm->schema();
    // rlmSchema can be larger due to multiple classes backed by one table
    REALM_ASSERT(rlmSchema.objectSchema.count >= schema.size());

    m_objects.reserve(schema.size());
    for (RLMObjectSchema *rlmObjectSchema in rlmSchema.objectSchema) {
        m_objects.emplace(std::piecewise_construct,
                          std::forward_as_tuple(rlmObjectSchema.className),
                          std::forward_as_tuple(realm, rlmObjectSchema,
                                                &*schema.find(rlmObjectSchema.objectName.UTF8String)));
    }
}

RLMSchemaInfo RLMSchemaInfo::clone(realm::Schema const& source_schema,
                                   __unsafe_unretained RLMRealm *const target_realm) {
    RLMSchemaInfo info;
    info.m_objects.reserve(m_objects.size());

    auto& schema = target_realm->_realm->schema();
    for (auto& pair : m_objects) {
        size_t idx = pair.second.objectSchema - &*source_schema.begin();
        info.m_objects.emplace(std::piecewise_construct,
                               std::forward_as_tuple(pair.first),
                               std::forward_as_tuple(target_realm, pair.second.rlmObjectSchema,
                                                     &*schema.begin() + idx));
    }
    return info;
}

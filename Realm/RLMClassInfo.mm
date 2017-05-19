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

realm::Table *RLMClassInfo::table() const {
    if (!m_table) {
        m_table = ObjectStore::table_for_object_type(realm.group, objectSchema->name).get();
    }
    return m_table;
}

RLMProperty *RLMClassInfo::propertyForTableColumn(NSUInteger col) const noexcept {
    auto const& props = objectSchema->persisted_properties;
    for (size_t i = 0; i < props.size(); ++i) {
        if (props[i].table_column == col) {
            return rlmObjectSchema.properties[i];
        }
    }
    return nil;
}

RLMProperty *RLMClassInfo::propertyForPrimaryKey() const noexcept {
    return rlmObjectSchema.primaryKeyProperty;
}

NSUInteger RLMClassInfo::tableColumn(NSString *propertyName) const {
    return tableColumn(RLMValidatedProperty(rlmObjectSchema, propertyName));
}

NSUInteger RLMClassInfo::tableColumn(RLMProperty *property) const {
    return objectSchema->persisted_properties[property.index].table_column;
}

RLMClassInfo &RLMClassInfo::linkTargetType(size_t propertyIndex) {
    if (propertyIndex < m_linkTargets.size() && m_linkTargets[propertyIndex]) {
        return *m_linkTargets[propertyIndex];
    }
    if (m_linkTargets.size() <= propertyIndex) {
        m_linkTargets.resize(propertyIndex + 1);
    }
    m_linkTargets[propertyIndex] = &realm->_info[rlmObjectSchema.properties[propertyIndex].objectClassName];
    return *m_linkTargets[propertyIndex];
}

RLMClassInfo &RLMClassInfo::linkTargetType(realm::Property const& property) {
    REALM_ASSERT(property.type == PropertyType::Object || property.type == PropertyType::Array);
    return linkTargetType(&property - &objectSchema->persisted_properties[0]);
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
    REALM_ASSERT(rlmSchema.objectSchema.count == schema.size());

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

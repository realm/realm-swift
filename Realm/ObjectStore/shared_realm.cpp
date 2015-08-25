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

#include "shared_realm.hpp"

#include <realm/commit_log.hpp>
#include <realm/group_shared.hpp>
#include <realm/lang_bind_helper.hpp>

#include <mutex>

using namespace realm;

RealmCache Realm::s_global_cache;

Realm::Config::Config(const Config& c)
: path(c.path)
, read_only(c.read_only)
, in_memory(c.in_memory)
, cache(c.cache)
, encryption_key(c.encryption_key)
, schema_version(c.schema_version)
, migration_function(c.migration_function)
{
    if (c.schema) {
        schema = std::make_unique<Schema>(*c.schema);
    }
}

Realm::Config& Realm::Config::operator=(realm::Realm::Config const& c)
{
    if (&c != this) {
        *this = Config(c);
    }
    return *this;
}

Realm::Realm(Config config) : m_config(std::move(config))
{
    try {
        if (m_config.read_only) {
            m_read_only_group = std::make_unique<Group>(m_config.path, m_config.encryption_key.data(), Group::mode_ReadOnly);
            m_group = m_read_only_group.get();
        }
        else {
            m_history = realm::make_client_history(m_config.path, m_config.encryption_key.data());
            SharedGroup::DurabilityLevel durability = m_config.in_memory ? SharedGroup::durability_MemOnly :
                                                                           SharedGroup::durability_Full;
            m_shared_group = std::make_unique<SharedGroup>(*m_history, durability, m_config.encryption_key.data());
        }
    }
    catch (util::File::PermissionDenied const& ex) {
        throw RealmFileException(RealmFileException::Kind::PermissionDenied, "Unable to open a realm at path '" + m_config.path +
                             "'. Please use a path where your app has " + (m_config.read_only ? "read" : "read-write") + " permissions.");
    }
    catch (util::File::Exists const& ex) {
        throw RealmFileException(RealmFileException::Kind::Exists, "Unable to open a realm at path '" + m_config.path + "'");
    }
    catch (util::File::AccessError const& ex) {
        throw RealmFileException(RealmFileException::Kind::AccessError, "Unable to open a realm at path '" + m_config.path + "'");
    }
    catch (IncompatibleLockFile const&) {
        throw RealmFileException(RealmFileException::Kind::IncompatibleLockFile, "Realm file is currently open in another process "
        "which cannot share access with this process. All processes sharing a single file must be the same architecture.");
    }
}

Group *Realm::read_group()
{
    if (!m_group) {
        m_group = &const_cast<Group&>(m_shared_group->begin_read());
    }
    return m_group;
}

SharedRealm Realm::get_shared_realm(Config config)
{
    SharedRealm realm = s_global_cache.get_realm(config.path);
    if (realm) {
        if (realm->config().read_only != config.read_only) {
            throw MismatchedConfigException("Realm at path already opened with different read permissions.");
        }
        if (realm->config().in_memory != config.in_memory) {
            throw MismatchedConfigException("Realm at path already opened with different inMemory settings.");
        }
        if (realm->config().encryption_key != config.encryption_key) {
            throw MismatchedConfigException("Realm at path already opened with a different encryption key.");
        }
        if (realm->config().schema_version != config.schema_version && config.schema_version != ObjectStore::NotVersioned) {
            throw MismatchedConfigException("Realm at path already opened with different schema version.");
        }
        // FIXME - enable schma comparison
        /*if (realm->config().schema != config.schema) {
            throw MismatchedConfigException("Realm at path already opened with different schema");
        }*/

        realm->m_config.migration_function = config.migration_function;
        
        return realm;
    }

    realm = SharedRealm(new Realm(std::move(config)));

    // we want to ensure we are only initializing a single realm at a time
    static std::mutex s_init_mutex;
    std::lock_guard<std::mutex> lock(s_init_mutex);

    uint64_t old_version = ObjectStore::get_schema_version(realm->read_group());
    if (auto existing = s_global_cache.get_any_realm(realm->config().path)) {
        // if there is an existing realm at the current path steal its schema/column mapping
        // FIXME - need to validate that schemas match
        realm->m_config.schema = std::make_unique<Schema>(*existing->m_config.schema);
    }
    else if (!realm->m_config.schema) {
        // get schema from group and skip validation
        realm->m_config.schema_version = old_version;
        realm->m_config.schema = std::make_unique<Schema>(ObjectStore::schema_from_group(realm->read_group()));
    }
    else if (realm->m_config.read_only) {
        if (old_version == ObjectStore::NotVersioned) {
            throw UnitializedRealmException("Can't open an un-initizliazed Realm without a Schema");
        }
        ObjectStore::verify_schema(realm->read_group(), *realm->m_config.schema, true);
    }
    else {
        // its a non-cached realm so update/migrate if needed
        realm->update_schema(*realm->m_config.schema, realm->m_config.schema_version);
    }

    if (config.cache) {
        s_global_cache.cache_realm(realm, realm->m_thread_id);
    }
    return realm;
}

bool Realm::update_schema(Schema &schema, uint64_t version)
{
    bool changed = false;
    Config old_config(m_config);

    // set new version/schema
    if (m_config.schema.get() != &schema) {
        m_config.schema = std::make_unique<Schema>(schema);
    }
    m_config.schema_version = version;

    try {
        if (!m_config.read_only && ObjectStore::realm_requires_update(read_group(), version, schema)) {
            // keep old copy to pass to migration function
            old_config.read_only = true;
            old_config.schema_version = ObjectStore::get_schema_version(read_group());
            old_config.schema = std::make_unique<Schema>(ObjectStore::schema_from_group(read_group()));
            SharedRealm old_realm(new Realm(old_config));
            auto updated_realm = shared_from_this();

            // update and migrate
            begin_transaction();
            changed = ObjectStore::update_realm_with_schema(read_group(), version, *m_config.schema,
                                                            [=](__unused Group *group, __unused Schema &target_schema) {
                                                                m_config.migration_function(old_realm, updated_realm);
                                                            });
            commit_transaction();
        }
        else {
            ObjectStore::verify_schema(read_group(), *m_config.schema, m_config.read_only);
        }
    }
    catch (...) {
        if (is_in_transaction()) {
            cancel_transaction();
        }
        m_config.schema_version = old_config.schema_version;
        m_config.schema = std::move(old_config.schema);
        throw;
    }
    return changed;
}

static void check_read_write(Realm *realm)
{
    if (realm->config().read_only) {
        throw InvalidTransactionException("Can't perform transactions on read-only Realms.");
    }
}

void Realm::verify_thread()
{
    if (m_thread_id != std::this_thread::get_id()) {
        throw IncorrectThreadException("Realm accessed from incorrect thread.");
    }
}

void Realm::begin_transaction()
{
    check_read_write(this);
    verify_thread();

    if (m_in_transaction) {
        throw InvalidTransactionException("The Realm is already in a write transaction");
    }

    // if the upgrade to write will move the transaction forward, announce the change after promoting
    bool announce = m_shared_group->has_changed();

    // make sure we have a read transaction
    read_group();

    LangBindHelper::promote_to_write(*m_shared_group, *m_history);
    m_in_transaction = true;

    if (announce) {
        send_local_notifications(DidChangeNotification);
    }
}

void Realm::commit_transaction()
{
    check_read_write(this);
    verify_thread();

    if (!m_in_transaction) {
        throw InvalidTransactionException("Can't commit a non-existing write transaction");
    }

    LangBindHelper::commit_and_continue_as_read(*m_shared_group);
    m_in_transaction = false;

    send_external_notifications();
    send_local_notifications(DidChangeNotification);
}

void Realm::cancel_transaction()
{
    check_read_write(this);
    verify_thread();

    if (!m_in_transaction) {
        throw InvalidTransactionException("Can't cancel a non-existing write transaction");
    }

    LangBindHelper::rollback_and_continue_as_read(*m_shared_group, *m_history);
    m_in_transaction = false;
}


void Realm::invalidate()
{
    verify_thread();
    check_read_write(this);

    if (m_in_transaction) {
        cancel_transaction();
    }
    if (!m_group) {
        return;
    }

    m_shared_group->end_read();
    m_group = nullptr;
}

bool Realm::compact()
{
    verify_thread();

    bool success = false;
    if (m_in_transaction) {
        throw InvalidTransactionException("Can't compact a Realm within a write transaction");
    }

    for (auto &object_schema : *m_config.schema) {
        ObjectStore::table_for_object_type(read_group(), object_schema.first)->optimize();
    }

    m_shared_group->end_read();
    success = m_shared_group->compact();
    m_shared_group->begin_read();

    return success;
}

void Realm::notify()
{
    verify_thread();

    if (m_shared_group->has_changed()) { // Throws
        if (m_auto_refresh) {
            if (m_group) {
                LangBindHelper::advance_read(*m_shared_group, *m_history);
            }
            send_local_notifications(DidChangeNotification);
        }
        else {
            send_local_notifications(RefreshRequiredNotification);
        }
    }
}


void Realm::send_local_notifications(const std::string &type)
{
    verify_thread();
    for (NotificationFunction const& notification : m_notifications) {
        (*notification)(type);
    }
}


bool Realm::refresh()
{
    verify_thread();
    check_read_write(this);

    // can't be any new changes if we're in a write transaction
    if (m_in_transaction) {
        return false;
    }

    // advance transaction if database has changed
    if (!m_shared_group->has_changed()) { // Throws
        return false;
    }

    if (m_group) {
        LangBindHelper::advance_read(*m_shared_group, *m_history);
    }
    else {
        // Create the read transaction
        read_group();
    }

    send_local_notifications(DidChangeNotification);
    return true;
}

SharedRealm RealmCache::get_realm(const std::string &path, std::thread::id thread_id)
{
    std::lock_guard<std::mutex> lock(m_mutex);

    auto path_iter = m_cache.find(path);
    if (path_iter == m_cache.end()) {
        return SharedRealm();
    }

    auto thread_iter = path_iter->second.find(thread_id);
    if (thread_iter == path_iter->second.end()) {
        return SharedRealm();
    }

    return thread_iter->second.lock();
}

SharedRealm RealmCache::get_any_realm(const std::string &path)
{
    std::lock_guard<std::mutex> lock(m_mutex);

    auto path_iter = m_cache.find(path);
    if (path_iter == m_cache.end()) {
        return SharedRealm();
    }

    auto thread_iter = path_iter->second.begin();
    while (thread_iter != path_iter->second.end()) {
        if (auto realm = thread_iter->second.lock()) {
            return realm;
        }
        path_iter->second.erase(thread_iter++);
    }

    return SharedRealm();
}

void RealmCache::remove(const std::string &path, std::thread::id thread_id)
{
    std::lock_guard<std::mutex> lock(m_mutex);

    auto path_iter = m_cache.find(path);
    if (path_iter == m_cache.end()) {
        return;
    }

    auto thread_iter = path_iter->second.find(thread_id);
    if (thread_iter != path_iter->second.end()) {
        path_iter->second.erase(thread_iter);
    }

    if (path_iter->second.size() == 0) {
        m_cache.erase(path_iter);
    }
}

void RealmCache::cache_realm(SharedRealm &realm, std::thread::id thread_id)
{
    std::lock_guard<std::mutex> lock(m_mutex);

    auto path_iter = m_cache.find(realm->config().path);
    if (path_iter == m_cache.end()) {
        m_cache.emplace(realm->config().path, std::map<std::thread::id, WeakRealm>{{thread_id, realm}});
    }
    else {
        path_iter->second.emplace(thread_id, realm);
    }
}

void RealmCache::clear()
{
    std::lock_guard<std::mutex> lock(m_mutex);

    m_cache.clear();
}


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

#include "external_commit_helper.hpp"
#include "binding_context.hpp"
#include "schema.hpp"
#include "transact_log_handler.hpp"

#include <realm/commit_log.hpp>
#include <realm/group_shared.hpp>

#include <mutex>

using namespace realm;
using namespace realm::_impl;

RealmCache Realm::s_global_cache;

Realm::Config::Config(const Config& c)
: path(c.path)
, read_only(c.read_only)
, in_memory(c.in_memory)
, cache(c.cache)
, disable_format_upgrade(c.disable_format_upgrade)
, encryption_key(c.encryption_key)
, schema_version(c.schema_version)
, migration_function(c.migration_function)
{
    if (c.schema) {
        schema = std::make_unique<Schema>(*c.schema);
    }
}

Realm::Config::Config() = default;
Realm::Config::Config(Config&&) = default;
Realm::Config::~Config() = default;

Realm::Config& Realm::Config::operator=(realm::Realm::Config const& c)
{
    if (&c != this) {
        *this = Config(c);
    }
    return *this;
}

Realm::Realm(Config config)
: m_config(std::move(config))
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
            m_shared_group = std::make_unique<SharedGroup>(*m_history, durability, m_config.encryption_key.data(), !m_config.disable_format_upgrade);
        }
    }
    catch (util::File::PermissionDenied const& ex) {
        throw RealmFileException(RealmFileException::Kind::PermissionDenied, ex.get_path(),
                                 "Unable to open a realm at path '" + ex.get_path() +
                                 "'. Please use a path where your app has " + (m_config.read_only ? "read" : "read-write") + " permissions.");
    }
    catch (util::File::Exists const& ex) {
        throw RealmFileException(RealmFileException::Kind::Exists, ex.get_path(),
                                 "File at path '" + ex.get_path() + "' already exists.");
    }
    catch (util::File::AccessError const& ex) {
        throw RealmFileException(RealmFileException::Kind::AccessError, ex.get_path(),
                                 "Unable to open a realm at path '" + ex.get_path() + "'");
    }
    catch (IncompatibleLockFile const& ex) {
        throw RealmFileException(RealmFileException::Kind::IncompatibleLockFile, m_config.path,
                                 "Realm file is currently open in another process "
                                 "which cannot share access with this process. All processes sharing a single file must be the same architecture.");
    }
    catch (FileFormatUpgradeRequired const& ex) {
        throw RealmFileException(RealmFileException::Kind::FormatUpgradeRequired, m_config.path, "The Realm file format must be allowed to be upgraded "
        "in order to proceed.");
    }
}

Realm::~Realm() {
    if (m_notifier) { // might not exist yet if an error occurred during init
        m_notifier->remove_realm(this);
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
    if (config.cache) {
        if (SharedRealm realm = s_global_cache.get_realm(config.path)) {
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
    }

    SharedRealm realm(new Realm(std::move(config)));

    auto target_schema = std::move(realm->m_config.schema);
    auto target_schema_version = realm->m_config.schema_version;
    realm->m_config.schema_version = ObjectStore::get_schema_version(realm->read_group());

    // we want to ensure we are only initializing a single realm at a time
    static std::mutex s_init_mutex;
    std::lock_guard<std::mutex> lock(s_init_mutex);
    if (auto existing = s_global_cache.get_any_realm(realm->config().path)) {
        // if there is an existing realm at the current path steal its schema/column mapping
        // FIXME - need to validate that schemas match
        realm->m_config.schema = std::make_unique<Schema>(*existing->m_config.schema);

        if (!realm->m_config.read_only) {
            realm->m_notifier = existing->m_notifier;
            realm->m_notifier->add_realm(realm.get());
        }
    }
    else {
        if (!realm->m_config.read_only) {
            realm->m_notifier = std::make_shared<ExternalCommitHelper>(realm.get());
        }

        // otherwise get the schema from the group
        realm->m_config.schema = std::make_unique<Schema>(ObjectStore::schema_from_group(realm->read_group()));

        // if a target schema is supplied, verify that it matches or migrate to
        // it, as neeeded
        if (target_schema) {
            if (realm->m_config.read_only) {
                if (realm->m_config.schema_version == ObjectStore::NotVersioned) {
                    throw UnitializedRealmException("Can't open an un-initialized Realm without a Schema");
                }
                target_schema->validate();
                ObjectStore::verify_schema(*realm->m_config.schema, *target_schema, true);
                realm->m_config.schema = std::move(target_schema);
            }
            else {
                realm->update_schema(std::move(target_schema), target_schema_version);
            }
        }
    }

    if (config.cache) {
        s_global_cache.cache_realm(realm, realm->m_thread_id);
    }
    return realm;
}

void Realm::update_schema(std::unique_ptr<Schema> schema, uint64_t version)
{
    schema->validate();

    // If the schema version matches, just verify that the schema itself also matches
    bool needs_update = !m_config.read_only && (m_config.schema_version != version || ObjectStore::needs_update(*m_config.schema, *schema));
    if (!needs_update) {
        ObjectStore::verify_schema(*m_config.schema, *schema, m_config.read_only);
        m_config.schema = std::move(schema);
        m_config.schema_version = version;
        return;
    }

    read_group();
    transaction::begin(*m_shared_group, *m_history, m_binding_context.get(),
                       /* error on schema changes */ false);
    m_in_transaction = true;

    struct WriteTransactionGuard {
        Realm& realm;
        ~WriteTransactionGuard() {
            if (realm.is_in_transaction()) {
                realm.cancel_transaction();
            }
        }
    } write_transaction_guard{*this};

    // Recheck the schema version after beginning the write transaction
    // If it changed then someone else initialized the schema and we need to
    // recheck everything
    auto current_schema_version = ObjectStore::get_schema_version(read_group());
    if (current_schema_version != m_config.schema_version) {
        cancel_transaction();

        m_config.schema_version = current_schema_version;
        *m_config.schema = ObjectStore::schema_from_group(read_group());
        return update_schema(std::move(schema), version);
    }

    Config old_config(m_config);
    auto migration_function = [&](Group*,  Schema&) {
        SharedRealm old_realm(new Realm(old_config));
        // Need to open in read-write mode so that it uses a SharedGroup, but
        // users shouldn't actually be able to write via the old realm
        old_realm->m_config.read_only = true;

        m_config.migration_function(old_realm, shared_from_this());
    };

    try {
        m_config.schema = std::move(schema);
        m_config.schema_version = version;

        ObjectStore::update_realm_with_schema(read_group(), *old_config.schema,
                                              version, *m_config.schema,
                                              migration_function);
        commit_transaction();
    }
    catch (...) {
        m_config.schema = std::move(old_config.schema);
        m_config.schema_version = old_config.schema_version;
        throw;
    }
}

static void check_read_write(Realm *realm)
{
    if (realm->config().read_only) {
        throw InvalidTransactionException("Can't perform transactions on read-only Realms.");
    }
}

void Realm::verify_thread() const
{
    if (m_thread_id != std::this_thread::get_id()) {
        throw IncorrectThreadException();
    }
}

void Realm::verify_in_write() const
{
    if (!is_in_transaction()) {
        throw InvalidTransactionException("Cannot modify persisted objects outside of a write transaction.");
    }
}

void Realm::begin_transaction()
{
    check_read_write(this);
    verify_thread();

    if (m_in_transaction) {
        throw InvalidTransactionException("The Realm is already in a write transaction");
    }

    // make sure we have a read transaction
    read_group();

    transaction::begin(*m_shared_group, *m_history, m_binding_context.get());
    m_in_transaction = true;
}

void Realm::commit_transaction()
{
    check_read_write(this);
    verify_thread();

    if (!m_in_transaction) {
        throw InvalidTransactionException("Can't commit a non-existing write transaction");
    }

    m_in_transaction = false;
    transaction::commit(*m_shared_group, *m_history, m_binding_context.get());
    m_notifier->notify_others();
}

void Realm::cancel_transaction()
{
    check_read_write(this);
    verify_thread();

    if (!m_in_transaction) {
        throw InvalidTransactionException("Can't cancel a non-existing write transaction");
    }

    m_in_transaction = false;
    transaction::cancel(*m_shared_group, *m_history, m_binding_context.get());
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

    if (m_config.read_only) {
        throw InvalidTransactionException("Can't compact a read-only Realm");
    }
    if (m_in_transaction) {
        throw InvalidTransactionException("Can't compact a Realm within a write transaction");
    }

    Group* group = read_group();
    for (auto &object_schema : *m_config.schema) {
        ObjectStore::table_for_object_type(group, object_schema.name)->optimize();
    }
    m_shared_group->end_read();
    m_group = nullptr;

    return m_shared_group->compact();
}

void Realm::notify()
{
    verify_thread();

    if (m_shared_group->has_changed()) { // Throws
        if (m_binding_context) {
            m_binding_context->changes_available();
        }
        if (m_auto_refresh) {
            if (m_group) {
                transaction::advance(*m_shared_group, *m_history, m_binding_context.get());
            }
            else if (m_binding_context) {
                m_binding_context->did_change({}, {});
            }
        }
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
        transaction::advance(*m_shared_group, *m_history, m_binding_context.get());
    }
    else {
        // Create the read transaction
        read_group();
    }

    return true;
}

uint64_t Realm::get_schema_version(const realm::Realm::Config &config)
{
    if (auto existing_realm = s_global_cache.get_any_realm(config.path)) {
        return existing_realm->config().schema_version;
    }

    return ObjectStore::get_schema_version(Realm(config).read_group());
}

void Realm::close()
{
    invalidate();

    if (m_notifier) {
        m_notifier->remove_realm(this);
    }

    m_group = nullptr;
    m_shared_group = nullptr;
    m_history = nullptr;
    m_read_only_group = nullptr;
    m_notifier = nullptr;
    m_binding_context = nullptr;
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
    for (auto const& path : m_cache) {
        for (auto const& thread : path.second) {
            if (auto realm = thread.second.lock()) {
                realm->close();
            }
        }
    }

    m_cache.clear();
}

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

#include "binding_context.hpp"
#include "impl/realm_coordinator.hpp"
#include "impl/transact_log_handler.hpp"
#include "object_store.hpp"
#include "schema.hpp"

#include <realm/commit_log.hpp>
#include <realm/group_shared.hpp>

using namespace realm;
using namespace realm::_impl;

Realm::Config::Config(const Config& c)
: path(c.path)
, encryption_key(c.encryption_key)
, schema_version(c.schema_version)
, migration_function(c.migration_function)
, delete_realm_if_migration_needed(c.delete_realm_if_migration_needed)
, read_only(c.read_only)
, in_memory(c.in_memory)
, cache(c.cache)
, disable_format_upgrade(c.disable_format_upgrade)
, automatic_change_notifications(c.automatic_change_notifications)
{
    if (c.schema) {
        schema = std::make_unique<Schema>(*c.schema);
    }
}

Realm::Config::Config() : schema_version(ObjectStore::NotVersioned) { }
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
    open_with_config(m_config, m_history, m_shared_group, m_read_only_group);

    if (m_read_only_group) {
        m_group = m_read_only_group.get();
    }
}

REALM_NOINLINE static void translate_file_exception(StringData path, bool read_only=false)
{
    try {
        throw;
    }
    catch (util::File::PermissionDenied const& ex) {
        throw RealmFileException(RealmFileException::Kind::PermissionDenied, ex.get_path(),
                                 "Unable to open a realm at path '" + ex.get_path() +
                                 "'. Please use a path where your app has " + (read_only ? "read" : "read-write") + " permissions.",
                                 ex.what());
    }
    catch (util::File::Exists const& ex) {
        throw RealmFileException(RealmFileException::Kind::Exists, ex.get_path(),
                                 "File at path '" + ex.get_path() + "' already exists.",
                                 ex.what());
    }
    catch (util::File::NotFound const& ex) {
        throw RealmFileException(RealmFileException::Kind::NotFound, ex.get_path(),
                                 "Directory at path '" + ex.get_path() + "' does not exist.",
                                 ex.what());
    }
    catch (util::File::AccessError const& ex) {
        // Errors for `open()` include the path, but other errors don't. We
        // don't want two copies of the path in the error, so strip it out if it
        // appears, and then include it in our prefix.
        std::string underlying = ex.what();
        auto pos = underlying.find(ex.get_path());
        if (pos != std::string::npos && pos > 0) {
            // One extra char at each end for the quotes
            underlying.replace(pos - 1, ex.get_path().size() + 2, "");
        }
        throw RealmFileException(RealmFileException::Kind::AccessError, ex.get_path(),
                                 "Unable to open a realm at path '" + ex.get_path() + "': " + underlying,
                                 ex.what());
    }
    catch (IncompatibleLockFile const& ex) {
        throw RealmFileException(RealmFileException::Kind::IncompatibleLockFile, path,
                                 "Realm file is currently open in another process "
                                 "which cannot share access with this process. All processes sharing a single file must be the same architecture.",
                                 ex.what());
    }
    catch (FileFormatUpgradeRequired const& ex) {
        throw RealmFileException(RealmFileException::Kind::FormatUpgradeRequired, path,
                                 "The Realm file format must be allowed to be upgraded "
                                 "in order to proceed.",
                                 ex.what());
    }
}

void Realm::open_with_config(const Config& config,
                             std::unique_ptr<Replication>& history,
                             std::unique_ptr<SharedGroup>& shared_group,
                             std::unique_ptr<Group>& read_only_group)
{
    try {
        if (config.read_only) {
            read_only_group = std::make_unique<Group>(config.path, config.encryption_key.data(), Group::mode_ReadOnly);
        }
        else {
            history = realm::make_client_history(config.path, config.encryption_key.data());
            SharedGroup::DurabilityLevel durability = config.in_memory ? SharedGroup::durability_MemOnly :
                                                                           SharedGroup::durability_Full;
            shared_group = std::make_unique<SharedGroup>(*history, durability, config.encryption_key.data(), !config.disable_format_upgrade);
        }
    }
    catch (...) {
        translate_file_exception(config.path, config.read_only);
    }
}

void Realm::init(std::shared_ptr<RealmCoordinator> coordinator)
{
    m_coordinator = std::move(coordinator);

    // if there is an existing realm at the current path steal its schema/column mapping
    if (auto existing = m_coordinator->get_schema()) {
        m_config.schema = std::make_unique<Schema>(*existing);
        return;
    }

    try {
        // otherwise get the schema from the group
        auto target_schema = std::move(m_config.schema);
        auto target_schema_version = m_config.schema_version;
        m_config.schema_version = ObjectStore::get_schema_version(read_group());
        m_config.schema = std::make_unique<Schema>(ObjectStore::schema_from_group(read_group()));

        // if a target schema is supplied, verify that it matches or migrate to
        // it, as neeeded
        if (target_schema) {
            if (m_config.read_only) {
                if (m_config.schema_version == ObjectStore::NotVersioned) {
                    throw UninitializedRealmException("Can't open an un-initialized Realm without a Schema");
                }
                target_schema->validate();
                ObjectStore::verify_schema(*m_config.schema, *target_schema, true);
                m_config.schema = std::move(target_schema);
            }
            else {
                update_schema(std::move(target_schema), target_schema_version);
            }

            if (!m_config.read_only) {
                // End the read transaction created to validation/update the
                // schema to avoid pinning the version even if the user never
                // actually reads data
                invalidate();
            }
        }
    }
    catch (...) {
        // Trying to unregister from the coordinator before we finish
        // construction will result in a deadlock
        m_coordinator = nullptr;
        throw;
    }
}

Realm::~Realm()
{
    if (m_coordinator) {
        m_coordinator->unregister_realm(this);
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
    return RealmCoordinator::get_coordinator(config.path)->get_realm(std::move(config));
}

void Realm::update_schema(std::unique_ptr<Schema> schema, uint64_t version)
{
    schema->validate();

    auto needs_update = [&] {
        // If the schema version matches, just verify that the schema itself also matches
        bool needs_write = !m_config.read_only && (m_config.schema_version != version || ObjectStore::needs_update(*m_config.schema, *schema));
        if (needs_write) {
            return true;
        }

        ObjectStore::verify_schema(*m_config.schema, *schema, m_config.read_only);
        m_config.schema = std::move(schema);
        m_config.schema_version = version;
        m_coordinator->update_schema(*m_config.schema);
        return false;
    };

    if (!needs_update()) {
        return;
    }

    read_group();
    transaction::begin(*m_shared_group, m_binding_context.get(),
                       /* error on schema changes */ false);

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
        m_config.schema_version = current_schema_version;
        *m_config.schema = ObjectStore::schema_from_group(read_group());

        if (!needs_update()) {
            cancel_transaction();
            return;
        }
    }
    else if (m_config.delete_realm_if_migration_needed && current_schema_version != ObjectStore::NotVersioned) {
        // Delete realm rather than run migration if delete_realm_if_migration_needed is set and the Realm file exists.
        // FIXME: not a schema mismatch exception, but this is the exception used to signal the Realm file deletion.
        throw SchemaMismatchException(std::vector<ObjectSchemaValidationException>());
    }

    Config old_config(m_config);
    auto migration_function = [&](Group*,  Schema&) {
        SharedRealm old_realm(new Realm(old_config));
        // Need to open in read-write mode so that it uses a SharedGroup, but
        // users shouldn't actually be able to write via the old realm
        old_realm->m_config.read_only = true;

        if (m_config.migration_function) {
            m_config.migration_function(old_realm, shared_from_this());
        }
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

    m_coordinator->update_schema(*m_config.schema);
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

bool Realm::is_in_transaction() const noexcept
{
    if (!m_shared_group) {
        return false;
    }
    return m_shared_group->get_transact_stage() == SharedGroup::transact_Writing;
}

void Realm::begin_transaction()
{
    check_read_write(this);
    verify_thread();

    if (is_in_transaction()) {
        throw InvalidTransactionException("The Realm is already in a write transaction");
    }

    // make sure we have a read transaction
    read_group();

    transaction::begin(*m_shared_group, m_binding_context.get());
}

void Realm::commit_transaction()
{
    check_read_write(this);
    verify_thread();

    if (!is_in_transaction()) {
        throw InvalidTransactionException("Can't commit a non-existing write transaction");
    }

    transaction::commit(*m_shared_group, m_binding_context.get());
    m_coordinator->send_commit_notifications();
}

void Realm::cancel_transaction()
{
    check_read_write(this);
    verify_thread();

    if (!is_in_transaction()) {
        throw InvalidTransactionException("Can't cancel a non-existing write transaction");
    }

    transaction::cancel(*m_shared_group, m_binding_context.get());
}

void Realm::invalidate()
{
    verify_thread();
    check_read_write(this);

    if (is_in_transaction()) {
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
    if (is_in_transaction()) {
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

void Realm::write_copy(StringData path, BinaryData key)
{
    REALM_ASSERT(!key.data() || key.size() == 64);
    verify_thread();
    try {
        read_group()->write(path, key.data());
    }
    catch (...) {
        translate_file_exception(path);
    }
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
                m_coordinator->advance_to_ready(*this);
            }
            else if (m_binding_context) {
                m_binding_context->did_change({}, {});
            }
        }
    }
    else {
        m_coordinator->process_available_async(*this);
    }
}

bool Realm::refresh()
{
    verify_thread();
    check_read_write(this);

    // can't be any new changes if we're in a write transaction
    if (is_in_transaction()) {
        return false;
    }

    // advance transaction if database has changed
    if (!m_shared_group->has_changed()) { // Throws
        return false;
    }

    if (m_group) {
        transaction::advance(*m_shared_group, m_binding_context.get());
        m_coordinator->process_available_async(*this);
    }
    else {
        // Create the read transaction
        read_group();
    }

    return true;
}

bool Realm::can_deliver_notifications() const noexcept
{
    if (m_config.read_only) {
        return false;
    }

    if (m_binding_context && !m_binding_context->can_deliver_notifications()) {
        return false;
    }

    return true;
}

uint64_t Realm::get_schema_version(const realm::Realm::Config &config)
{
    auto coordinator = RealmCoordinator::get_existing_coordinator(config.path);
    if (coordinator) {
        return coordinator->get_schema_version();
    }

    return ObjectStore::get_schema_version(Realm(config).read_group());
}

void Realm::close()
{
    invalidate();

    if (m_coordinator) {
        m_coordinator->unregister_realm(this);
    }

    m_group = nullptr;
    m_shared_group = nullptr;
    m_history = nullptr;
    m_read_only_group = nullptr;
    m_binding_context = nullptr;
    m_coordinator = nullptr;
}

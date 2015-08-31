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

#include "realm_delegate.hpp"

#include <realm/commit_log.hpp>
#include <realm/group_shared.hpp>
#include <realm/lang_bind_helper.hpp>

#include <mutex>
#include <numeric>

using namespace realm;

namespace {
class TransactLogHandler {
    using ColumnInfo = RealmDelegate::ColumnInfo;
    using ObserverState = RealmDelegate::ObserverState;

    size_t currentTable = 0;
    std::vector<ObserverState> observers;
    std::vector<void *> invalidated;
    ColumnInfo *activeLinkList = nullptr;
    RealmDelegate* m_delegate;

    // Get the change info for the given column, creating it if needed
    static ColumnInfo& get_change(ObserverState& state, size_t i)
    {
        if (state.changes.size() <= i) {
            state.changes.resize(std::max(state.changes.size() * 2, i + 1));
        }
        return state.changes[i];
    }

    // Loop over the columns which were changed in an observer state
    template<typename Func>
    static void for_each(ObserverState& state, Func&& f)
    {
        for (size_t i = 0; i < state.changes.size(); ++i) {
            auto const& change = state.changes[i];
            if (change.changed) {
                f(i, change);
            }
        }
    }

    // Mark the given row/col as needing notifications sent
    bool mark_dirty(size_t row_ndx, size_t col_ndx)
    {
        auto it = lower_bound(begin(observers), end(observers), ObserverState{currentTable, row_ndx, nullptr});
        if (it != end(observers) && it->table_ndx == currentTable && it->row_ndx == row_ndx) {
            get_change(*it, col_ndx).changed = true;
        }
        return true;
    }

    // Remove the given observer from the list of observed objects and add it
    // to the listed of invalidated objects
    void invalidate(ObserverState *o)
    {
        invalidated.push_back(o->info);
        observers.erase(observers.begin() + (o - &observers[0]));
    }

public:
    template<typename Func>
    TransactLogHandler(RealmDelegate* delegate, SharedGroup& sg, Func&& func)
    : m_delegate(delegate)
    {
        if (!delegate) {
            func();
            return;
        }

        observers = delegate->get_observed_rows();
        if (observers.empty()) {
            auto old_version = sg.get_version_of_current_transaction();
            func();
            if (old_version != sg.get_version_of_current_transaction()) {
                delegate->did_change({}, {});
            }
            return;
        }

        func(*this);
        delegate->did_change(observers, invalidated);
    }

    // Called at the end of the transaction log immediately before the version
    // is advanced
    void parse_complete()
    {
        m_delegate->will_change(observers, invalidated);
    }

    // These would require having an observer before schema init
    // Maybe do something here to throw an error when multiple processes have different schemas?
    bool insert_group_level_table(size_t, size_t, StringData) noexcept { return false; }
    bool erase_group_level_table(size_t, size_t) noexcept { return false; }
    bool rename_group_level_table(size_t, StringData) noexcept { return false; }
    bool insert_column(size_t, DataType, StringData, bool) { return false; }
    bool insert_link_column(size_t, DataType, StringData, size_t, size_t) { return false; }
    bool erase_column(size_t) { return false; }
    bool erase_link_column(size_t, size_t, size_t) { return false; }
    bool rename_column(size_t, StringData) { return false; }
    bool add_search_index(size_t) { return false; }
    bool remove_search_index(size_t) { return false; }
    bool add_primary_key(size_t) { return false; }
    bool remove_primary_key() { return false; }
    bool set_link_type(size_t, LinkType) { return false; }

    bool select_table(size_t group_level_ndx, int, const size_t*) noexcept {
        currentTable = group_level_ndx;
        return true;
    }

    bool insert_empty_rows(size_t, size_t, size_t, bool) {
        // rows are only inserted at the end, so no need to do anything
        return true;
    }

    bool erase_rows(size_t row_ndx, size_t, size_t last_row_ndx, bool unordered) noexcept {
        for (size_t i = 0; i < observers.size(); ++i) {
            auto& o = observers[i];
            if (o.table_ndx == currentTable) {
                if (o.row_ndx == row_ndx) {
                    invalidate(&o);
                    --i;
                }
                else if (unordered && o.row_ndx == last_row_ndx) {
                    o.row_ndx = row_ndx;
                }
                else if (!unordered && o.row_ndx > row_ndx) {
                    o.row_ndx -= 1;
                }
            }
        }
        return true;
    }

    bool clear_table() noexcept {
        for (size_t i = 0; i < observers.size(); ) {
            auto& o = observers[i];
            if (o.table_ndx == currentTable) {
                invalidate(&o);
            }
            else {
                ++i;
            }
        }
        return true;
    }

    bool select_link_list(size_t col, size_t row) {
        activeLinkList = nullptr;
        for (auto& o : observers) {
            if (o.table_ndx == currentTable && o.row_ndx == row) {
                activeLinkList = &get_change(o, col);
                break;
            }
        }
        return true;
    }

    void append_link_list_change(ColumnInfo::Kind kind, size_t index) {
        ColumnInfo *o = activeLinkList;
        if (!o || o->kind == ColumnInfo::Kind::SetAll) {
            // Active LinkList isn't observed or already has multiple kinds of changes
            return;
        }

        if (o->kind == ColumnInfo::Kind::None) {
            o->kind = kind;
            o->changed = true;
            o->indices.add(index);
        }
        else if (o->kind == kind) {
            if (kind == ColumnInfo::Kind::Remove) {
                // Shift the index to compensate for already-removed indices
                for (auto i : o->indices) {
                    if (i <= index)
                        ++index;
                    else
                        break;
                }
                o->indices.add(index);
            }
            else if (kind == ColumnInfo::Kind::Insert) {
                o->indices.insert_at(index);
            }
            else {
                o->indices.add(index);
            }
        }
        else {
            // Array KVO can only send a single kind of change at a time, so
            // if there's multiple just give up and send "Set"
            o->indices.set(0);
            o->kind = ColumnInfo::Kind::SetAll;
        }
    }

    bool link_list_set(size_t index, size_t) {
        append_link_list_change(ColumnInfo::Kind::Set, index);
        return true;
    }

    bool link_list_insert(size_t index, size_t) {
        append_link_list_change(ColumnInfo::Kind::Insert, index);
        return true;
    }

    bool link_list_erase(size_t index) {
        append_link_list_change(ColumnInfo::Kind::Remove, index);
        return true;
    }

    bool link_list_nullify(size_t index) {
        append_link_list_change(ColumnInfo::Kind::Remove, index);
        return true;
    }

    bool link_list_swap(size_t index1, size_t index2) {
        append_link_list_change(ColumnInfo::Kind::Set, index1);
        append_link_list_change(ColumnInfo::Kind::Set, index2);
        return true;
    }

    bool link_list_clear(size_t old_size) {
        ColumnInfo *o = activeLinkList;
        if (!o || o->kind == ColumnInfo::Kind::SetAll) {
            return true;
        }

        if (o->kind == ColumnInfo::Kind::Remove)
            old_size += o->indices.size();
        else if (o->kind == ColumnInfo::Kind::Insert)
            old_size -= o->indices.size();

        o->indices.set(old_size);

        o->kind = ColumnInfo::Kind::Remove;
        o->changed = true;
        return true;
    }

    bool link_list_move(size_t from, size_t to) {
        ColumnInfo *o = activeLinkList;
        if (!o || o->kind == ColumnInfo::Kind::SetAll) {
            return true;
        }
        if (from > to) {
            std::swap(from, to);
        }

        if (o->kind == ColumnInfo::Kind::None) {
            o->kind = ColumnInfo::Kind::Set;
            o->changed = true;
        }
        if (o->kind == ColumnInfo::Kind::Set) {
            for (size_t i = from; i <= to; ++i)
                o->indices.add(i);
        }
        else {
            o->indices.set(0);
            o->kind = ColumnInfo::Kind::SetAll;
        }
        return true;
    }

    // Things that just mark the field as modified
    bool set_int(size_t col, size_t row, int_fast64_t) { return mark_dirty(row, col); }
    bool set_bool(size_t col, size_t row, bool) { return mark_dirty(row, col); }
    bool set_float(size_t col, size_t row, float) { return mark_dirty(row, col); }
    bool set_double(size_t col, size_t row, double) { return mark_dirty(row, col); }
    bool set_string(size_t col, size_t row, StringData) { return mark_dirty(row, col); }
    bool set_binary(size_t col, size_t row, BinaryData) { return mark_dirty(row, col); }
    bool set_date_time(size_t col, size_t row, DateTime) { return mark_dirty(row, col); }
    bool set_table(size_t col, size_t row) { return mark_dirty(row, col); }
    bool set_mixed(size_t col, size_t row, const Mixed&) { return mark_dirty(row, col); }
    bool set_link(size_t col, size_t row, size_t) { return mark_dirty(row, col); }
    bool set_null(size_t col, size_t row) { return mark_dirty(row, col); }
    bool nullify_link(size_t col, size_t row) { return mark_dirty(row, col); }

    // Things we don't need to do anything for
    bool optimize_table() { return false; }

    // Things that we don't do in the binding
    bool select_descriptor(int, const size_t*) { return true; }
    bool add_int_to_column(size_t, int_fast64_t) { return false; }
};
}

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
            throw UnitializedRealmException("Can't open an un-initialized Realm without a Schema");
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

    // make sure we have a read transaction
    read_group();

    TransactLogHandler(m_delegate.get(), *m_shared_group, [&](auto&&... args) {
        LangBindHelper::promote_to_write(*m_shared_group, *m_history, std::move(args)...);
    });
    m_in_transaction = true;
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

    if (m_delegate) {
        m_delegate->transaction_committed();
    }
}

void Realm::cancel_transaction()
{
    check_read_write(this);
    verify_thread();

    if (!m_in_transaction) {
        throw InvalidTransactionException("Can't cancel a non-existing write transaction");
    }

    TransactLogHandler(m_delegate.get(), *m_shared_group, [&](auto&&... args) {
        LangBindHelper::rollback_and_continue_as_read(*m_shared_group, *m_history, std::move(args)...);
    });
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
        ObjectStore::table_for_object_type(read_group(), object_schema.name)->optimize();
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
                TransactLogHandler(m_delegate.get(), *m_shared_group, [&](auto&&... args) {
                    LangBindHelper::advance_read(*m_shared_group, *m_history, std::move(args)...);
                });
            }
            else if (m_delegate) {
                m_delegate->did_change({}, {});
            }
        }
        else if (m_delegate) {
            m_delegate->changes_available();
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
        TransactLogHandler(m_delegate.get(), *m_shared_group, [&](auto&&... args) {
            LangBindHelper::advance_read(*m_shared_group, *m_history, std::move(args)...);
        });
    }
    else {
        // Create the read transaction
        read_group();
    }

    return true;
}

uint64_t Realm::get_schema_version(const realm::Realm::Config &config)
{
    auto existing_realm = s_global_cache.get_any_realm(config.path);
    if (existing_realm) {
        return existing_realm->config().schema_version;
    }

    return ObjectStore::get_schema_version(Realm(config).read_group());
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


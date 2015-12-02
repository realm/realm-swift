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

#include "impl/realm_coordinator.hpp"

#include "impl/async_query.hpp"
#include "impl/cached_realm.hpp"
#include "impl/external_commit_helper.hpp"
#include "object_store.hpp"
#include "transact_log_handler.hpp"

#include <realm/commit_log.hpp>
#include <realm/group_shared.hpp>
#include <realm/lang_bind_helper.hpp>
#include <realm/query.hpp>
#include <realm/table_view.hpp>

#include <cassert>
#include <unordered_map>

#include <unordered_map>

using namespace realm;
using namespace realm::_impl;

static std::mutex s_coordinator_mutex;
static std::unordered_map<std::string, std::weak_ptr<RealmCoordinator>> s_coordinators_per_path;

std::shared_ptr<RealmCoordinator> RealmCoordinator::get_coordinator(StringData path)
{
    std::lock_guard<std::mutex> lock(s_coordinator_mutex);

    auto& weak_coordinator = s_coordinators_per_path[path];
    if (auto coordinator = weak_coordinator.lock()) {
        return coordinator;
    }

    auto coordinator = std::make_shared<RealmCoordinator>();
    weak_coordinator = coordinator;
    return coordinator;
}

std::shared_ptr<RealmCoordinator> RealmCoordinator::get_existing_coordinator(StringData path)
{
    std::lock_guard<std::mutex> lock(s_coordinator_mutex);
    auto it = s_coordinators_per_path.find(path);
    return it == s_coordinators_per_path.end() ? nullptr : it->second.lock();
}

std::shared_ptr<Realm> RealmCoordinator::get_realm(Realm::Config config)
{
    std::lock_guard<std::mutex> lock(m_realm_mutex);
    if ((!m_config.read_only && !m_notifier) || (m_config.read_only && m_cached_realms.empty())) {
        m_config = config;
        if (!config.read_only && !m_notifier) {
            try {
                m_notifier = std::make_unique<ExternalCommitHelper>(*this);
            }
            catch (std::system_error const& ex) {
                throw RealmFileException(RealmFileException::Kind::AccessError, config.path, ex.code().message());
            }
        }
    }
    else {
        if (m_config.read_only != config.read_only) {
            throw MismatchedConfigException("Realm at path already opened with different read permissions.");
        }
        if (m_config.in_memory != config.in_memory) {
            throw MismatchedConfigException("Realm at path already opened with different inMemory settings.");
        }
        if (m_config.encryption_key != config.encryption_key) {
            throw MismatchedConfigException("Realm at path already opened with a different encryption key.");
        }
        if (m_config.schema_version != config.schema_version && config.schema_version != ObjectStore::NotVersioned) {
            throw MismatchedConfigException("Realm at path already opened with different schema version.");
        }
        // FIXME: verify that schema is compatible
        // Needs to verify that all tables present in both are identical, and
        // then updated m_config with any tables present in config but not in
        // it
        // Public API currently doesn't make it possible to have non-matching
        // schemata so it's not a huge issue
        if ((false) && m_config.schema != config.schema) {
            throw MismatchedConfigException("Realm at path already opened with different schema");
        }
    }

    if (config.cache) {
        for (auto& cachedRealm : m_cached_realms) {
            if (cachedRealm.is_cached_for_current_thread()) {
                // can be null if we jumped in between ref count hitting zero and
                // unregister_realm() getting the lock
                if (auto realm = cachedRealm.realm()) {
                    return realm;
                }
            }
        }
    }

    auto realm = std::make_shared<Realm>(config);
    realm->init(shared_from_this());
    m_cached_realms.emplace_back(realm, m_config.cache);
    return realm;
}

std::shared_ptr<Realm> RealmCoordinator::get_realm()
{
    return get_realm(m_config);
}

const Schema* RealmCoordinator::get_schema() const noexcept
{
    return m_cached_realms.empty() ? nullptr : m_config.schema.get();
}

RealmCoordinator::RealmCoordinator() = default;

RealmCoordinator::~RealmCoordinator()
{
    std::lock_guard<std::mutex> coordinator_lock(s_coordinator_mutex);
    for (auto it = s_coordinators_per_path.begin(); it != s_coordinators_per_path.end(); ) {
        if (it->second.expired()) {
            it = s_coordinators_per_path.erase(it);
        }
        else {
            ++it;
        }
    }
}

void RealmCoordinator::unregister_realm(Realm* realm)
{
    std::lock_guard<std::mutex> lock(m_realm_mutex);
    for (size_t i = 0; i < m_cached_realms.size(); ++i) {
        auto& cached_realm = m_cached_realms[i];
        if (!cached_realm.expired() && !cached_realm.is_for_realm(realm)) {
            continue;
        }

        if (i + 1 < m_cached_realms.size()) {
            cached_realm = std::move(m_cached_realms.back());
        }
        m_cached_realms.pop_back();
    }
}

void RealmCoordinator::clear_cache()
{
    std::vector<WeakRealm> realms_to_close;
    {
        std::lock_guard<std::mutex> lock(s_coordinator_mutex);

        for (auto& weak_coordinator : s_coordinators_per_path) {
            auto coordinator = weak_coordinator.second.lock();
            if (!coordinator) {
                continue;
            }

            coordinator->m_notifier = nullptr;

            // Gather a list of all of the realms which will be removed
            for (auto& cached_realm : coordinator->m_cached_realms) {
                if (auto realm = cached_realm.realm()) {
                    realms_to_close.push_back(realm);
                }
            }
        }

        s_coordinators_per_path.clear();
    }

    // Close all of the previously cached Realms. This can't be done while
    // s_coordinator_mutex is held as it may try to re-lock it.
    for (auto& weak_realm : realms_to_close) {
        if (auto realm = weak_realm.lock()) {
            realm->close();
        }
    }
}

void RealmCoordinator::send_commit_notifications()
{
    REALM_ASSERT(!m_config.read_only);
    m_notifier->notify_others();
}

void RealmCoordinator::pin_version(uint_fast64_t version, uint_fast32_t index)
{
    if (m_async_error) {
        return;
    }

    SharedGroup::VersionID versionid(version, index);
    if (!m_advancer_sg) {
        try {
            // Use a temporary Realm instance to open the shared group to reuse
            // the error handling there
            Realm tmp(m_config);
            m_advancer_history = std::move(tmp.m_history);
            m_advancer_sg = std::move(tmp.m_shared_group);
            m_advancer_sg->begin_read(versionid);
        }
        catch (...) {
            m_async_error = std::current_exception();
            m_advancer_sg = nullptr;
            m_advancer_history = nullptr;
        }
    }
    else if (m_new_queries.empty()) {
        // If this is the first query then we don't already have a read transaction
        m_advancer_sg->begin_read(versionid);
    }
    else if (versionid < m_advancer_sg->get_version_of_current_transaction()) {
        // Ensure we're holding a readlock on the oldest version we have a
        // handover object for, as handover objects don't
        m_advancer_sg->end_read();
        m_advancer_sg->begin_read(versionid);
    }
}

AsyncQueryCancelationToken RealmCoordinator::register_query(const Results& r, std::unique_ptr<AsyncQueryCallback> target)
{
    return r.get_realm().m_coordinator->do_register_query(r, std::move(target));
}

AsyncQueryCancelationToken RealmCoordinator::do_register_query(const Results& r, std::unique_ptr<AsyncQueryCallback> target)
{
    if (m_config.read_only) {
        throw InvalidTransactionException("Cannot create asynchronous query for read-only Realms");
    }
    if (r.get_realm().is_in_transaction()) {
        throw InvalidTransactionException("Cannot create asynchronous query while in a write transaction");
    }

    auto handover = r.get_realm().m_shared_group->export_for_handover(r.get_query(), ConstSourcePayload::Copy);
    auto version = handover->version;
    auto query = std::make_shared<AsyncQuery>(r.get_sort(),
                                              std::move(handover),
                                              std::move(target),
                                              *this);

    {
        std::lock_guard<std::mutex> lock(m_query_mutex);
        pin_version(version.version, version.index);
        m_new_queries.push_back(query);
    }

    // Wake up the background worker threads by pretending we made a commit
    m_notifier->notify_others();
    return query;
}

void RealmCoordinator::unregister_query(AsyncQuery& registration)
{
    registration.parent->do_unregister_query(registration);
}

void RealmCoordinator::do_unregister_query(AsyncQuery& registration)
{
    auto swap_remove = [&](auto& container) {
        auto it = std::find_if(container.begin(), container.end(),
                               [&](auto const& ptr) { return ptr.get() == &registration; });
        if (it != container.end()) {
            std::iter_swap(--container.end(), it);
            container.pop_back();
            return true;
        }
        return false;
    };

    std::lock_guard<std::mutex> lock(m_query_mutex);
    if (swap_remove(m_queries)) {
        // Make sure we aren't holding on to read versions needlessly if there
        // are no queries left, but don't close them entirely as opening shared
        // groups is expensive
        if (m_queries.empty() && m_query_sg) {
            m_query_sg->end_read();
        }
    }
    else if (swap_remove(m_new_queries)) {
        if (m_new_queries.empty() && m_advancer_sg) {
            m_advancer_sg->end_read();
        }
    }
}

void RealmCoordinator::on_change()
{
    run_async_queries();

    std::lock_guard<std::mutex> lock(m_realm_mutex);
    for (auto& realm : m_cached_realms) {
        realm.notify();
    }
}

void RealmCoordinator::run_async_queries()
{
    std::unique_lock<std::mutex> lock(m_query_mutex);

    if (m_queries.empty() && m_new_queries.empty()) {
        return;
    }

    if (!m_async_error) {
        open_helper_shared_group();
    }

    if (m_async_error) {
        move_new_queries_to_main();
        for (auto& query : m_queries) {
            query->set_error(m_async_error);
        }
        return;
    }

    advance_helper_shared_group_to_latest();

    // Make a copy of the queries vector so that we can release the lock while
    // we run the queries
    auto queries_to_run = m_queries;
    lock.unlock();

    for (auto& query : queries_to_run) {
        query->prepare_update();
    }

    // Reacquire the lock while updating the fields that are actually read on
    // other threads
    lock.lock();
    for (auto& query : queries_to_run) {
        query->prepare_handover();
    }
}

void RealmCoordinator::open_helper_shared_group()
{
    if (!m_query_sg) {
        try {
            Realm tmp(m_config);
            m_query_history = std::move(tmp.m_history);
            m_query_sg = std::move(tmp.m_shared_group);
            m_query_sg->begin_read();
        }
        catch (...) {
            // Store the error to be passed to the async queries
            m_async_error = std::current_exception();
            m_query_sg = nullptr;
            m_query_history = nullptr;
        }
    }
    else if (m_queries.empty()) {
        m_query_sg->begin_read();
    }
}

void RealmCoordinator::move_new_queries_to_main()
{
    m_queries.reserve(m_queries.size() + m_new_queries.size());
    std::move(m_new_queries.begin(), m_new_queries.end(), std::back_inserter(m_queries));
    m_new_queries.clear();
}

void RealmCoordinator::advance_helper_shared_group_to_latest()
{
    if (m_new_queries.empty()) {
        LangBindHelper::advance_read(*m_query_sg, *m_query_history);
        return;
    }

    // Sort newly added queries by their source version so that we can pull them
    // all forward to the latest version in a single pass over the transaction log
    std::sort(m_new_queries.begin(), m_new_queries.end(), [](auto const& lft, auto const& rgt) {
        return lft->version() < rgt->version();
    });

    // Import all newly added queries to our helper SG
    for (auto& query : m_new_queries) {
        LangBindHelper::advance_read(*m_advancer_sg, *m_advancer_history, query->version());
        query->attach_to(*m_advancer_sg);
    }

    // Advance both SGs to the newest version
    LangBindHelper::advance_read(*m_advancer_sg, *m_advancer_history);
    LangBindHelper::advance_read(*m_query_sg, *m_query_history,
                                 m_advancer_sg->get_version_of_current_transaction());

    // Transfer all new queries over to the main SG
    for (auto& query : m_new_queries) {
        query->detatch();
        query->attach_to(*m_query_sg);
    }

    if (!m_new_queries.empty()) {
        move_new_queries_to_main();
        m_advancer_sg->end_read();
    }
}

void RealmCoordinator::advance_to_ready(Realm& realm)
{
    std::vector<std::function<void()>> async_results;

    {
        std::lock_guard<std::mutex> lock(m_query_mutex);

        SharedGroup::VersionID version;
        for (auto& query : m_queries) {
            version = query->version();
            if (version != SharedGroup::VersionID()) {
                break;
            }
        }

        // no untargeted async queries; just advance to latest
        if (version.version == 0) {
            transaction::advance(*realm.m_shared_group, *realm.m_history, realm.m_binding_context.get());
            return;
        }
        // async results are out of date; ignore
        else if (version < realm.m_shared_group->get_version_of_current_transaction()) {
            return;
        }

        transaction::advance(*realm.m_shared_group, *realm.m_history, realm.m_binding_context.get(), version);

        for (auto& query : m_queries) {
            query->get_results(realm.shared_from_this(), *realm.m_shared_group, async_results);
        }
    }

    for (auto& results : async_results) {
        results();
    }
}

void RealmCoordinator::process_available_async(Realm& realm)
{
    std::vector<std::function<void()>> async_results;

    {
        std::lock_guard<std::mutex> lock(m_query_mutex);
        for (auto& query : m_queries) {
            query->get_results(realm.shared_from_this(), *realm.m_shared_group, async_results);
        }
    }

    for (auto& results : async_results) {
        results();
    }
}

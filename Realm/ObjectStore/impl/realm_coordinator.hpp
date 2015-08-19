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

#ifndef REALM_COORDINATOR_HPP
#define REALM_COORDINATOR_HPP

#include "shared_realm.hpp"

#include <realm/string_data.hpp>

namespace realm {
namespace _impl {
class ExternalCommitHelper;

// RealmCoordinator manages the weak cache of Realm instances and communication
// between per-thread Realm instances for a given file
class RealmCoordinator : public std::enable_shared_from_this<RealmCoordinator> {
public:
    // Get the coordinator for the given path, creating it if neccesary
    static std::shared_ptr<RealmCoordinator> get_coordinator(StringData path);
    // Get the coordinator for the given path, or null if there is none
    static std::shared_ptr<RealmCoordinator> get_existing_coordinator(StringData path);

    // Get a thread-local shared Realm with the given configuration
    // If the Realm is already open on another thread, validates that the given
    // configuration is compatible with the existing one
    std::shared_ptr<Realm> get_realm(Realm::Config config);

    const Schema* get_schema() const noexcept;
    uint64_t get_schema_version() const noexcept { return m_config.schema_version; }
    const std::string& get_path() const noexcept { return m_config.path; }

    // Asyncronously call notify() on every Realm instance for this coordinator's
    // path, including those in other processes
    void send_commit_notifications();

    // Clear the weak Realm cache for all paths
    // Should only be called in test code, as continuing to use the previously
    // cached instances will have odd results
    static void clear_cache();

    // Explicit constructor/destructor needed for the unique_ptrs to forward-declared types
    RealmCoordinator();
    ~RealmCoordinator();

    // Called by Realm's destructor to ensure the cache is cleaned up promptly
    // Do not call directly
    void unregister_realm(Realm* realm);

private:
    Realm::Config m_config;

    std::mutex m_realm_mutex;
    std::vector<std::weak_ptr<Realm>> m_cached_realms;

    std::unique_ptr<_impl::ExternalCommitHelper> m_notifier;
};

} // namespace _impl
} // namespace realm

#endif /* REALM_COORDINATOR_HPP */

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

#ifndef REALM_REALM_HPP
#define REALM_REALM_HPP

#include <realm/handover_defs.hpp>

#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace realm {
    class BindingContext;
    class ClientHistory;
    class Group;
    class Realm;
    class RealmDelegate;
    class Schema;
    class SharedGroup;
    typedef std::shared_ptr<Realm> SharedRealm;
    typedef std::weak_ptr<Realm> WeakRealm;

    namespace _impl {
        class AsyncQuery;
        class RealmCoordinator;
    }

    class Realm : public std::enable_shared_from_this<Realm> {
      public:
        typedef std::function<void(SharedRealm old_realm, SharedRealm realm)> MigrationFunction;

        struct Config
        {
            std::string path;
            bool read_only = false;
            bool in_memory = false;
            bool cache = true;
            bool disable_format_upgrade = false;
            std::vector<char> encryption_key;

            std::unique_ptr<Schema> schema;
            uint64_t schema_version;

            MigrationFunction migration_function;

            Config();
            Config(Config&&);
            Config(const Config& c);
            ~Config();

            Config& operator=(Config const&);
            Config& operator=(Config&&) = default;
        };

        // Get a cached Realm or create a new one if no cached copies exists
        // Caching is done by path - mismatches for in_memory and read_only
        // Config properties will raise an exception
        // If schema/schema_version is specified, update_schema is called
        // automatically on the realm and a migration is performed. If not
        // specified, the schema version and schema are dynamically read from
        // the the existing Realm.
        static SharedRealm get_shared_realm(Config config);

        // Updates a Realm to a given target schema/version creating tables and
        // updating indexes as necessary. Uses the existing migration function
        // on the Config, and the resulting Schema and version with updated
        // column mappings are set on the realms config upon success.
        void update_schema(std::unique_ptr<Schema> schema, uint64_t version);

        static uint64_t get_schema_version(Config const& config);

        const Config &config() const { return m_config; }

        void begin_transaction();
        void commit_transaction();
        void cancel_transaction();
        bool is_in_transaction() const noexcept;
        bool is_in_read_transaction() const { return !!m_group; }

        bool refresh();
        void set_auto_refresh(bool auto_refresh) { m_auto_refresh = auto_refresh; }
        bool auto_refresh() const { return m_auto_refresh; }
        void notify();

        void invalidate();
        bool compact();

        std::thread::id thread_id() const { return m_thread_id; }
        void verify_thread() const;
        void verify_in_write() const;

        bool can_deliver_notifications() const noexcept;

        // Close this Realm and remove it from the cache. Continuing to use a
        // Realm after closing it will produce undefined behavior.
        void close();

        ~Realm();

        void init(std::shared_ptr<_impl::RealmCoordinator> coordinator);
        Realm(Config config);

        // Expose some internal functionality to other parts of the ObjectStore
        // without making it public to everyone
        class Internal {
            friend class _impl::AsyncQuery;
            friend class _impl::RealmCoordinator;

            // AsyncQuery needs access to the SharedGroup to be able to call the
            // handover functions, which are not very wrappable
            static SharedGroup& get_shared_group(Realm& realm) { return *realm.m_shared_group; }
            static ClientHistory& get_history(Realm& realm) { return *realm.m_history; }

            // AsyncQuery needs to be able to access the owning coordinator to
            // wake up the worker thread when a callback is added, and
            // coordinators need to be able to get themselves from a Realm
            static _impl::RealmCoordinator& get_coordinator(Realm& realm) { return *realm.m_coordinator; }
        };

        static void open_with_config(const Config& config,
                                     std::unique_ptr<ClientHistory>& history,
                                     std::unique_ptr<SharedGroup>& shared_group,
                                     std::unique_ptr<Group>& read_only_group);

      private:
        Config m_config;
        std::thread::id m_thread_id = std::this_thread::get_id();
        bool m_auto_refresh = true;

        std::unique_ptr<ClientHistory> m_history;
        std::unique_ptr<SharedGroup> m_shared_group;
        std::unique_ptr<Group> m_read_only_group;

        Group *m_group = nullptr;

        std::shared_ptr<_impl::RealmCoordinator> m_coordinator;

      public:
        std::unique_ptr<BindingContext> m_binding_context;

        // FIXME private
        Group *read_group();
    };

    class RealmFileException : public std::runtime_error {
    public:
        enum class Kind {
            /** Thrown for any I/O related exception scenarios when a realm is opened. */
            AccessError,
            /** Thrown if the user does not have permission to open or create
             the specified file in the specified access mode when the realm is opened. */
            PermissionDenied,
            /** Thrown if create_Always was specified and the file did already exist when the realm is opened. */
            Exists,
            /** Thrown if no_create was specified and the file was not found when the realm is opened. */
            NotFound,
            /** Thrown if the database file is currently open in another
             process which cannot share with the current process due to an
             architecture mismatch. */
            IncompatibleLockFile,
            /** Thrown if the file needs to be upgraded to a new format, but upgrades have been explicitly disabled. */
            FormatUpgradeRequired,
        };
        RealmFileException(Kind kind, std::string path, std::string message) :
            std::runtime_error(std::move(message)), m_kind(kind), m_path(std::move(path)) {}
        Kind kind() const { return m_kind; }
        const std::string& path() const { return m_path; }

    private:
        Kind m_kind;
        std::string m_path;
    };

    class MismatchedConfigException : public std::runtime_error {
    public:
        MismatchedConfigException(std::string message) : std::runtime_error(message) {}
    };

    class InvalidTransactionException : public std::runtime_error {
    public:
        InvalidTransactionException(std::string message) : std::runtime_error(message) {}
    };

    class IncorrectThreadException : public std::runtime_error {
    public:
        IncorrectThreadException() : std::runtime_error("Realm accessed from incorrect thread.") {}
    };

    class UnitializedRealmException : public std::runtime_error {
    public:
        UnitializedRealmException(std::string message) : std::runtime_error(message) {}
    };
}

#endif /* defined(REALM_REALM_HPP) */

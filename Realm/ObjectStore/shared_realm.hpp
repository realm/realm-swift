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

#include <memory>
#include <thread>
#include <vector>

#include "object_store.hpp"

namespace realm {
    class ClientHistory;
    class Realm;
    class RealmCache;
    class BindingContext;
    typedef std::shared_ptr<Realm> SharedRealm;
    typedef std::weak_ptr<Realm> WeakRealm;

    namespace _impl {
        class ExternalCommitHelper;
    }

    class Realm : public std::enable_shared_from_this<Realm>
    {
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
            uint64_t schema_version = ObjectStore::NotVersioned;

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
        bool is_in_transaction() const { return m_in_transaction; }

        bool refresh();
        void set_auto_refresh(bool auto_refresh) { m_auto_refresh = auto_refresh; }
        bool auto_refresh() const { return m_auto_refresh; }
        void notify();

        void invalidate();
        bool compact();

        std::thread::id thread_id() const { return m_thread_id; }
        void verify_thread() const;
        void verify_in_write() const;

        // Close this Realm and remove it from the cache. Continuing to use a
        // Realm after closing it will produce undefined behavior.
        void close();

        ~Realm();

      private:
        Realm(Config config);

        Config m_config;
        std::thread::id m_thread_id = std::this_thread::get_id();
        bool m_in_transaction = false;
        bool m_auto_refresh = true;

        std::unique_ptr<ClientHistory> m_history;
        std::unique_ptr<SharedGroup> m_shared_group;
        std::unique_ptr<Group> m_read_only_group;

        Group *m_group = nullptr;

        std::shared_ptr<_impl::ExternalCommitHelper> m_notifier;

      public:
        std::unique_ptr<BindingContext> m_binding_context;

        // FIXME private
        Group *read_group();
        static RealmCache s_global_cache;
    };

    class RealmCache
    {
      public:
        SharedRealm get_realm(const std::string &path, std::thread::id thread_id = std::this_thread::get_id());
        SharedRealm get_any_realm(const std::string &path);
        void remove(const std::string &path, std::thread::id thread_id);
        void cache_realm(SharedRealm &realm, std::thread::id thread_id = std::this_thread::get_id());
        void clear();

      private:
        std::map<std::string, std::map<std::thread::id, WeakRealm>> m_cache;
        std::mutex m_mutex;
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
